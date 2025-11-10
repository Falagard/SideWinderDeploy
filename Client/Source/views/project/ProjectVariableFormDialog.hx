package views.project;

import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.components.TextField;
import haxe.ui.components.Label;
import haxe.ui.components.Button;
import services.AsyncServiceRegistry;
import components.Notifications;
import sidewinderdeploy.shared.DeployModels.ProjectVariable;
using StringTools;

@:build(haxe.ui.ComponentBuilder.build("Assets/project-variable-dialog.xml"))
class ProjectVariableFormDialog extends Dialog {
    public var projectId:Int;
    public var editingVariable:ProjectVariable; // null for create
    public var onSaved:ProjectVariable->Void; // invoked after create/update
    public var onCancelled:Void->Void; // optional

    var nameField:TextField; // from XML
    var valueField:TextField; // from XML
    var errorLabel:Label; // from XML
    var saveBtn:Button; // from XML
    var cancelBtn:Button; // from XML
    var savingRow:haxe.ui.containers.HBox; // from XML
    var savingSpinner:haxe.ui.components.Progress; // from XML

    var asyncServices = AsyncServiceRegistry.instance;

    public function new(projectId:Int, ?editing:ProjectVariable) {
        super();
        this.projectId = projectId;
        this.editingVariable = editing;
        this.title = (editing == null ? "Add Variable" : "Edit Variable");
        this.buttons = null;
        this.closable = true;
        this.destroyOnClose = true;
        if (editing != null) {
            nameField.text = editing.name;
            valueField.text = editing.defaultValue;
        }
        saveBtn.onClick = function(_) doSave();
        cancelBtn.onClick = function(_) cancel();
        haxe.ui.Toolkit.callLater(function() {
            if (nameField != null) nameField.focus = true;
        });
    }

    function validate(name:String):Array<String> {
        var errs = [];
        if (name.length == 0) errs.push("Name required");
        var re = ~/^[A-Za-z0-9 _-]+$/;
        if (!re.match(name)) errs.push("Invalid characters in name");
        return errs;
    }

    function doSave():Void {
        if (saveBtn.disabled) return;
        errorLabel.visible = false;
        var name = nameField.text.trim();
        var value = valueField.text; // allow empty value
        var errs = validate(name);
        if (errs.length > 0) {
            errorLabel.text = errs.join("; ");
            errorLabel.visible = true;
            return;
        }
        saveBtn.disabled = true;
        if (savingRow != null) savingRow.visible = true;
        if (editingVariable == null) createVariable(name, value) else updateVariable(name, value);
    }

    function createVariable(name:String, value:String):Void {
        var variable:ProjectVariable = {
            id: 0,
            projectId: projectId,
            name: name,
            defaultValue: value,
            createdAt: Date.now()
        };
        untyped asyncServices.projectVariable.createProjectVariableAsync(projectId, variable, function(created:ProjectVariable) {
            saveBtn.disabled = false;
            if (savingRow != null) savingRow.visible = false;
            Notifications.show('Variable "' + created.name + '" created', 'success');
            if (onSaved != null) onSaved(created);
            this.hideDialog("success");
        }, function(err:Dynamic) {
            saveBtn.disabled = false;
            if (savingRow != null) savingRow.visible = false;
            errorLabel.text = 'Create failed: ' + Std.string(err);
            errorLabel.visible = true;
        });
    }

    function updateVariable(name:String, value:String):Void {
        var updated:ProjectVariable = {
            id: editingVariable.id,
            projectId: editingVariable.projectId,
            name: name,
            defaultValue: value,
            createdAt: editingVariable.createdAt
        };
        untyped asyncServices.projectVariable.updateProjectVariableAsync(editingVariable.id, updated, function(ret:ProjectVariable) {
            saveBtn.disabled = false;
            if (savingRow != null) savingRow.visible = false;
            Notifications.show('Variable updated', 'success');
            if (onSaved != null) onSaved(ret);
            this.hideDialog("success");
        }, function(err:Dynamic) {
            saveBtn.disabled = false;
            if (savingRow != null) savingRow.visible = false;
            errorLabel.text = 'Update failed: ' + Std.string(err);
            errorLabel.visible = true;
        });
    }

    function cancel():Void {
        this.hideDialog("cancel");
        if (onCancelled != null) onCancelled();
        if (savingRow != null) savingRow.visible = false;
    }
}
