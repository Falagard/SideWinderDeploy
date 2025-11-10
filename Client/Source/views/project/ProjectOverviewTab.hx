package views.project;

import haxe.ui.containers.VBox;
import haxe.ui.components.Label;
import haxe.ui.core.Component;
import components.ErrorBanner;
import services.AsyncServiceRegistry;
import sidewinderdeploy.shared.DeployModels.Project;
import state.AppState;
using StringTools;

@:build(haxe.ui.ComponentBuilder.build("Assets/project-overview-tab.xml"))
class ProjectOverviewTab extends VBox {
	public var currentProjectId:Int = -1;

	var asyncServices = AsyncServiceRegistry.instance;

	var overviewContent:VBox; // from XML
	var projectName:Label; // from XML
	var projectId:Label; // from XML - label for displaying ID
	var projectDescription:Label; // from XML
	var projectCreatedAt:Label; // from XML

	var errorBanner:ErrorBanner;

	public function new() {
		super();
		
		// Watch global selected project and load project details when it changes
		AppState.instance.selectedProjectId.watch(function(pid:Int) {
			if (pid != this.currentProjectId) {
				loadProject(pid);
			}
		});
	}

	public function loadProject(pid:Int):Void {
		this.currentProjectId = pid;
		if (pid < 0) {
			clearDisplay();
			return;
		}
		
		// Just clear and load - no loading indicator
		clearDisplay();
		untyped asyncServices.project.getProjectAsync(pid, function(project:Project) {
			if (project != null) {
				displayProject(project);
			} else {
				showError('Project not found');
			}
		}, function(err:Dynamic) {
			showError('Failed to load project: ' + Std.string(err));
		});
	}

	function displayProject(project:Project):Void {
		if (projectName != null) projectName.text = project.name;
		if (projectId != null) projectId.text = Std.string(project.id);
		if (projectDescription != null) {
			projectDescription.text = project.description.length > 0 ? project.description : "(No description)";
		}
		if (projectCreatedAt != null) {
			projectCreatedAt.text = formatDate(project.createdAt);
		}
		
		if (overviewContent != null) overviewContent.visible = true;
	}

	function clearDisplay():Void {
		if (projectName != null) projectName.text = "-";
		if (projectId != null) projectId.text = "-";
		if (projectDescription != null) projectDescription.text = "-";
		if (projectCreatedAt != null) projectCreatedAt.text = "-";
		if (overviewContent != null) overviewContent.visible = false;
	}

	function formatDate(date:Date):String {
		if (date == null) return "-";
		return DateTools.format(date, "%Y-%m-%d %H:%M:%S");
	}

	function showError(message:String):Void {
		if (overviewContent != null) overviewContent.visible = false;
		hideError();
		errorBanner = new ErrorBanner(message, function() loadProject(this.currentProjectId));
		
		// Always defer to ensure both parent and child are ready
		haxe.ui.Toolkit.callLater(function() {
			if (errorBanner != null && errorBanner.parentComponent == null) {
				addComponent(errorBanner);
			}
		});
	}

	function hideError():Void {
		if (errorBanner != null && errorBanner.parentComponent != null) {
			removeComponent(errorBanner);
		}
		errorBanner = null;
	}
}
