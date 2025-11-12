package;

import sidewinder.AsyncBlockerPool;
import sidewinder.UserService;
import sidewinder.CacheService;
import sidewinder.IUserService;
import sidewinder.App;
import sidewinder.AutoRouter;
import sidewinder.DI;
import sidewinder.HybridLogger;
import sidewinder.SideWinderRequestHandler;
import sidewinder.ICacheService;
import hx.injection.ServiceCollection;
import haxe.Json;
import haxe.Http;
import haxe.Timer;
import sidewinder.Router.Response;
import sidewinder.Router.Request;
import sys.thread.Thread;
import lime.app.Application;
import lime.ui.WindowAttributes;
import lime.ui.Window;
import snake.http.*;
import snake.socket.*;
import sys.net.Host;
import sys.net.Socket;
import snake.server.*;
import sidewinder.SideWinderServer;
import lime.ui.Gamepad;
import lime.ui.GamepadButton;
import Date;
import sidewinder.Database;
import hx.injection.Service;
// Removed DeployApi; using AutoRouter-based controllers
import sidewinderdeploy.shared.*;
import sidewinderdeploy.shared.AuthModels;
import deploy.*;

using hx.injection.ServiceExtensions;

class Main extends Application {
	private static final DEFAULT_PROTOCOL = "HTTP/1.0"; // snake-server needs more work for 1.1 connections
	private static final DEFAULT_ADDRESS = "127.0.0.1";
	private static final DEFAULT_PORT = 8000;

	private var httpServer:SideWinderServer;

	public static var router = SideWinderRequestHandler.router;

	public var cache:ICacheService;

