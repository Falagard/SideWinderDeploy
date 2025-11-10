package deploy;

import sidewinderdeploy.shared.*;
import sidewinderdeploy.shared.AuthModels;
import sidewinder.Database;
import sidewinder.Router;
import Date;
import haxe.crypto.Sha256;

class AuthService implements IAuthService {
	private static final SESSION_DURATION_DAYS = 30;
	
	// Store current session in context for middleware
	private var currentSession:Null<Session> = null;
	private var currentUser:Null<User> = null;

	public function new() {}

	public function register(request:RegisterRequest):RegisterResponse {
		// Validate input
		if (request.email == null || request.email.length == 0) {
			return {success: false, error: "Email is required"};
		}
		if (request.password == null || request.password.length < 8) {
			return {success: false, error: "Password must be at least 8 characters"};
		}

		// Check if user exists
		try {
			var conn = Database.acquire();
			var params = new Map<String, Dynamic>();
			params.set("email", request.email);
			var sql = "SELECT id FROM users WHERE email=@email";
			var rs = conn.request(Database.buildSql(sql, params));
			var rec = rs.next();
			Database.release(conn);
			
			if (rec != null) {
				return {success: false, error: "Email already registered"};
			}
		} catch (e:Dynamic) {
			return {success: false, error: "Database error"};
		}

		// Hash password using SHA256 (salt with email for uniqueness)
		var passwordHash = hashPassword(request.password, request.email);

		// Create user
		var userId = generateId();
		var now = Date.now();
		
		try {
			var conn = Database.acquire();
			var params = new Map<String, Dynamic>();
			params.set("id", userId);
			params.set("email", request.email);
			params.set("username", request.username);
			params.set("password_hash", passwordHash);
			params.set("created_at", now.getTime());
			params.set("updated_at", now.getTime());
			
			var sql = "INSERT INTO users (id, email, username, password_hash, created_at, updated_at, is_active, email_verified) " +
					  "VALUES (@id, @email, @username, @password_hash, @created_at, @updated_at, 1, 0)";
			conn.request(Database.buildSql(sql, params));
			Database.release(conn);
		} catch (e:Dynamic) {
			return {success: false, error: "Failed to create user"};
		}

		var user = getUserById(userId);
		if (user == null) {
			return {success: false, error: "User created but not found"};
		}

		return {
			success: true,
			user: {
				id: user.id,
				email: user.email,
				username: user.username,
				emailVerified: user.emailVerified
			}
		};
	}

	public function login(request:LoginRequest):LoginResponse {
		// Find user by email or username
		var user:Null<User> = null;
		
		try {
			var conn = Database.acquire();
			var params = new Map<String, Dynamic>();
			params.set("identifier", request.emailOrUsername);
			
			var sql = "SELECT * FROM users WHERE (email=@identifier OR username=@identifier) AND is_active=1";
			var rs = conn.request(Database.buildSql(sql, params));
			var rec = rs.next();
			Database.release(conn);
			
			if (rec != null) {
				user = recordToUser(rec);
			}
		} catch (e:Dynamic) {
			return {success: false, error: "Database error"};
		}

		if (user == null || user.passwordHash == null) {
			return {success: false, error: "Invalid credentials"};
		}

		// Verify password
		var passwordHash = hashPassword(request.password, user.email);
		if (passwordHash != user.passwordHash) {
			return {success: false, error: "Invalid credentials"};
		}

		// Get request context for IP and user agent
		// TODO: These should be passed as parameters or obtained via middleware
		var ipAddress = "unknown";
		var userAgent = "unknown";

		// Create session
		var session = createSession(user.id, ipAddress, userAgent);
		if (session == null) {
			return {success: false, error: "Failed to create session"};
		}

		return {
			success: true,
			token: session.token,
			user: {
				id: user.id,
				email: user.email,
				username: user.username,
				emailVerified: user.emailVerified
			}
		};
	}

	public function logout():Bool {
		if (currentSession == null) {
			return false;
		}
		
		try {
			var conn = Database.acquire();
			var params = new Map<String, Dynamic>();
			params.set("token", currentSession.token);
			
			var sql = "DELETE FROM sessions WHERE token=@token";
			conn.request(Database.buildSql(sql, params));
			Database.release(conn);
			
			currentSession = null;
			currentUser = null;
			return true;
		} catch (e:Dynamic) {
			return false;
		}
	}

