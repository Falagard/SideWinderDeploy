package sidewinderdeploy.shared;

import sidewinderdeploy.shared.DeployModels;
import hx.injection.Service;

interface ITenantVariableValueService extends Service {
	// Upsert (create or update) a tenant-specific variable value
	@post("/api/projects/:projectId/variables/:variableId/tenants/:tenantId/value")
	public function setTenantVariableValue(projectId:Int, variableId:Int, tenantId:Int, value:TenantProjectVariableValue):TenantProjectVariableValue; // include path params

	// Get the resolved override value (or null if none exists)
	@get("/api/projects/:projectId/variables/:variableId/tenants/:tenantId/value")
	public function getTenantVariableValue(projectId:Int, variableId:Int, tenantId:Int):String;

	// List all variable overrides for a given project + tenant
	@get("/api/projects/:projectId/tenants/:tenantId/variables")
	public function listTenantVariableValues(projectId:Int, tenantId:Int):Array<TenantProjectVariableValue>;

	// Delete all overrides tied to a project (cascade on project delete)
	@delete("/api/projects/:projectId/tenant-variable-values")
	public function deleteOverridesForProject(projectId:Int):Void;

	// Delete overrides for a specific project variable across all tenants
	@delete("/api/project-variables/:variableId/tenant-variable-values")
	public function deleteOverridesForVariable(variableId:Int):Void;

	// Delete all overrides for a specific tenant (cascade on tenant delete)
	@delete("/api/tenants/:tenantId/tenant-variable-values")
	public function deleteOverridesForTenant(tenantId:Int):Void;
}
