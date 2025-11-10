package;

import haxe.ui.containers.VBox;
import haxe.ui.containers.TabView;
import haxe.ui.containers.TreeView;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.core.Component;
import components.ErrorBanner;
import haxe.ui.events.MouseEvent;
import services.ServiceRegistry;
import services.AsyncServiceRegistry; // global async services
import state.AppState;
import sidewinderdeploy.shared.DeployModels; // brings in Project typedef
import components.Notifications;
import views.project.ReleasesTab;
import views.project.ProjectVariablesTab;
import views.project.ProjectOverviewTab;

@:build(haxe.ui.ComponentBuilder.build("Assets/main-view.xml"))
class MainView extends VBox {
	// IDs from XML will map automatically: projectTree, contentTabs, refreshBtn
	var primaryNavList:TreeView; // from XML primaryNavList
	var itemList:TreeView; // from XML itemList
	var contentTabs:TabView; // from XML
	var detailsPlaceholder:VBox; // from XML - placeholder for machines/environments
	var detailsPlaceholderText:Label; // from XML
	var refreshBtn:Button; // from XML
	var createItemBtn:Button; // from XML
	var itemStatusLabel:Label; // from XML
	var userLabel:Label; // from XML - displays current user
	var logoutBtn:Button; // from XML - logout button
	var releasesTab:ReleasesTab; // added programmatically and uses its own XML
	var projectVariablesTab:ProjectVariablesTab; // variables tab implementation
	var projectOverviewTab:ProjectOverviewTab; // overview tab implementation

	// Error components for item list
	var errorBanner:ErrorBanner; // generic for item list

	var appState = AppState.instance;
	var services = ServiceRegistry.instance;
	var asyncServices = AppState.instance.asyncServices; // centralized async registry

	public function new() {
		super();
		// async services already initialized in AppState
		wireEvents();
		attachReleasesTab();
		initPrimaryNav();
		// Ensure we have a non-null category before initial population
		var initialCat = appState.selectedPrimaryCategory.value;
		if (initialCat == null || initialCat == "") initialCat = "Projects";
		updateContentTabsVisibility(initialCat);
		populateItemsFor(initialCat);
		
		// Watch authentication state and update user display
		appState.currentUser.watch(function(user) {
			updateUserDisplay();
		});
		updateUserDisplay();
	}

	private function updateUserDisplay():Void {
		if (userLabel != null) {
			var user = appState.currentUser.value;
			if (user != null) {
				var displayName = user.username != null ? user.username : user.email;
				userLabel.text = displayName;
			} else {
				userLabel.text = "";
			}
		}
	}

	private function wireEvents():Void {
		if (logoutBtn != null) logoutBtn.onClick = function(_) {
			handleLogout();
		};
		if (refreshBtn != null) refreshBtn.onClick = function(_) {
			populateItemsFor(appState.selectedPrimaryCategory.value, true);
		};
		if (createItemBtn != null) createItemBtn.onClick = function(_) {
			var cat = appState.selectedPrimaryCategory.value;
			if (cat == null || cat == "") cat = "Projects";
			if (cat == "Projects") {
				var dlg = new views.project.CreateProjectDialog();
				// parent for sizing overlay
				dlg.dialogParent = this.rootComponent;
				// on created refresh list
				dlg.onCreated = function(p) {
					populateItemsFor("Projects");
				};
				dlg.showDialog(true);
			} else if (cat == "Environments") {
				var dlg = new views.environment.CreateEnvironmentDialog();
				// parent for sizing overlay
				dlg.dialogParent = this.rootComponent;
				// on created refresh list
				dlg.onCreated = function(e) {
					populateItemsFor("Environments");
				};
				dlg.showDialog(true);
			} else if (cat == "Machines") {
				var dlg = new views.machine.CreateMachineDialog();
				// parent for sizing overlay
				dlg.dialogParent = this.rootComponent;
				// on created refresh list
				dlg.onCreated = function(m) {
					populateItemsFor("Machines");
				};
				dlg.showDialog(true);
			} else if (cat == "Tenants") {
				var dlg = new views.tenant.CreateTenantDialog();
				// parent for sizing overlay
				dlg.dialogParent = this.rootComponent;
				// on created refresh list
				dlg.onCreated = function(t) {
					populateItemsFor("Tenants");
				};
				dlg.showDialog(true);
			} else {
				trace('[UI] Create for category not implemented: ' + cat);
			}
		};
		appState.selectedPrimaryCategory.watch(function(cat) {
			if (cat == null || cat == "") cat = "Projects";
			populateItemsFor(cat);
			updateContentTabsVisibility(cat);
		});
		if (itemList != null) itemList.onChange = function(_) {
			var sel = itemList.selectedNode;
			if (sel == null) return;
			switch (appState.selectedPrimaryCategory.value) {
				case "Projects":
					var pid = Std.parseInt(Std.string(sel.userData));
					appState.selectedProjectId.value = pid;
					if (projectOverviewTab != null) projectOverviewTab.loadProject(pid);
					releasesTab.loadReleases(pid);
					if (projectVariablesTab != null) projectVariablesTab.loadVariables(pid);
				case "Environments":
					appState.selectedEnvironmentId.value = Std.parseInt(Std.string(sel.userData));
				case "Machines":
					appState.selectedMachineId.value = Std.parseInt(Std.string(sel.userData));
				case "Tenants":
					appState.selectedTenantId.value = Std.parseInt(Std.string(sel.userData));
			}
		};
	}

