package views.project;

import haxe.ui.containers.VBox;
import haxe.ui.containers.HBox;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.core.Component;
import components.ErrorBanner;
import views.deployment.DeploymentWizard;
import components.Notifications;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.Toolkit;
import services.ServiceRegistry;
import services.AsyncServiceRegistry;
import sidewinderdeploy.shared.DeployModels; // Release typedef
import state.AppState; // observe selectedProjectId

/** Tab that lists releases for the selected project. */
@:build(haxe.ui.ComponentBuilder.build("Assets/releases-tab.xml"))
class ReleasesTab extends VBox {
    public var projectId:Int = -1;
    var services = ServiceRegistry.instance; // kept for future sync fallbacks (e.g. until create form converted)
    var asyncServices = AsyncServiceRegistry.instance; // async clients (Dynamic fields with *Async methods)
    var actionsBar:HBox; // from XML id actionsBar
    var createReleaseBtn:Button; // from XML id createReleaseBtn
    var formContainer:VBox; // from XML id formContainer
    var listContainer:VBox; // from XML id listContainer
    var createForm:CreateReleaseForm; // lazily instantiated
    var createFormDialog:Dialog; // dialog wrapping the create form

	var errorBanner:ErrorBanner;

    public function new() {
        super();
        // Wire button event from XML
        if (createReleaseBtn != null) createReleaseBtn.onClick = function(_) toggleCreateForm();
        // Watch global selected project and auto-reload if it changes
        AppState.instance.selectedProjectId.watch(function(pid:Int) {
            // Avoid redundant reloads
            if (pid != projectId) {
                loadReleases(pid);
            } else if (pid >= 0 && listContainer.numComponents == 0) {
                // Edge case: project unchanged but list cleared (e.g. recreation)
                loadReleases(pid);
            }
        });
    }

    public function loadReleases(projectId:Int):Void {
        this.projectId = projectId;
        clearList();
        clearForm();
        if (projectId < 0) {
            addInfoLabel("No project selected");
            return;
        }
		showLoading();
		// invoke async call: listReleasesAsync(projectId, success, error)
		untyped asyncServices.release.listReleasesAsync(projectId, function(releases:Array<Release>) {
			clearList();
			if (releases == null || releases.length == 0) {
				addInfoLabel("No releases yet.");
			} else {
				for (r in releases) addReleaseRow(r);
			}
		}, function(err:Dynamic) {
			clearList();
			showError("Failed to load releases: " + Std.string(err));
		});
    }

    function clearList():Void {
        while (listContainer.numComponents > 0) listContainer.removeComponent(listContainer.getComponentAt(0));
		errorBanner = null;
    }

    function addInfoLabel(text:String):Void {
        var lbl = new Label();
        lbl.text = text;
        listContainer.addComponent(lbl);
    }

    function showLoading():Void {
        clearList();
    }

    function showError(message:String):Void {
        clearList();
        errorBanner = new ErrorBanner(message, function() loadReleases(projectId));
        listContainer.addComponent(errorBanner);
    }

    function addReleaseRow(r:Release):Void {
        var row = new HBox();
        row.addClass("releaseRow");
        var versionLbl = new Label(); versionLbl.text = r.version; versionLbl.percentWidth = 20;
        var notesLbl = new Label(); notesLbl.text = r.notes; notesLbl.percentWidth = 60;
        var createdLbl = new Label(); createdLbl.text = Std.string(r.createdAt); createdLbl.percentWidth = 20;
        var deployBtn = new Button(); deployBtn.text = "Deploy"; deployBtn.onClick = function(_) openDeploymentWizard(r);
        row.addComponent(versionLbl);
        row.addComponent(notesLbl);
        row.addComponent(createdLbl);
        row.addComponent(deployBtn);
        listContainer.addComponent(row);
    }

    // Helper to build and show a dialog wrapping a component
    function showDialogFor(content:Component, title:String, overlayClass:String, onClosed:Void->Void, ?fixedWidth:Int):Dialog {
        var dlg = new Dialog();
        dlg.title = title;
        dlg.closable = true;
        dlg.buttons = null; // internal component supplies its own buttons
        dlg.destroyOnClose = true;
        dlg.dialogParent = this.rootComponent; // ensure overlay sized to app root
        dlg.addClass(overlayClass); // append overlay styling instead of replacing base styles
        if (fixedWidth != null) {
            // Prevent percentWidth child from stretching dialog
            content.percentWidth = null;
            dlg.width = fixedWidth;
        }
        dlg.addComponent(content);
        dlg.onDialogClosed = function(_) {
            if (onClosed != null) onClosed();
        };
        trace('[Dialog] show title="' + title + '" overlayClass=' + overlayClass);
        dlg.showDialog(true);
        // Log final size after layout pass
        Toolkit.callLater(function() {
            trace('[Dialog] post-layout size title="' + title + '" w=' + dlg.width + ' h=' + dlg.height);
        });
        return dlg;
    }

    function toggleCreateForm():Void {
        if (createFormDialog == null) {
            createForm = new CreateReleaseForm(projectId);
            createForm.onCreated = function(r) {
                listContainer.addComponentAt(buildReleaseRow(r), 0);
                clearForm();
            };
            createForm.onCancelled = function() clearForm();
            createFormDialog = showDialogFor(createForm, "Create Release", "releaseFormOverlay", function() {
                createFormDialog = null;
                createForm = null;
            }, 420);
        } else {
            clearForm();
        }
    }

    function clearForm():Void {
        if (createFormDialog != null) {
            var dlg = createFormDialog;
            createFormDialog = null;
            trace('[Dialog] hide create release dialog');
            dlg.hideDialog("close"); // abstract maps string
        }
        createForm = null;
    }

    // Dialog now used instead of custom ModalManager

    function buildReleaseRow(r:Release):Component {
        var row = new HBox();
        row.addClass("releaseRow");
        var versionLbl = new Label(); versionLbl.text = r.version; versionLbl.percentWidth = 20;
        var notesLbl = new Label(); notesLbl.text = r.notes; notesLbl.percentWidth = 60;
        var createdLbl = new Label(); createdLbl.text = Std.string(r.createdAt); createdLbl.percentWidth = 20;
        var deployBtn = new Button(); deployBtn.text = "Deploy"; deployBtn.onClick = function(_) openDeploymentWizard(r);
        row.addComponent(versionLbl);
        row.addComponent(notesLbl);
        row.addComponent(createdLbl);
        row.addComponent(deployBtn);
        return row;
    }

    function openDeploymentWizard(r:Release):Void {
        var wizard = new DeploymentWizard(r);
        wizard.onClose = function() this.removeComponent(wizard);
        wizard.onLaunched = function(d) {
            trace('Deployment launched id=' + d.id + ' releaseId=' + d.releaseId + ' envId=' + d.environmentId);
            // Future: update deployments tab / history
            Notifications.show('Deployment #' + d.id + ' queued for ' + r.version + ' on env ' + d.environmentId, 'success');
        };
        // Insert wizard at top for now (could be modal later)
        addComponentAt(wizard, 0);
    }
}
