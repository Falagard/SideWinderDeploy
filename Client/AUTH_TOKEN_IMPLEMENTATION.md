# Authentication Token Implementation

## Issue

The server requires all `/api/` requests (except `/api/auth/`) to include an `Authorization: Bearer {token}` header for authentication. However, the current `AutoClientAsync` implementation doesn't support adding custom headers to requests.

## Current Server Middleware

```haxe
// From Server/Source/Main.hx
App.use((req, res, next) -> {
    // Skip auth for auth endpoints
    if (req.path.indexOf("/api/auth/") == 0) {
        next();
        return;
    }
    
    // Require authentication for all other /api/ routes
    if (req.path.indexOf("/api/") == 0) {
        var authHeader = req.headers.get("authorization");
        if (authHeader == null || authHeader.indexOf("Bearer ") != 0) {
            res.sendResponse(HTTPStatus.UNAUTHORIZED);
            // ... send error response
            return;
        }
        
        var token = authHeader.substring(7); // Remove "Bearer " prefix
        var authService:AuthService = cast DI.get(IAuthService);
        var user = authService.validateSessionToken(token);
        
        if (user == null) {
            res.sendResponse(HTTPStatus.UNAUTHORIZED);
            // ... send error response
            return;
        }
    }
    next();
});
```

## Solutions

### Solution 1: Update SideWinder AutoClientAsync (Recommended)

Modify the SideWinder library's `AutoClientAsync` to support optional headers parameter:

```haxe
// In SideWinder library
class AutoClientAsync {
    public static function create<T>(
        serviceInterface:Class<T>, 
        baseUrl:String,
        ?headers:Map<String, String>
    ):T {
        // Implementation that includes headers in all HTTP requests
        // ...
    }
}
```

Then update `AsyncServiceRegistry` to pass auth headers:

```haxe
private function createClients():Void {
    var headers = getAuthHeaders();
    
    project = AutoClientAsync.create(IProjectService, baseUrl, headers);
    release = AutoClientAsync.create(IReleaseService, baseUrl, headers);
    // ... etc
    auth = AutoClientAsync.create(IAuthService, baseUrl, null); // No auth for auth endpoints
}

private function getAuthHeaders():Null<Map<String, String>> {
    var token = AppState.instance.authToken.value;
    if (token != null && token.length > 0) {
        var headers = new Map<String, String>();
        headers.set("Authorization", "Bearer " + token);
        return headers;
    }
    return null;
}
```

### Solution 2: Create Request Interceptor Wrapper

Create a wrapper around service calls that adds headers:

```haxe
// In AsyncServiceRegistry.hx
class AsyncServiceRegistry {
    // ... fields ...
    
    private var _rawProject:Dynamic;
    private var _rawRelease:Dynamic;
    // ... etc
    
    public var project(get, never):Dynamic;
    
    function get_project():Dynamic {
        return wrapServiceWithAuth(_rawProject);
    }
    
    private function wrapServiceWithAuth(service:Dynamic):Dynamic {
        // Create proxy that intercepts all method calls
        // and adds Authorization header before making request
        // This requires access to the underlying HTTP implementation
    }
}
```

### Solution 3: XMLHttpRequest Interceptor (JS Target Only)

For JavaScript/HTML5 target, intercept all XHR requests:

```haxe
#if js
// In Main.hx, before app starts
js.Syntax.code("
    (function() {
        var originalOpen = XMLHttpRequest.prototype.open;
        var originalSend = XMLHttpRequest.prototype.send;
        
        XMLHttpRequest.prototype.open = function(method, url) {
            this._url = url;
            return originalOpen.apply(this, arguments);
        };
        
        XMLHttpRequest.prototype.send = function() {
            // Add auth header to API requests
            if (this._url && this._url.indexOf('/api/') !== -1 && 
                this._url.indexOf('/api/auth/') === -1) {
                var token = window.localStorage.getItem('authToken');
                if (token) {
                    this.setRequestHeader('Authorization', 'Bearer ' + token);
                }
            }
            return originalSend.apply(this, arguments);
        };
    })();
");
#end
```

### Solution 4: Update Server to Use Cookies

Alternative: Modify server to use httpOnly cookies instead of Bearer tokens:

```haxe
// In Server AuthService
public function login(request:LoginRequest):LoginResponse {
    // ... validate credentials ...
    
    // Set httpOnly cookie instead of returning token
    // Client automatically sends cookie with each request
    // No need to add Authorization header
}
```

This is more secure (httpOnly cookies can't be accessed by JavaScript, preventing XSS attacks) but requires CORS configuration for cross-origin requests.

## Recommended Implementation Order

1. **Implement Solution 3 (XHR Interceptor)** - Quick fix for HTML5 target, gets authentication working immediately
2. **Implement Solution 1 (Update SideWinder)** - Proper long-term solution that works for all targets
3. **Consider Solution 4 (Cookies)** - Best security practice for production

## Current Workaround

Until one of the above solutions is implemented, the authentication endpoints work but protected endpoints will return 401 Unauthorized errors. You can temporarily disable the auth middleware on the server for development:

```haxe
// In Server/Source/Main.hx
// Comment out the authentication middleware
// App.use((req, res, next) -> { ... });
```

## Implementation Status

- ✅ Authentication dialogs (Login/Register) created
- ✅ Auth state management added
- ✅ Token storage in localStorage
- ✅ IAuthService added to service registries
- ✅ **Authorization header injection (IMPLEMENTED - Solution 3)**
- ✅ Protected API endpoints will now work with authentication

## Current Implementation

**Solution 3 (XHR Interceptor)** has been implemented in `Main.hx`:

```haxe
#if js
static function installAuthInterceptor():Void {
    js.Syntax.code("
        (function() {
            var originalOpen = XMLHttpRequest.prototype.open;
            var originalSend = XMLHttpRequest.prototype.send;
            
            XMLHttpRequest.prototype.open = function(method, url) {
                this._url = url;
                return originalOpen.apply(this, arguments);
            };
            
            XMLHttpRequest.prototype.send = function() {
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
        })();
    ");
}
#end
```

This interceptor:
- ✅ Runs before any HTTP requests are made
- ✅ Automatically adds `Authorization: Bearer {token}` to all `/api/` requests
- ✅ Skips `/api/auth/` endpoints (login, register don't need auth)
- ✅ Reads token fresh from localStorage on each request
- ✅ Works transparently - no changes needed in service code
- ✅ Only active on HTML5/JS target (uses `#if js` conditional compilation)

## Future Enhancements

While Solution 3 works well for HTML5, consider implementing **Solution 1 (Update SideWinder)** for:
- Cross-platform support (HashLink, C++, etc.)
- Type-safe header management
- Better testability
- Cleaner architecture