	public function new() {
		super();

		// Initialize database and run migrations
		Database.runMigrations();
		HybridLogger.init(true);

		// Cache service will be resolved from DI

		var directory:String = null;

		// Configure SideWinderRequestHandler
		BaseHTTPRequestHandler.protocolVersion = DEFAULT_PROTOCOL;
		SideWinderRequestHandler.corsEnabled = false;
		SideWinderRequestHandler.cacheEnabled = true;
		SideWinderRequestHandler.silent = true;

		DI.init(c -> {
			c.addSingleton(ICacheService, CacheService);
			c.addScoped(IAuthService, AuthService);
			c.addScoped(IProjectService, ProjectService);
			c.addScoped(IEnvironmentService, EnvironmentService);
			c.addScoped(IMachineService, MachineService);
			c.addScoped(IReleaseService, ReleaseService);
			c.addScoped(IDeploymentService, DeploymentService);
			c.addScoped(ITenantService, TenantService);
			c.addScoped(IProjectVariableService, ProjectVariableService);
			c.addScoped(ITenantVariableValueService, TenantVariableValueService);
		});

		cache = DI.get(ICacheService);

		httpServer = new SideWinderServer(new Host(DEFAULT_ADDRESS), DEFAULT_PORT, SideWinderRequestHandler, true, directory);

		// Example middleware: logging
		App.use((req, res, next) -> {
			//
			HybridLogger.info('${req.method} ${req.path} ' + Sys.time());
			next();
		});

		// Authentication middleware - protect all /api/ routes except /api/auth/
		App.use((req, res, next) -> {
			// Skip auth for auth endpoints
			if (req.path.indexOf("/api/auth/") == 0) {
				next();
				return;
			}

			// Require authentication for all other /api/ routes
			if (req.path.indexOf("/api/") == 0) {
				// Get session token from cookie or Authorization header
				var sessionToken:String = null;

				// Check for Bearer token in Authorization header first
				var authHeader = req.headers.get("authorization");
				if (authHeader != null && authHeader.indexOf("Bearer ") == 0) {
					sessionToken = authHeader.substring(7); // Remove "Bearer " prefix
				}

				// Fall back to cookie if no Authorization header
				if (sessionToken == null && req.cookies != null && req.cookies.exists("session_token")) {
					sessionToken = req.cookies.get("session_token");
				}

				if (sessionToken == null) {
					res.sendResponse(HTTPStatus.UNAUTHORIZED);
					res.setHeader("Content-Type", "application/json");
					res.endHeaders();
					res.write(haxe.Json.stringify({error: "Unauthorized - No session token"}));
					res.end();
					return;
				}

				var authService:AuthService = cast DI.get(IAuthService);
				var user = authService.validateSessionToken(sessionToken);

				if (user == null) {
					res.sendResponse(HTTPStatus.UNAUTHORIZED);
					res.setHeader("Content-Type", "application/json");
					res.endHeaders();
					res.write(haxe.Json.stringify({error: "Unauthorized - Invalid or expired token"}));
					res.end();
					return;
				}
				// User is authenticated, continue
			}
			next();
		});

		// Custom login endpoint to set HttpOnly cookie
		router.add("POST", "/api/auth/login", (req:Request, res:Response) -> {
			try {
				var loginRequest:LoginRequest = req.jsonBody;
				if (loginRequest == null || loginRequest.emailOrUsername == null || loginRequest.password == null) {
					res.sendResponse(HTTPStatus.BAD_REQUEST);
					res.setHeader("Content-Type", "application/json");
					res.endHeaders();
					res.write(haxe.Json.stringify({error: "Missing email/username or password"}));
					res.end();
					return;
				}

				var authService:AuthService = cast DI.get(IAuthService);
				var result = authService.login(loginRequest);

				if (result.success) {
					// Use SideWinder setCookie helper (SameSite attribute not currently supported; extend helper if needed)
					res.sendResponse(HTTPStatus.OK);
					res.setHeader("Content-Type", "application/json");
					res.setCookie("session_token", result.token, {path: "/", domain: null, maxAge: "604800", httpOnly: true, secure: false}); // 7 days
					// TODO: Add Secure when serving over HTTPS
					res.endHeaders();
					res.write(haxe.Json.stringify({
						success: true,
						user: result.user
					}));
					res.end();
				} else {
					res.sendResponse(HTTPStatus.UNAUTHORIZED);
					res.setHeader("Content-Type", "application/json");
					res.endHeaders();
					res.write(haxe.Json.stringify({success: false, error: result.error}));
					res.end();
				}
			} catch (e:Dynamic) {
				res.sendResponse(HTTPStatus.INTERNAL_SERVER_ERROR);
				res.setHeader("Content-Type", "application/json");
				res.endHeaders();
				res.write(haxe.Json.stringify({error: "Internal server error"}));
				res.end();
			}
		});

		// Custom logout endpoint to clear cookie
		router.add("POST", "/api/auth/logout", (req:Request, res:Response) -> {
			try {
				// Get session token from cookie to invalidate it
				var sessionToken:String = null;
				if (req.cookies != null && req.cookies.exists("session_token")) {
					sessionToken = req.cookies.get("session_token");
				}

				// Invalidate session in database if token exists
				if (sessionToken != null) {
					var authService:AuthService = cast DI.get(IAuthService);
					authService.invalidateSession(sessionToken);
				} // Clear the cookie
				res.sendResponse(HTTPStatus.OK);
				res.setHeader("Content-Type", "application/json");
				// Clear cookie using helper (SameSite not supported in helper yet)
				res.setCookie("session_token", "", {path: "/", domain: null, maxAge: "0", httpOnly: true, secure: false});
				res.endHeaders();
				res.write(haxe.Json.stringify({success: true}));
				res.end();
			} catch (e:Dynamic) {
				res.sendResponse(HTTPStatus.INTERNAL_SERVER_ERROR);
				res.setHeader("Content-Type", "application/json");
				res.endHeaders();
				res.write(haxe.Json.stringify({error: "Internal server error"}));
				res.end();
			}
		});

		// Build AutoRouter mappings for all controllers
		AutoRouter.build(router, IAuthService, () -> DI.get(IAuthService));
		AutoRouter.build(router, IProjectService, () -> DI.get(IProjectService));
		AutoRouter.build(router, IEnvironmentService, () -> DI.get(IEnvironmentService));
		AutoRouter.build(router, IMachineService, () -> DI.get(IMachineService));
		AutoRouter.build(router, IReleaseService, () -> DI.get(IReleaseService));
		AutoRouter.build(router, IDeploymentService, () -> DI.get(IDeploymentService));
		AutoRouter.build(router, ITenantService, () -> DI.get(ITenantService));
		AutoRouter.build(router, IProjectVariableService, () -> DI.get(IProjectVariableService));
		AutoRouter.build(router, ITenantVariableValueService, () -> DI.get(ITenantVariableValueService));
	}

	// Entry point
	public static function main() {
		var app:Main = new Main();
		app.exec();
	}

	// Override update to serve HTTP requests
	public override function update(deltaTime:Int):Void {
		httpServer.handleRequest();
	}

	// Override createWindow to prevent Lime from creating a window
	override public function createWindow(attributes:WindowAttributes):Window {
		return null;
	}
}
