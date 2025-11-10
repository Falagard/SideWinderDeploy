package views.environment;

import haxe.ui.containers.VBox;
import haxe.ui.components.Label;
import haxe.ui.components.TextField;
import haxe.ui.components.Button;
import haxe.ui.containers.dialogs.Dialog;
import services.AsyncServiceRegistry;
import sidewinderdeploy.shared.DeployModels; // brings Environment typedef
import components.Notifications; // toast feedback
using StringTools;

/** Modal dialog for creating a new environment. */
@:build(haxe.ui.ComponentBuilder.build("Assets/create-environment-dialog.xml"))
class CreateEnvironmentDialog extends Dialog {
    public var onCreated:Environment->Void; // optional callback
    public var onCancelled:Void->Void; // optional callback

    var nameField:TextField; // from XML
    var errorLabel:Label; // from XML
    var createBtn:Button; // from XML
    var cancelBtn:Button; // from XML
    var savingRow:haxe.ui.containers.HBox; // from XML
    var savingSpinner:haxe.ui.components.Progress; // from XML (indeterminate)

    var asyncServices = AsyncServiceRegistry.instance;

    public function new() {
        super();
        // Dialog configuration
        this.title = "Create Environment";
        this.closable = true;
        this.buttons = null; // internal buttons
        this.destroyOnClose = true;
        
        if (createBtn != null) createBtn.onClick = function(_) doCreate();
        if (cancelBtn != null) cancelBtn.onClick = function(_) handleCancel();
        
        // Defer focus until after layout
        haxe.ui.Toolkit.callLater(function() {
            if (nameField != null) nameField.focus = true;
        });
    }

    function validate(name:String):Array<String> {
        var errs = [];
        if (name.length == 0) errs.push("Name required");
        
        // Basic name rule: letters, numbers, space, dash, underscore
        var nameRe = ~/^[A-Za-z0-9 _-]+$/;
        if (!nameRe.match(name)) errs.push("Invalid characters in name");
        
        return errs;
    }

    function doCreate():Void {
        if (createBtn.disabled) return;
        errorLabel.visible = false;
        
        var name = nameField.text.trim();
        
        var errs = validate(name);
        if (errs.length > 0) {
            errorLabel.text = errs.join("; ");
            errorLabel.visible = true;
            return;
        }
        
        createBtn.disabled = true;
        if (savingRow != null) savingRow.visible = true;
        
        var environment:Environment = {
            id: 0,
            name: name,
            createdAt: Date.now()
        };
        
        // Call the async environment service to create the environment
        untyped asyncServices.environment.createEnvironmentAsync(environment, function(created:Environment) {
            createBtn.disabled = false;
            if (savingRow != null) savingRow.visible = false;
            Notifications.show('Environment "' + created.name + '" created', 'success');
            if (onCreated != null) onCreated(created);
            // hide dialog with "success" reason
            this.hideDialog("success");
        }, function(err:Dynamic) {
            createBtn.disabled = false;
            if (savingRow != null) savingRow.visible = false;
            errorLabel.text = "Failed to create environment: " + Std.string(err);
            errorLabel.visible = true;
        });
    }

    function handleCancel():Void {
        // simply hide; onDialogClosed can be wired externally if needed
        this.hideDialog("cancel");
        if (onCancelled != null) onCancelled();
    }
}
