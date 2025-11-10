package views.auth;

import haxe.ui.core.Component;
import state.AppState;
import views.auth.LoginDialog;
import views.auth.RegisterDialog;
import components.Notifications;
import sidewinderdeploy.shared.AuthModels;

/**
 * Authentication manager - handles login/registration flow
 */
class AuthManager {
    var appState = AppState.instance;
    var parentComponent:Component;
    var loginDialog:LoginDialog;
    var registerDialog:RegisterDialog;
    
    public function new(parent:Component) {
        this.parentComponent = parent;
    }
    
    /**
     * Check if user is authenticated, show login if not
     * Returns true if already authenticated
     */
    public function checkAuthentication():Bool {
        // Try to load stored token
        var storedToken = appState.loadStoredToken();
        if (storedToken != null) {
            // Verify the stored token is still valid
            verifyStoredToken(storedToken);
            // Assume valid for now, will update if verification fails
            return true;
        }
        
        // No stored token, show login
        showLogin();
        return false;
    }
    
    function verifyStoredToken(token:String):Void {
        // Call getCurrentUser to verify the token
        untyped appState.asyncServices.auth.getCurrentUserAsync(function(user:Null<UserPublic>) {
            if (user != null) {
                // Token is valid, update app state
                appState.setAuthentication(user, token);
                Notifications.show('Welcome back, ' + (user.username != null ? user.username : user.email), 'info');
            } else {
                // Token invalid, clear it and show login
                appState.clearAuthentication();
                showLogin();
            }
        }, function(err:Dynamic) {
            // Token verification failed, clear and show login
            trace('Token verification failed: ' + err);
            appState.clearAuthentication();
            showLogin();
        });
    }
    
    public function showLogin():Void {
        if (loginDialog != null) return; // already showing
        
        loginDialog = new LoginDialog();
        loginDialog.dialogParent = parentComponent;
        
        loginDialog.onLoginSuccess = function(user:UserPublic, token:String) {
            appState.setAuthentication(user, token);
            loginDialog = null;
        };
        
        loginDialog.onRegisterRequested = function() {
            // Close login and show registration
            if (loginDialog != null) {
                loginDialog.hideDialog("cancel");
                loginDialog = null;
            }
            showRegister();
        };
        
        loginDialog.showDialog(true);
    }
    
    public function showRegister():Void {
        if (registerDialog != null) return; // already showing
        
        registerDialog = new RegisterDialog();
        registerDialog.dialogParent = parentComponent;
        
        registerDialog.onRegisterSuccess = function(user:UserPublic) {
            registerDialog = null;
            // After registration, show login for user to sign in
            Notifications.show('Please sign in with your new account', 'info', 3000);
            haxe.ui.Toolkit.callLater(function() {
                showLogin();
            });
        };
        
        registerDialog.onBackToLogin = function() {
            // Close registration and show login
            if (registerDialog != null) {
                registerDialog.hideDialog("cancel");
                registerDialog = null;
            }
            showLogin();
        };
        
        registerDialog.showDialog(true);
    }
    
    public function logout():Void {
        untyped appState.asyncServices.auth.logoutAsync(function(success:Bool) {
            appState.clearAuthentication();
            Notifications.show('Signed out successfully', 'info');
            showLogin();
        }, function(err:Dynamic) {
            // Still clear local auth even if server call fails
            appState.clearAuthentication();
            Notifications.show('Signed out', 'info');
            showLogin();
        });
    }
}
