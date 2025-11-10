package views.project;

import haxe.ui.containers.VBox;
import haxe.ui.components.Label;
import haxe.ui.components.TextField;
import haxe.ui.components.Button;
import haxe.ui.components.TextArea;
import sidewinderdeploy.shared.DeployModels; // Release typedef
using StringTools;
import services.ServiceRegistry;
import services.AsyncServiceRegistry;

/** Inline form for creating a new release. Emits callbacks on create/cancel. */
@:build(haxe.ui.ComponentBuilder.build("Assets/create-release-form.xml"))
class CreateReleaseForm extends VBox {
    public var projectId:Int = -1;
    public var onCreated:Release->Void; // set by parent
    public var onCancelled:Void->Void; // optional

    var versionField:TextField; // from XML id versionField
    var notesField:TextArea; // from XML id notesField
    var errorLabel:Label; // from XML id errorLabel
    var createBtn:Button; // from XML id createBtn
    var cancelBtn:Button; // from XML id cancelBtn
    var services = ServiceRegistry.instance; // legacy sync usage kept for now (list reloads etc.)
    var asyncServices = AsyncServiceRegistry.instance; // async client for non-blocking creation

    public function new(projectId:Int) {
        super();
        this.projectId = projectId;
        if (createBtn != null) createBtn.onClick = function(_) doCreate();
        if (cancelBtn != null) cancelBtn.onClick = function(_) handleCancel();
    }

    function doCreate():Void {
        if (createBtn.disabled) return; // prevent double submit
        errorLabel.visible = false;
        var version = versionField.text.trim();
        var notes = notesField.text.trim();

        var errors = validate(version, notes);
        if (errors.length > 0) {
            errorLabel.text = errors.join("; ");
            errorLabel.visible = true;
            return;
        }

        var release:Release = {
            id: 0,
            projectId: projectId,
            version: version,
            notes: notes,
            // createdAt expects a Date (DeployModels.Release)
            createdAt: Date.now()
        };
        // disable create button while pending
        createBtn.disabled = true;
        untyped asyncServices.release.createReleaseAsync(projectId, release, function(created:Release) {
            createBtn.disabled = false;
            if (onCreated != null) onCreated(created);
            // clear inputs after success
            versionField.text = "";
            notesField.text = "";
        }, function(err:Dynamic) {
            createBtn.disabled = false;
            errorLabel.text = "Failed to create release: " + err;
            errorLabel.visible = true;
        });
    }

    function handleCancel():Void {
        if (onCancelled != null) onCancelled();
    }

    function validate(version:String, notes:String):Array<String> {
        var errs = [];
        if (version.length == 0) errs.push("Version required");
        // Basic semantic version check (optional)
        var semverRegex = ~/^\d+(\.\d+){0,2}(-[A-Za-z0-9]+)?$/;
        if (!semverRegex.match(version)) errs.push("Version format unexpected");
        if (notes.length == 0) errs.push("Notes required");
        return errs;
    }
}
