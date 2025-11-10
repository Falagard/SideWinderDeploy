# Authentication Flow

This document describes the login and registration flow implemented using the IAuthService and HaxeUI.

## Components

### 1. LoginDialog (`Source/views/auth/LoginDialog.hx`)
- Modal dialog for user authentication
- Fields: email/username, password
- Features:
  - Client-side validation
  - Error display
  - Loading state with spinner
  - "Create Account" button to switch to registration
  - Callback support for successful login

### 2. RegisterDialog (`Source/views/auth/RegisterDialog.hx`)
- Modal dialog for user registration
- Fields: email, username (optional), password, confirm password
- Features:
  - Email format validation
  - Password strength check (minimum 6 characters)
  - Password confirmation matching
  - Username validation (alphanumeric, hyphens, underscores only)
  - Loading state with spinner
  - "Back to Sign In" button to return to login
  - Success message prompts user to verify email

### 3. AuthManager (`Source/views/auth/AuthManager.hx`)
- Centralized authentication management
- Responsibilities:
  - Check authentication on app startup
  - Manage login/registration dialog lifecycle
  - Handle stored token verification
  - Provide logout functionality
- Methods:
  - `checkAuthentication()`: Verifies stored token or shows login
  - `showLogin()`: Displays login dialog
  - `showRegister()`: Displays registration dialog
  - `logout()`: Signs user out and reloads app

### 4. AppState Updates (`Source/state/AppState.hx`)
- Added authentication state management:
  - `currentUser`: Observable<UserPublic> - current authenticated user
  - `authToken`: Observable<String> - JWT token
  - `isAuthenticated`: Computed property
- Methods:
  - `setAuthentication(user, token)`: Updates auth state and saves token to localStorage
  - `clearAuthentication()`: Clears auth state and removes token from localStorage
  - `loadStoredToken()`: Retrieves token from localStorage

### 5. Service Registry Updates
- Added `IAuthService` to both `ServiceRegistry` and `AsyncServiceRegistry`
- Auth service provides methods:
  - `login(request)`: Authenticate with email/username and password
  - `register(request)`: Create new user account
  - `logout()`: End current session
  - `getCurrentUser()`: Fetch current user info (for token verification)

### 6. MainView Updates (`Source/MainView.hx`)
- Added top bar with:
  - App title
  - User display (shows username or email when authenticated)
  - Sign Out button
- User display automatically updates when authentication state changes
- Logout handler clears auth and reloads app to show login dialog

### 7. Main App Updates (`Source/Main.hx`)
- Initializes `AuthManager` on app startup
- Calls `checkAuthentication()` to verify stored token or show login
- Added CSS styles for authentication dialogs and top bar

## User Flow

### First-Time User (Registration)
1. App loads → AuthManager checks for stored token → None found → Login dialog appears
2. User clicks "Create Account" → Registration dialog appears
3. User enters email, optional username, password, confirm password
4. Validation checks:
   - Email format
   - Password length (≥6 characters)
   - Passwords match
   - Username format (if provided)
5. Click "Create Account" → Async call to `auth.registerAsync()`
6. Success → Notification shown: "Account created! Please check your email..."
7. Registration dialog closes → Login dialog appears
8. User enters credentials → Login as normal

### Returning User (Login)
1. App loads → AuthManager checks for stored token
2. If token exists:
   - Call `auth.getCurrentUserAsync()` to verify token
   - Success → User authenticated, main app visible
   - Failure → Token invalid, show login dialog
3. If no token → Show login dialog
4. User enters email/username and password
5. Click "Sign In" → Async call to `auth.loginAsync()`
6. Success:
   - Token stored in localStorage
   - User info stored in AppState
   - Welcome notification shown
   - Login dialog closes
   - Main app visible with user's name in top bar

### Logout
1. User clicks "Sign Out" button in top bar
2. Async call to `auth.logoutAsync()` to end server session
3. Clear authentication state (token removed from localStorage)
4. Notification shown: "Signed out successfully"
5. Page reloads → AuthManager shows login dialog

## Token Storage

- JWT token stored in browser localStorage (key: "authToken")
- Token automatically loaded on app startup
- Token verified by calling `getCurrentUser()` endpoint
- Invalid/expired tokens are cleared and login shown
- **XHR Interceptor**: Automatic injection of `Authorization: Bearer {token}` header on all `/api/` requests (except `/api/auth/`)

### Authorization Header Injection

The client uses an XMLHttpRequest interceptor (JavaScript/HTML5 target) to automatically add the Authorization header to all API requests:

```haxe
// In Main.hx - installed before app starts
XMLHttpRequest.prototype.open = function(method, url) {
    this._url = url;
    return originalOpen.apply(this, arguments);
};

XMLHttpRequest.prototype.send = function() {
    // Add auth header to API requests (except /api/auth/ endpoints)
    if (this._url && this._url.indexOf('/api/') !== -1) {
        if (this._url.indexOf('/api/auth/') === -1) {
            var token = window.localStorage.getItem('authToken');
            if (token) {
                this.setRequestHeader('Authorization', 'Bearer ' + token);
            }
        }
    }
    return originalSend.apply(this, arguments);
};
```

This ensures:
- All protected API endpoints receive the auth token
- Auth endpoints (login, register) don't get the header (as they shouldn't need it)
- No modification needed to service calls - authorization is transparent
- Token is read fresh from localStorage on each request

## Security Considerations

1. **Password Requirements**: Minimum 6 characters (can be enhanced)
2. **HTTPS Required**: Tokens should only be transmitted over HTTPS in production
3. **Token Expiry**: Server should handle token expiration; client verifies on startup
4. **Email Verification**: Registration prompts email verification (server-side)
5. **XSS Protection**: HaxeUI handles input sanitization

## Future Enhancements

1. **Remember Me**: Optional extended token lifetime
2. **Password Reset**: Add "Forgot Password?" link in login dialog
3. **OAuth Integration**: Enable Google, GitHub, etc. (IAuthService already supports it)
4. **Session Refresh**: Automatically refresh tokens before expiry
5. **Multi-factor Auth**: Add 2FA support
6. **Better Password Strength**: Visual indicator for password strength
7. **Error Rate Limiting**: Prevent brute force attempts

## CSS Styling

Authentication dialogs use consistent styling with other dialogs:
- `.loginDialog`, `.registerDialog`: White background, rounded corners, shadow
- `.dialogTitle`: Larger, bold text for dialog titles
- `.topSpacing`: Vertical spacing between form fields
- `.topBar`: Dark background for app header
- `.userLabel`: Light text color for username display
- `.logoutBtn`: Red background for sign-out button

## Testing

To test the authentication flow:

1. **Registration**:
   - Try invalid email format
   - Try weak password (< 6 chars)
   - Try mismatched passwords
   - Successfully register new account

2. **Login**:
   - Try invalid credentials
   - Successfully log in with valid credentials
   - Verify token persistence (refresh page, should stay logged in)

3. **Logout**:
   - Click sign-out button
   - Verify token cleared
   - Verify login dialog reappears

4. **Token Expiry**:
   - Manually set expired token in localStorage
   - Reload app
   - Verify login dialog appears
