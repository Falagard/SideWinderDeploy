package views.auth;

import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.components.TextField;
import haxe.ui.components.Label;
import haxe.ui.components.Button;
import services.AsyncServiceRegistry;
import components.Notifications;
import sidewinderdeploy.shared.AuthModels;
using StringTools;

/** Registration dialog for creating new user accounts */
@:build(haxe.ui.ComponentBuilder.build("Assets/register-dialog.xml"))
class RegisterDialog extends Dialog {
    public var onRegisterSuccess:UserPublic->Void; // callback with user info
    public var onBackToLogin:Void->Void; // callback to return to login
    
    var emailField:TextField; // from XML
    var usernameField:TextField; // from XML
    var passwordField:TextField; // from XML
    var confirmPasswordField:TextField; // from XML
    var errorLabel:Label; // from XML
    var registerBtn:Button; // from XML
    var backToLoginBtn:Button; // from XML
    var registeringRow:haxe.ui.containers.HBox; // from XML
    var registeringSpinner:haxe.ui.components.Progress; // from XML
    
    var asyncServices = AsyncServiceRegistry.instance;
    
    public function new() {
        super();
        this.title = "Create Account";
        this.closable = false; // Force registration flow
        this.buttons = null; // using internal buttons
        this.destroyOnClose = true;
        
        if (registerBtn != null) registerBtn.onClick = function(_) doRegister();
        if (backToLoginBtn != null) backToLoginBtn.onClick = function(_) goBackToLogin();
        
        // Focus email field after layout
        haxe.ui.Toolkit.callLater(function() {
            if (emailField != null) emailField.focus = true;
        });
    }
    
    function validate(email:String, password:String, confirmPassword:String, username:String):Array<String> {
        var errs = [];
        
        // Email validation
        if (email.length == 0) {
            errs.push("Email required");
        } else {
            var emailRegex = ~/^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.match(email)) errs.push("Invalid email format");
        }
        
        // Password validation
        if (password.length == 0) {
            errs.push("Password required");
        } else if (password.length < 6) {
            errs.push("Password must be at least 6 characters");
        }
        
        // Confirm password
        if (password != confirmPassword) {
            errs.push("Passwords do not match");
        }
        
        // Username validation (optional)
        if (username.length > 0) {
            var usernameRegex = ~/^[A-Za-z0-9_-]+$/;
            if (!usernameRegex.match(username)) {
                errs.push("Username can only contain letters, numbers, hyphens, and underscores");
            }
            if (username.length < 3) {
                errs.push("Username must be at least 3 characters");
            }
        }
        
        return errs;
    }
    
    function doRegister():Void {
        if (registerBtn.disabled) return;
        errorLabel.visible = false;
        
        var email = (emailField.text != null ? emailField.text : "").trim();
        var username = (usernameField.text != null ? usernameField.text : "").trim();
        var password = (passwordField.text != null ? passwordField.text : "").trim();
        var confirmPassword = (confirmPasswordField.text != null ? confirmPasswordField.text : "").trim();
        
        var errs = validate(email, password, confirmPassword, username);
        if (errs.length > 0) {
            errorLabel.text = errs.join("; ");
            errorLabel.visible = true;
            return;
        }
        
        registerBtn.disabled = true;
        if (backToLoginBtn != null) backToLoginBtn.disabled = true;
        if (registeringRow != null) registeringRow.visible = true;
        
        var request:RegisterRequest = {
            email: email,
            password: password,
            username: username.length > 0 ? username : null
        };
        
        // Call async auth service
        untyped asyncServices.auth.registerAsync(request, function(response:RegisterResponse) {
            registerBtn.disabled = false;
            if (backToLoginBtn != null) backToLoginBtn.disabled = false;
            if (registeringRow != null) registeringRow.visible = false;
            
            if (response.success && response.user != null) {
                Notifications.show('Account created! Please check your email to verify your account.', 'success');
                if (onRegisterSuccess != null) onRegisterSuccess(response.user);
                this.hideDialog("success");
            } else {
                errorLabel.text = response.error != null ? response.error : "Registration failed";
                errorLabel.visible = true;
            }
        }, function(err:Dynamic) {
            registerBtn.disabled = false;
            if (backToLoginBtn != null) backToLoginBtn.disabled = false;
            if (registeringRow != null) registeringRow.visible = false;
            errorLabel.text = "Registration failed: " + Std.string(err);
            errorLabel.visible = true;
        });
    }
    
    function goBackToLogin():Void {
        if (onBackToLogin != null) onBackToLogin();
    }
}
