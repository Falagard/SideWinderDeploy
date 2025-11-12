package views.project;

import haxe.ui.containers.VBox;
import haxe.ui.components.Label;
import haxe.ui.components.TextField;
import haxe.ui.components.TextArea;
import haxe.ui.components.Button;
import haxe.ui.containers.dialogs.Dialog;
import services.AsyncServiceRegistry;
import sidewinderdeploy.shared.DeployModels; // brings Project typedef
import components.Notifications; // toast feedback
using StringTools;

/** Modal dialog for creating a new project. */
@:build(haxe.ui.ComponentBuilder.build("Assets/create-project-dialog.xml"))
class CreateProjectDialog extends Dialog {
    public var onCreated:Project->Void; // optional callback
    public var onCancelled:Void->Void; // optional callback

    var nameField:TextField; // from XML
    var descField:TextArea; // from XML
    var errorLabel:Label; // from XML
    var createBtn:Button; // from XML
    var cancelBtn:Button; // from XML
    var savingRow:haxe.ui.containers.HBox; // from XML
    var savingSpinner:haxe.ui.components.Progress; // from XML (indeterminate)

    var asyncServices = AsyncServiceRegistry.instance;

    public function new() {
        super();
        // Dialog configuration similar to ProjectVariablesTab / ReleasesTab pattern
        this.title = "Create Project";
        this.closable = true;
        this.buttons = null; // internal buttons
        this.destroyOnClose = true;
        // dialogParent assigned at show time if needed (caller will set showDialog(true))
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
        var re = ~/^[A-Za-z0-9 _-]+$/;
        if (!re.match(name)) errs.push("Invalid characters in name");
        return errs;
    }

    function doCreate():Void {
        if (createBtn.disabled) return;
        errorLabel.visible = false;
        var name = (nameField.text != null ? nameField.text : "").trim();
        var desc = (descField.text != null ? descField.text : "").trim();
        var errs = validate(name);
        if (errs.length > 0) {
            errorLabel.text = errs.join("; ");
            errorLabel.visible = true;
            return;
        }
        createBtn.disabled = true;
        if (savingRow != null) savingRow.visible = true;
        var project:Project = {
            id: 0,
            name: name,
            description: desc,
            createdAt: Date.now()
        };
        // Guessing service signature based on release pattern: createProjectAsync(project)
        // Adjust if API differs.
        untyped asyncServices.project.createProjectAsync(project, function(created:Project) {
            createBtn.disabled = false;
            if (savingRow != null) savingRow.visible = false;
            Notifications.show('Project "' + created.name + '" created', 'success');
            if (onCreated != null) onCreated(created);
            // hide dialog ("success" reason similar to existing tabs)
            this.hideDialog("success");
        }, function(err:Dynamic) {
            createBtn.disabled = false;
            if (savingRow != null) savingRow.visible = false;
            errorLabel.text = "Failed to create project: " + Std.string(err);
            errorLabel.visible = true;
        });
    }

    function handleCancel():Void {
        // simply hide; onDialogClosed can be wired externally if needed
        this.hideDialog("cancel");
        if (onCancelled != null) onCancelled();
    }
}
