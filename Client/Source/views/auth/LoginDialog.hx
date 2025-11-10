package views.auth;

import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.components.TextField;
import haxe.ui.components.Label;
import haxe.ui.components.Button;
import services.AsyncServiceRegistry;
import components.Notifications;
import sidewinderdeploy.shared.AuthModels;
using StringTools;

/** Login dialog for user authentication */
@:build(haxe.ui.ComponentBuilder.build("Assets/login-dialog.xml"))
class LoginDialog extends Dialog {
    public var onLoginSuccess:UserPublic->String->Void; // callback with user and token
    public var onRegisterRequested:Void->Void; // callback to show registration
    
    var emailField:TextField; // from XML
    var passwordField:TextField; // from XML
    var errorLabel:Label; // from XML
    var loginBtn:Button; // from XML
    var registerBtn:Button; // from XML
    var loggingInRow:haxe.ui.containers.HBox; // from XML
    var loggingInSpinner:haxe.ui.components.Progress; // from XML
    
    var asyncServices = AsyncServiceRegistry.instance;
    
    public function new() {
        super();
        this.title = "Sign In";
        this.closable = false; // Force login - can't be dismissed
        this.buttons = null; // using internal buttons
        this.destroyOnClose = true;
        
        if (loginBtn != null) loginBtn.onClick = function(_) doLogin();
        if (registerBtn != null) registerBtn.onClick = function(_) showRegister();
        
        // Focus email field after layout
        haxe.ui.Toolkit.callLater(function() {
            if (emailField != null) emailField.focus = true;
        });
    }
    
    function validate(emailOrUsername:String, password:String):Array<String> {
        var errs = [];
        if (emailOrUsername.length == 0) errs.push("Email/username required");
        if (password.length == 0) errs.push("Password required");
        if (password.length < 6) errs.push("Password must be at least 6 characters");
        return errs;
    }
    
    function doLogin():Void {
        if (loginBtn.disabled) return;
        errorLabel.visible = false;
        
        var emailOrUsername = (emailField.text != null ? emailField.text : "").trim();
        var password = (passwordField.text != null ? passwordField.text : "").trim();
        
        var errs = validate(emailOrUsername, password);
        if (errs.length > 0) {
            errorLabel.text = errs.join("; ");
            errorLabel.visible = true;
            return;
        }
        
        loginBtn.disabled = true;
        if (registerBtn != null) registerBtn.disabled = true;
        if (loggingInRow != null) loggingInRow.visible = true;
        
        var request:LoginRequest = {
            emailOrUsername: emailOrUsername,
            password: password
        };
        
        // Call async auth service
        untyped asyncServices.auth.loginAsync(request, function(response:LoginResponse) {
            loginBtn.disabled = false;
            if (registerBtn != null) registerBtn.disabled = false;
            if (loggingInRow != null) loggingInRow.visible = false;
            
            if (response.success && response.token != null && response.user != null) {
                Notifications.show('Welcome, ' + (response.user.username != null ? response.user.username : response.user.email), 'success');
                if (onLoginSuccess != null) onLoginSuccess(response.user, response.token);
                this.hideDialog("success");
            } else {
                errorLabel.text = response.error != null ? response.error : "Login failed";
                errorLabel.visible = true;
            }
        }, function(err:Dynamic) {
            loginBtn.disabled = false;
            if (registerBtn != null) registerBtn.disabled = false;
            if (loggingInRow != null) loggingInRow.visible = false;
            errorLabel.text = "Login failed: " + Std.string(err);
            errorLabel.visible = true;
        });
    }
    
    function showRegister():Void {
        if (onRegisterRequested != null) onRegisterRequested();
    }
}