	public function getCurrentUser():Null<UserPublic> {
		// TODO: Current user should be set via middleware or passed as context
		// For now, returning null if not already set
		if (currentUser == null) {
			return null;
		}
		
		return {
			id: currentUser.id,
			email: currentUser.email,
			username: currentUser.username,
			emailVerified: currentUser.emailVerified
		};
	}

	public function oauthLogin(provider:String, request:OAuthLoginRequest):LoginResponse {
		// OAuth implementation would go here
		// This is a placeholder for future OAuth integration
		return {success: false, error: "OAuth not yet implemented"};
	}

	public function linkOAuthProvider(provider:String, request:OAuthLoginRequest):Bool {
		// OAuth linking would go here
		return false;
	}

	public function changePassword(request:ChangePasswordRequest):Bool {
		if (currentUser == null) {
			return false;
		}

		var user = getUserById(currentUser.id);
		if (user == null || user.passwordHash == null) {
			return false;
		}

		// Verify old password
		var oldPasswordHash = hashPassword(request.oldPassword, user.email);
		if (oldPasswordHash != user.passwordHash) {
			return false;
		}

		// Hash new password
		var newPasswordHash = hashPassword(request.newPassword, user.email);
		
		try {
			var conn = Database.acquire();
			var params = new Map<String, Dynamic>();
			params.set("password_hash", newPasswordHash);
			params.set("updated_at", Date.now().getTime());
			params.set("id", user.id);
			
			var sql = "UPDATE users SET password_hash=@password_hash, updated_at=@updated_at WHERE id=@id";
			conn.request(Database.buildSql(sql, params));
			Database.release(conn);
			return true;
		} catch (e:Dynamic) {
			return false;
		}
	}

	public function requestPasswordReset(email:String):Bool {
		// Password reset implementation would send an email with a reset token
		// For now, just return true if user exists
		var user = getUserByEmail(email);
		return user != null;
	}

	public function verifyEmail(code:String):Bool {
		// Email verification implementation
		// This would validate the verification code and mark email as verified
		return false;
	}

	public function refreshSession():Null<Session> {
		if (currentSession == null) {
			return null;
		}

		var newExpiresAt = Date.fromTime(Date.now().getTime() + (SESSION_DURATION_DAYS * 24 * 60 * 60 * 1000.0));
		
		try {
			var conn = Database.acquire();
			var params = new Map<String, Dynamic>();
			params.set("expires_at", newExpiresAt.getTime());
			params.set("id", currentSession.id);
			
			var sql = "UPDATE sessions SET expires_at=@expires_at WHERE id=@id";
			conn.request(Database.buildSql(sql, params));
			Database.release(conn);
			
			currentSession.expiresAt = newExpiresAt;
			return currentSession;
		} catch (e:Dynamic) {
			return null;
		}
	}

	// Helper methods
	
	public function validateSessionToken(token:String):Null<User> {
		try {
			var conn = Database.acquire();
			var params = new Map<String, Dynamic>();
			params.set("token", token);
			params.set("now", Date.now().getTime());
			
			var sql = "SELECT u.* FROM users u " +
					  "INNER JOIN sessions s ON s.user_id = u.id " +
					  "WHERE s.token=@token AND s.expires_at > @now AND u.is_active=1";
			var rs = conn.request(Database.buildSql(sql, params));
			var rec = rs.next();
			Database.release(conn);
			
			if (rec != null) {
				var user = recordToUser(rec);
				
				// Also load the session
				conn = Database.acquire();
				params = new Map<String, Dynamic>();
				params.set("token", token);
				sql = "SELECT * FROM sessions WHERE token=@token";
				rs = conn.request(Database.buildSql(sql, params));
				var sessionRec = rs.next();
				Database.release(conn);
				
				if (sessionRec != null) {
					currentSession = recordToSession(sessionRec);
				}
				
				currentUser = user;
				return user;
			}
		} catch (e:Dynamic) {}
		
		return null;
	}

