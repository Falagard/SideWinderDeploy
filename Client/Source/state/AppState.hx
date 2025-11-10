package state;

import services.ServiceRegistry;
import services.AsyncServiceRegistry;
import sidewinderdeploy.shared.AuthModels;

/** Global application state & selections */
class AppState {
    public static var instance(default, null):AppState = new AppState();

    public var services:ServiceRegistry;
    public var asyncServices:AsyncServiceRegistry; // global async service access

    // Authentication state
    public var currentUser:Observable<Null<UserPublic>> = new Observable<Null<UserPublic>>(null);
    public var authToken:Observable<Null<String>> = new Observable<Null<String>>(null);
    public var isAuthenticated(get, never):Bool;

    // Current selections
    public var selectedProjectId:Observable<Int> = new Observable<Int>(-1);
    public var selectedEnvironmentId:Observable<Int> = new Observable<Int>(-1);
    public var selectedMachineId:Observable<Int> = new Observable<Int>(-1);
    public var selectedTenantId:Observable<Int> = new Observable<Int>(-1);
    public var selectedPrimaryCategory:Observable<String> = new Observable<String>("Projects");

    private function new() {
        services = ServiceRegistry.instance;
        asyncServices = AsyncServiceRegistry.instance;
    }

    function get_isAuthenticated():Bool {
        return currentUser.value != null && authToken.value != null;
    }

    public function setAuthentication(user:UserPublic, token:String):Void {
        currentUser.value = user;
        authToken.value = token;
        // Store token in local storage for persistence
        #if js
        try {
            js.Browser.window.localStorage.setItem("authToken", token);
        } catch (e:Dynamic) {
            trace("Failed to save auth token to localStorage: " + e);
        }
        #end
    }

    public function clearAuthentication():Void {
        currentUser.value = null;
        authToken.value = null;
        #if js
        try {
            js.Browser.window.localStorage.removeItem("authToken");
        } catch (e:Dynamic) {
            trace("Failed to remove auth token from localStorage: " + e);
        }
        #end
    }

    public function loadStoredToken():Null<String> {
        #if js
        try {
            return js.Browser.window.localStorage.getItem("authToken");
        } catch (e:Dynamic) {
            trace("Failed to load auth token from localStorage: " + e);
            return null;
        }
        #else
        return null;
        #end
    }
}
