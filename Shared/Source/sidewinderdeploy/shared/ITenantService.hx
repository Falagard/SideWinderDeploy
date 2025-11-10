package sidewinderdeploy.shared;

import sidewinderdeploy.shared.DeployModels;
import hx.injection.Service;

interface ITenantService extends Service {
	@get("/api/tenants")
	public function listTenants():Array<Tenant>;
	@post("/api/tenants")
	public function createTenant(tenant:Tenant):Tenant;
	@get("/api/tenants/:id")
	public function getTenant(id:Int):Null<Tenant>;
	@post("/api/tenants/:id") // Using POST for update (could switch to PUT if framework supports)
	public function updateTenant(id:Int, tenant:Tenant):Null<Tenant>;
	@delete("/api/tenants/:id")
	public function deleteTenant(id:Int):Bool;
}
