package views.project;

import haxe.ui.containers.VBox;
import haxe.ui.containers.HBox;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.components.TextField;
import haxe.ui.core.Component;
import components.ErrorBanner;
import components.Notifications;
import haxe.ui.containers.dialogs.Dialog;
import services.AsyncServiceRegistry;
import sidewinderdeploy.shared.DeployModels.ProjectVariable;
import state.AppState; // observe selectedProjectId

@:build(haxe.ui.ComponentBuilder.build("Assets/project-variables-tab.xml"))
class ProjectVariablesTab extends VBox {
	public var projectId:Int = -1;

	var asyncServices = AsyncServiceRegistry.instance;

	var varActions:HBox; // from XML id
	var addVarBtn:Button; // from XML id
	var refreshVarBtn:Button; // from XML id
	var varList:VBox; // from XML id
	var varFormContainer:VBox; // container for add/edit form

	var errorBanner:ErrorBanner;

	var editingVariable:ProjectVariable; // track variable being edited

	public function new() {
		super();
		if (addVarBtn != null)
			addVarBtn.onClick = function(_) showCreateForm();
		if (refreshVarBtn != null)
			refreshVarBtn.onClick = function(_) reload(true);
		// Watch global selected project and reload variables when it changes
		AppState.instance.selectedProjectId.watch(function(pid:Int) {
			if (pid != projectId) {
				loadVariables(pid);
			} else if (pid >= 0 && varList.numComponents == 0) {
				// Edge case: project unchanged but list cleared (e.g. component recreated)
				reload();
			}
		});
	}

	public function loadVariables(projectId:Int):Void {
		this.projectId = projectId;
		if (projectId < 0) {
			clearList();
			addInfo("No project selected");
			return;
		}
		reload();
	}

	function reload(?userInitiated:Bool = false):Void {
		clearList();
		untyped asyncServices.projectVariable.listProjectVariablesAsync(projectId, function(vars:Array<ProjectVariable>) {
			clearList();
			if (vars == null || vars.length == 0) {
				addInfo("No variables defined");
			} else {
				for (v in vars)
					addVariableRow(v);
			}
			if (userInitiated) Notifications.show('Variables refreshed', 'info');
		}, function(err:Dynamic) {
			clearList();
			showError("Failed to load variables: " + Std.string(err));
		});
	}

	function showError(msg:String):Void {
		errorBanner = new ErrorBanner(msg, function() reload());
		varList.addComponent(errorBanner);
	}

	function clearList():Void {
		while (varList.numComponents > 0)
			varList.removeComponent(varList.getComponentAt(0));
		errorBanner = null;
	}

	function addInfo(text:String):Void {
		var l = new Label();
		l.text = text;
		varList.addComponent(l);
	}

	function addVariableRow(v:ProjectVariable):Void {
		var row = new HBox();
		row.addClass("variableRow");
		row.percentWidth = 100;
		// Name label - allow wider names, fixed min width
		var nameLbl = new Label();
		nameLbl.text = v.name;
		nameLbl.width = 140;
		// Value label - flex grow to consume remaining space before buttons
		var valueLbl = new Label();
		valueLbl.text = v.defaultValue;
		valueLbl.percentWidth = 100;
		// Container for right-aligned buttons
		var actions = new HBox();
		actions.horizontalAlign = "right";
		actions.addClass("variableActions");
		var editBtn = new Button();
		editBtn.text = "Edit";
		editBtn.onClick = function(_) showEditForm(v);
		var deleteBtn = new Button();
		deleteBtn.text = "Delete";
		deleteBtn.onClick = function(_) deleteVariable(v);
		actions.addComponent(editBtn);
		actions.addComponent(deleteBtn);
		row.addComponent(nameLbl);
		row.addComponent(valueLbl);
		row.addComponent(actions);
		varList.addComponent(row);
	}

	function showCreateForm():Void {
		editingVariable = null;
		openVariableDialog(null);
	}

	function showEditForm(v:ProjectVariable):Void {
		editingVariable = v;
		openVariableDialog(v);
	}

	var formDialog:views.project.ProjectVariableFormDialog; // active dialog

	function openVariableDialog(v:ProjectVariable):Void {
		if (formDialog != null) {
			formDialog.hideDialog("cancel");
			formDialog = null;
		}
		formDialog = new views.project.ProjectVariableFormDialog(projectId, v);
		formDialog.dialogParent = this.rootComponent;
		formDialog.onSaved = function(saved) {
			formDialog = null;
			reload();
		};
		formDialog.onCancelled = function() {
			formDialog = null;
			editingVariable = null;
		};
		formDialog.showDialog(true);
	}

	function cancelForm():Void {
		if (formDialog != null) {
			var dlg = formDialog;
			formDialog = null;
			trace('[Dialog] hide variable form dialog');
			dlg.hideDialog("cancel");
		}
		editingVariable = null;
	}

	function createVariable(name:String, value:String):Void {
		var variable:ProjectVariable = {
			id: 0,
			projectId: projectId,
			name: name,
			defaultValue: value,
			// createdAt expects a Date (DeployModels.ProjectVariable)
			createdAt: Date.now()
		};
		untyped asyncServices.projectVariable.createProjectVariableAsync(projectId, variable, function(created:ProjectVariable) {
			Notifications.show('Variable "' + created.name + '" created', 'success');
			cancelForm();
			reload();
		}, function(err:Dynamic) {
			Notifications.show('Create failed: ' + Std.string(err), 'error');
		});
	}

	function updateVariable(orig:ProjectVariable, name:String, value:String):Void {
		var updated:ProjectVariable = {
			id: orig.id,
			projectId: orig.projectId,
			name: name,
			defaultValue: value,
			createdAt: orig.createdAt
		};
		untyped asyncServices.projectVariable.updateProjectVariableAsync(orig.id, updated, function(ret:ProjectVariable) {
			Notifications.show('Variable updated', 'success');
			cancelForm();
			reload();
		}, function(err:Dynamic) {
			Notifications.show('Update failed: ' + Std.string(err), 'error');
		});
	}

	function deleteVariable(v:ProjectVariable):Void {
		untyped asyncServices.projectVariable.deleteProjectVariableAsync(v.id, function(ok:Bool) {
			Notifications.show('Variable deleted', 'success');
			reload();
		}, function(err:Dynamic) {
			Notifications.show('Delete failed: ' + Std.string(err), 'error');
		});
	}
}
