# Postman Collection Changelog

## Version 1.1.0 - November 12, 2025

### Added Authentication Endpoints
- **Request Password Reset** - `POST /api/auth/reset-password`
- **Verify Email** - `POST /api/auth/verify-email`
- **Refresh Session** - `POST /api/auth/refresh`
- **OAuth Login (Google)** - `POST /api/auth/oauth/google`
- **Link OAuth Provider (GitHub)** - `POST /api/auth/link-oauth/github`

### Fixed HTTP Methods
- **Update Project** - Changed from `POST` to `PUT` (now matches `PUT /api/projects/:id`)
- **Update Variable** - Changed from `POST` to `PUT` (now matches `PUT /api/variables/:id`)

### Added Missing Endpoints
- **Delete All Variables For Project** - `DELETE /api/projects/:projectId/variables`

### Authentication Model Changes
- **Removed**: Bearer token authentication (authToken collection variable)
- **Updated to**: Cookie-based authentication using `session_token` HttpOnly cookie
- Updated Login endpoint test to verify session cookie is set
- Removed Authorization headers from authenticated requests (now handled by cookies)

### Notes
- The Tenant Update endpoint still uses `POST /api/tenants/:id` as defined in `ITenantService`
- All endpoints now properly reflect the service interface definitions
- OAuth endpoints are placeholders - full OAuth implementation is not yet complete in the backend