	private function initPrimaryNav():Void {
		if (primaryNavList == null) return;
		// Rebuild primary nav using nodes
		primaryNavList.removeAllComponents();
		var projectsNode = primaryNavList.addNode("Projects");
		primaryNavList.addNode("Environments");
		primaryNavList.addNode("Machines");
		primaryNavList.addNode("Tenants");
		primaryNavList.onChange = function(_) {
			var sel = primaryNavList.selectedNode;
			if (sel != null) appState.selectedPrimaryCategory.value = sel.data;
		};
		// Pre-select Projects
		primaryNavList.selectedNode = projectsNode;
	}

	private function attachReleasesTab():Void {
		releasesTab = new ReleasesTab();
		if (contentTabs != null) {
			contentTabs.addComponent(releasesTab);
			// Replace placeholder overview tab with real component
			var overviewPlaceholder = contentTabs.findComponent("overviewTab", VBox, true);
			if (overviewPlaceholder != null) {
				projectOverviewTab = new ProjectOverviewTab();
				projectOverviewTab.text = "Overview";
				var idx = contentTabs.getComponentIndex(overviewPlaceholder);
				contentTabs.removeComponent(overviewPlaceholder);
				contentTabs.addComponentAt(projectOverviewTab, idx);
			}
			// Replace placeholder variables tab with real component
			var placeholder = contentTabs.findComponent("variablesTab", VBox, true);
			if (placeholder != null) {
				projectVariablesTab = new ProjectVariablesTab();
				projectVariablesTab.text = "Variables";
				var idx = contentTabs.getComponentIndex(placeholder);
				contentTabs.removeComponent(placeholder);
				contentTabs.addComponentAt(projectVariablesTab, idx);
			}
		}
	}

	private function updateContentTabsVisibility(cat:String):Void {
		if (contentTabs == null) return;
		
		// Show tabs only for Projects, show placeholder for Machines, Environments, and Tenants
		switch (cat) {
			case "Projects":
				contentTabs.visible = true;
				if (detailsPlaceholder != null) detailsPlaceholder.visible = false;
			case "Environments":
				contentTabs.visible = false;
				if (detailsPlaceholder != null) {
					detailsPlaceholder.visible = true;
					if (detailsPlaceholderText != null) {
						detailsPlaceholderText.text = "Select an environment to view details";
					}
				}
			case "Machines":
				contentTabs.visible = false;
				if (detailsPlaceholder != null) {
					detailsPlaceholder.visible = true;
					if (detailsPlaceholderText != null) {
						detailsPlaceholderText.text = "Select a machine to view details";
					}
				}
			case "Tenants":
				contentTabs.visible = false;
				if (detailsPlaceholder != null) {
					detailsPlaceholder.visible = true;
					if (detailsPlaceholderText != null) {
						detailsPlaceholderText.text = "Select a tenant to view details";
					}
				}
			default:
				contentTabs.visible = false;
				if (detailsPlaceholder != null) detailsPlaceholder.visible = false;
		}
	}

	private function setStatus(text:String, isError:Bool = false):Void {
		if (itemStatusLabel != null) {
			itemStatusLabel.text = text;
			itemStatusLabel.addClass(isError ? "statusError" : "statusInfo");
		}
	}

	private function clearStatus():Void {
		if (itemStatusLabel != null) {
			itemStatusLabel.text = "";
			itemStatusLabel.removeClass("statusError");
			itemStatusLabel.removeClass("statusInfo");
		}
	}

	private function showLoading(cat:String):Void {
		// No loading indicator - just clear status
		if (cat == null || cat == "") cat = "Projects";
		clearStatus();
	}

