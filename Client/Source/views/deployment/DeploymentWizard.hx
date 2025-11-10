package views.deployment;

import haxe.ui.containers.VBox;
import haxe.ui.containers.HBox; // needed for env rows
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import components.ErrorBanner;
import sidewinderdeploy.shared.DeployModels; // Release, Environment, Deployment
import services.ServiceRegistry;
import services.AsyncServiceRegistry;

/** Simple multi-step deployment wizard scaffold. */
@:build(haxe.ui.ComponentBuilder.build("Assets/deployment-wizard.xml"))
class DeploymentWizard extends VBox {
    public var release:Release; // set via constructor or setter
    public var onClose:Void->Void;
    public var onLaunched:Deployment->Void;

    var services = ServiceRegistry.instance; // legacy sync (will remove later)
    var asyncServices = AsyncServiceRegistry.instance; // async clients

    var stepIndex:Int = 0;
    var steps:Array<String> = ["Environment", "Confirm"];

    var envSelectionContainer:VBox; // from XML id envSelectionContainer
    var confirmContainer:VBox; // from XML id confirmContainer
    var selectedEnv:Environment;

    var headerLabel:Label; // from XML id headerLabel
    var errorLabel:Label; // from XML id errorLabel
    var backBtn:Button; // from XML id backBtn
    var nextBtn:Button; // from XML id nextBtn
    var cancelBtn:Button; // from XML id cancelBtn

    public function new(release:Release) {
        super();
        this.release = release;
        // Wire buttons from XML
        if (backBtn != null) backBtn.onClick = function(_) previousStep();
        if (nextBtn != null) nextBtn.onClick = function(_) nextStep();
        if (cancelBtn != null) cancelBtn.onClick = function(_) close();
        showStep(0);
        loadEnvironmentsAsync();
    }

    function loadEnvironmentsAsync():Void {
        envSelectionContainer.removeAllComponents();
        // disable Next until a selection is made
        updateNextButtonState();
        untyped asyncServices.environment.listEnvironmentsAsync(function(envs:Array<Environment>) {
            envSelectionContainer.removeAllComponents();
            if (envs == null || envs.length == 0) {
                envSelectionContainer.addComponent(new Label());
                var empty = new Label(); empty.text = "No environments defined"; envSelectionContainer.addComponent(empty);
                updateNextButtonState();
                return;
            }
            var container = new VBox();
            for (e in envs) {
                var row = new HBox();
                row.addClass("envRow");
                var nameLbl = new Label(); nameLbl.text = e.name; row.addComponent(nameLbl);
                var selectBtn = new Button();
                selectBtn.text = (selectedEnv != null && selectedEnv.id == e.id) ? "Selected" : "Select";
                selectBtn.onClick = function(_) {
                    selectedEnv = e;
                    refreshEnvRows(container, envs);
                    updateNextButtonState();
                };
                row.addComponent(selectBtn);
                container.addComponent(row);
            }
            envSelectionContainer.addComponent(container);
            updateNextButtonState();
        }, function(err:Dynamic) {
            envSelectionContainer.removeAllComponents();
            var banner = new ErrorBanner("Failed to load environments: " + err, function() loadEnvironmentsAsync());
            envSelectionContainer.addComponent(banner);
            updateNextButtonState();
        });
    }

    function refreshEnvRows(container:VBox, envs:Array<Environment>):Void {
        for (i in 0...container.numComponents) {
            var row = container.getComponentAt(i);
            if (Std.isOfType(row, HBox)) {
                var hb:HBox = cast row;
                var btn:Button = cast hb.getComponentAt(hb.numComponents - 1);
                var env = envs[i];
                btn.text = (selectedEnv != null && selectedEnv.id == env.id) ? "Selected" : "Select";
            }
        }
    }

    function updateNextButtonState():Void {
        if (nextBtn == null) return;
        if (stepIndex == 0) {
            nextBtn.disabled = (selectedEnv == null);
        } else if (stepIndex == 1) {
            // On confirm step, next triggers launch (kept for consistency); always enabled
            nextBtn.disabled = false;
        }
    }

    function showStep(idx:Int):Void {
        stepIndex = idx;
        headerLabel.text = 'Deploy Release ' + release.version + ' - Step ' + (idx + 1) + ' of ' + steps.length + ': ' + steps[idx];
        envSelectionContainer.visible = (idx == 0);
        confirmContainer.visible = (idx == 1);
        if (idx == 1) buildConfirm();
        updateNextButtonState();
    }

    function nextStep():Void {
        if (stepIndex == 0) {
            if (selectedEnv == null) {
                error("Select an environment first");
                return;
            }
            clearError();
            showStep(1);
            updateNextButtonState();
        } else if (stepIndex == 1) {
            launchDeployment();
        }
    }

    function previousStep():Void {
        if (stepIndex > 0) {
            clearError();
            showStep(stepIndex - 1);
        }
    }

    function buildConfirm():Void {
        confirmContainer.removeAllComponents();
        var summary = new VBox(); summary.addClass("confirmSummary");
        summary.addComponent(makeSummaryLabel('Project ID: ' + release.projectId));
        summary.addComponent(makeSummaryLabel('Release Version: ' + release.version));
        summary.addComponent(makeSummaryLabel('Environment: ' + (selectedEnv != null ? selectedEnv.name : 'NONE')));
        confirmContainer.addComponent(summary);
        var launchBtn = new Button(); launchBtn.text = "Launch Deployment"; launchBtn.onClick = function(_) launchDeployment();
        confirmContainer.addComponent(launchBtn);
    }

    function makeSummaryLabel(text:String):Label {
        var l = new Label(); l.text = text; return l;
    }

    function launchDeployment():Void {
        if (nextBtn != null) nextBtn.disabled = true;
        var deployment:Deployment = {
            id: 0,
            releaseId: release.id,
            environmentId: selectedEnv.id,
            status: DeploymentStatus.Queued,
            // startedAt expects a Date (DeployModels.Deployment)
            startedAt: Date.now(),
            finishedAt: null
        };
        untyped asyncServices.deployment.createDeploymentAsync(release.id, deployment, function(created:Deployment) {
            if (nextBtn != null) nextBtn.disabled = false;
            if (onLaunched != null) onLaunched(created);
            close();
        }, function(err:Dynamic) {
            if (nextBtn != null) nextBtn.disabled = false;
            error('Failed to create deployment: ' + err);
        });
    }

    function error(msg:String):Void {
        errorLabel.text = msg;
        errorLabel.visible = true;
    }

    function clearError():Void {
        errorLabel.visible = false;
    }

    function close():Void {
        if (onClose != null) onClose();
    }
}