	private function createSession(userId:String, ipAddress:String, userAgent:String):Null<Session> {
		var sessionId = generateId();
		var token = generateToken();
		var now = Date.now();
		var expiresAt = Date.fromTime(now.getTime() + (SESSION_DURATION_DAYS * 24 * 60 * 60 * 1000.0));

		try {
			var conn = Database.acquire();
			var params = new Map<String, Dynamic>();
			params.set("id", sessionId);
			params.set("user_id", userId);
			params.set("token", token);
			params.set("expires_at", expiresAt.getTime());
			params.set("created_at", now.getTime());
			params.set("ip_address", ipAddress);
			params.set("user_agent", userAgent);
			
			var sql = "INSERT INTO sessions (id, user_id, token, expires_at, created_at, ip_address, user_agent) " +
					  "VALUES (@id, @user_id, @token, @expires_at, @created_at, @ip_address, @user_agent)";
			conn.request(Database.buildSql(sql, params));
			Database.release(conn);

			return {
				id: sessionId,
				userId: userId,
				token: token,
				expiresAt: expiresAt,
				createdAt: now,
				ipAddress: ipAddress,
				userAgent: userAgent
			};
		} catch (e:Dynamic) {
			return null;
		}
	}

	private function getUserById(id:String):Null<User> {
		try {
			var conn = Database.acquire();
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			
			var sql = "SELECT * FROM users WHERE id=@id";
			var rs = conn.request(Database.buildSql(sql, params));
			var rec = rs.next();
			Database.release(conn);
			
			if (rec != null) {
				return recordToUser(rec);
			}
		} catch (e:Dynamic) {}
		
		return null;
	}

	private function getUserByEmail(email:String):Null<User> {
		try {
			var conn = Database.acquire();
			var params = new Map<String, Dynamic>();
			params.set("email", email);
			
			var sql = "SELECT * FROM users WHERE email=@email AND is_active=1";
			var rs = conn.request(Database.buildSql(sql, params));
			var rec = rs.next();
			Database.release(conn);
			
			if (rec != null) {
				return recordToUser(rec);
			}
		} catch (e:Dynamic) {}
		
		return null;
	}

	private function hashPassword(password:String, salt:String):String {
		// Simple SHA256 with salt
		// In production, consider using a proper password hashing library like bcrypt
		return Sha256.encode(password + salt + "SideWinderDeploy");
	}

	private function generateId():String {
		return Sha256.encode(Std.string(Math.random()) + Std.string(Date.now().getTime()) + Std.string(Math.random()));
	}

	private function generateToken():String {
		return Sha256.encode(Std.string(Math.random()) + Std.string(Date.now().getTime()) + Std.string(Math.random()) + "token");
	}

	private function recordToUser(rec:Dynamic):User {
		return {
			id: Std.string(Reflect.field(rec, "id")),
			email: Std.string(Reflect.field(rec, "email")),
			username: Reflect.field(rec, "username") != null ? Std.string(Reflect.field(rec, "username")) : null,
			passwordHash: Reflect.field(rec, "password_hash") != null ? Std.string(Reflect.field(rec, "password_hash")) : null,
			createdAt: Date.fromTime(Reflect.field(rec, "created_at")),
			updatedAt: Date.fromTime(Reflect.field(rec, "updated_at")),
			isActive: Std.int(Reflect.field(rec, "is_active")) == 1,
			emailVerified: Std.int(Reflect.field(rec, "email_verified")) == 1
		};
	}

	private function recordToSession(rec:Dynamic):Session {
		return {
			id: Std.string(Reflect.field(rec, "id")),
			userId: Std.string(Reflect.field(rec, "user_id")),
			token: Std.string(Reflect.field(rec, "token")),
			expiresAt: Date.fromTime(Reflect.field(rec, "expires_at")),
			createdAt: Date.fromTime(Reflect.field(rec, "created_at")),
			ipAddress: Reflect.field(rec, "ip_address") != null ? Std.string(Reflect.field(rec, "ip_address")) : null,
			userAgent: Reflect.field(rec, "user_agent") != null ? Std.string(Reflect.field(rec, "user_agent")) : null
		};
	}
}