	private function showError(cat:String, message:String):Void {
		clearStatus();
		errorBanner = new ErrorBanner(message, function() populateItemsFor(cat));
		if (secondaryPaneExists()) addComponentToItemListArea(errorBanner);
	}

	private function secondaryPaneExists():Bool {
		return itemList != null;
	}

	private function addComponentToItemListArea(c:Component):Void {
		// place status components adjacent to the itemList (same parent) once hierarchy exists
		if (itemList != null && c.parentComponent == null) {
			var parent = itemList.parentComponent; // secondaryPane container holding itemList
			if (parent != null) {
				parent.addComponentAt(c, parent.getComponentIndex(itemList));
			} else {
				// Hierarchy not ready yet (likely early call during construction) - fall back to attaching to MainView
				// This avoids a Null access when parentComponent isn't assigned yet.
				addComponent(c);
			}
		}
	}

	private function clearItemStatusComponents():Void {
		if (errorBanner != null && errorBanner.parentComponent != null) errorBanner.parentComponent.removeComponent(errorBanner);
		errorBanner = null;
	}

	private function populateItemsFor(cat:String, ?userInitiated:Bool = false):Void {
		if (cat == null || cat == "") cat = "Projects";
		clearItemStatusComponents();
		if (itemList == null) return;
		itemList.removeAllComponents();
		showLoading(cat);
		switch (cat) {
			case "Projects":
				untyped asyncServices.project.listProjectsAsync(function(projects:Array<Project>) {
					clearItemStatusComponents();
					for (p in projects) {
						var n = itemList.addNode(p.name);
						n.userData = p.id;
					}
					if (projects.length > 0 && appState.selectedProjectId.value == -1) {
						appState.selectedProjectId.value = projects[0].id;
						if (projectOverviewTab != null) projectOverviewTab.loadProject(projects[0].id);
						releasesTab.loadReleases(projects[0].id);
						if (projectVariablesTab != null) projectVariablesTab.loadVariables(projects[0].id);
						itemList.selectedNode = cast itemList.getComponentAt(0);
					}
					if (userInitiated) Notifications.show('Projects refreshed', 'info');
				}, function(err:Dynamic) {
					clearItemStatusComponents();
					showError(cat, 'Failed to load projects: ' + Std.string(err));
				});
			case "Environments":
				untyped asyncServices.environment.listEnvironmentsAsync(function(envs:Array<Dynamic>) {
					clearItemStatusComponents();
					for (e in envs) {
						var n = itemList.addNode(e.name);
						n.userData = e.id;
					}
					if (userInitiated) Notifications.show('Environments refreshed', 'info');
				}, function(err:Dynamic) {
					clearItemStatusComponents();
					showError(cat, 'Failed to load environments: ' + Std.string(err));
				});
			case "Machines":
				// switched from deployment.listMachinesAsync to machine.listMachinesAsync (dedicated service)
				untyped asyncServices.machine.listMachinesAsync(function(machs:Array<Dynamic>) {
					clearItemStatusComponents();
					for (m in machs) {
						var n = itemList.addNode(m.name);
						n.userData = m.id;
					}
					if (userInitiated) Notifications.show('Machines refreshed', 'info');
				}, function(err:Dynamic) {
					clearItemStatusComponents();
					showError(cat, 'Failed to load machines: ' + Std.string(err));
				});
			case "Tenants":
				untyped asyncServices.tenant.listTenantsAsync(function(tenants:Array<Dynamic>) {
					clearItemStatusComponents();
					for (t in tenants) {
						var n = itemList.addNode(t.name);
						n.userData = t.id;
					}
					if (userInitiated) Notifications.show('Tenants refreshed', 'info');
				}, function(err:Dynamic) {
					clearItemStatusComponents();
					showError(cat, 'Failed to load tenants: ' + Std.string(err));
				});
			default:
				clearItemStatusComponents();
								setStatus('Unknown category: ' + cat, true);
		}
	}

	private function handleLogout():Void {
		untyped asyncServices.auth.logoutAsync(function(success:Bool) {
			appState.clearAuthentication();
			Notifications.show('Signed out successfully', 'info');
			// Trigger re-authentication via AuthManager
			// The auth check will happen on next app reload or we can trigger it here
			#if js
			js.Browser.window.location.reload();
			#end
		}, function(err:Dynamic) {
			// Still clear local auth even if server call fails
			appState.clearAuthentication();
			Notifications.show('Signed out', 'info');
			#if js
			js.Browser.window.location.reload();
			#end
		});
	}
}