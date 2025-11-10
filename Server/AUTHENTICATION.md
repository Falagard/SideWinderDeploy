# Authentication System

The SideWinder Deploy server now includes a complete authentication system supporting both local authentication (username/password) and OAuth integration (framework in place).

## Features

- **User Registration**: Create accounts with email and password
- **Login/Logout**: Session-based authentication with bearer tokens
- **Password Management**: Change password functionality
- **Session Management**: 30-day session duration with automatic cleanup
- **Protected Routes**: Middleware to protect all `/api/` routes except auth endpoints
- **OAuth Ready**: Infrastructure in place for Google, GitHub, Microsoft OAuth

## Database Schema

The authentication system adds three new tables:

### `users`
- `id` (TEXT PRIMARY KEY): Unique user identifier
- `email` (TEXT UNIQUE): User's email address
- `username` (TEXT UNIQUE): Optional username
- `password_hash` (TEXT): Hashed password (SHA256 with salt)
- `created_at` (INTEGER): Unix timestamp
- `updated_at` (INTEGER): Unix timestamp
- `is_active` (INTEGER): Account active status (0/1)
- `email_verified` (INTEGER): Email verification status (0/1)

### `oauth_providers`
- Links users to OAuth providers (Google, GitHub, etc.)
- Stores OAuth tokens for API access

### `sessions`
- `token` (TEXT UNIQUE): Bearer token for authentication
- `user_id` (TEXT): Reference to user
- `expires_at` (INTEGER): Session expiration timestamp
- `ip_address`, `user_agent`: Session metadata

## API Endpoints

### Public Endpoints (No Authentication Required)

#### POST `/api/auth/register`
Register a new user account.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "username": "optional_username"
}
```

**Response:**
```json
{
  "success": true,
  "user": {
    "id": "abc123...",
    "email": "user@example.com",
    "username": "optional_username",
    "emailVerified": false
  }
}
```

#### POST `/api/auth/login`
Authenticate and receive a session token.

**Request Body:**
```json
{
  "emailOrUsername": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "token": "session_token_here",
  "user": {
    "id": "abc123...",
    "email": "user@example.com",
    "username": "username",
    "emailVerified": false
  }
}
```

### Protected Endpoints (Require Authentication)

All protected endpoints require the `Authorization` header:
```
Authorization: Bearer {token}
```

#### GET `/api/auth/me`
Get current authenticated user information.

**Response:**
```json
{
  "id": "abc123...",
  "email": "user@example.com",
  "username": "username",
  "emailVerified": false
}
```

#### POST `/api/auth/logout`
Invalidate the current session.

**Response:**
```json
{
  "success": true
}
```

#### POST `/api/auth/change-password`
Change the user's password.

**Request Body:**
```json
{
  "oldPassword": "current_password",
  "newPassword": "new_password"
}
```

**Response:**
```json
{
  "success": true
}
```

## Testing with Postman

A complete Postman collection is included in `postman/SideWinderDeploy.postman_collection.json`.

### Quick Start:

1. **Import the collection** into Postman
2. **Register a user**: Run "Authentication > Register"
3. **Login**: Run "Authentication > Login" - this automatically saves the token
4. **Test protected routes**: All other API endpoints now require authentication

The login request automatically stores the token in the `authToken` variable, which is used by all protected endpoints.

## OAuth Integration (Coming Soon)

The framework is in place for OAuth authentication. To enable:

1. Set environment variables for OAuth providers:
   - `GOOGLE_CLIENT_ID`
   - `GOOGLE_CLIENT_SECRET`
   
2. Implement OAuth flow endpoints:
   - `POST /api/auth/oauth/:provider` - OAuth login
   - `POST /api/auth/link-oauth/:provider` - Link OAuth to existing account

## Security Considerations

### Current Implementation:
- Passwords are hashed using SHA256 with email as salt
- Sessions expire after 30 days
- Protected routes validate session on every request

### Production Recommendations:
1. **Upgrade password hashing**: Replace SHA256 with bcrypt or Argon2
2. **Add rate limiting**: Prevent brute force attacks
3. **Implement HTTPS**: Always use TLS in production
4. **Add refresh tokens**: Separate access and refresh tokens
5. **Email verification**: Verify email addresses before full access
6. **Password reset**: Implement secure password reset flow
7. **Multi-factor authentication**: Add 2FA support
8. **Session cleanup**: Add background job to clean expired sessions

## Migration

The authentication tables are automatically created when the server starts through the migration file:
- `migrations/2025111101-auth-tables.sql`

To manually run migrations:
```haxe
Database.runMigrations();
```

## Code Structure

- **Interface**: `.haxelib/SideWinderDeployShared/git/Source/sidewinderdeploy/shared/IAuthService.hx`
- **Models**: `.haxelib/SideWinderDeployShared/git/Source/sidewinderdeploy/shared/AuthModels.hx`
- **Implementation**: `Source/deploy/AuthService.hx`
- **Middleware**: `Source/Main.hx` (authentication middleware)

## Middleware Flow

1. Request received
2. Logging middleware logs the request
3. Authentication middleware checks:
   - If path starts with `/api/auth/` → Allow (public endpoints)
   - If path starts with `/api/` → Require Bearer token and validate
   - Otherwise → Allow (static files)
4. If authenticated → Continue to route handler
5. If not authenticated → Return 401 Unauthorized
