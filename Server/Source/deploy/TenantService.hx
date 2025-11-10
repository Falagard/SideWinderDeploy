package deploy;

import sidewinderdeploy.shared.DeployModels;
import sidewinderdeploy.shared.ITenantVariableValueService;
import sidewinderdeploy.shared.ITenantService;
import sidewinder.DI;
import Date;
import sidewinder.Database;

class TenantService implements ITenantService {
	public function new() {}

	public function listTenants():Array<Tenant> {
		var out:Array<Tenant> = [];
		try {
			var conn = Database.acquire();
			var rs = conn.request("SELECT id, name, description, created_at FROM tenants ORDER BY id ASC");
			var rec = rs.next();
			while (rec != null) {
				out.push({
					id: Std.int(Reflect.field(rec, "id")),
					name: Std.string(Reflect.field(rec, "name")),
					description: Std.string(Reflect.field(rec, "description")),
					createdAt: Date.fromTime(Reflect.field(rec, "created_at"))
				});
				rec = rs.next();
			}
			Database.release(conn);
		} catch (e:Dynamic) {}
		return out;
	}

	public function createTenant(tenant:Tenant):Tenant {
		var now = Date.now();
		var t:Tenant = { id:0, name:tenant.name, description:tenant.description, createdAt:now };
		var params = new Map<String, Dynamic>();
		params.set("name", t.name);
		params.set("description", t.description);
		params.set("created_at", t.createdAt.getTime());
		var conn = Database.acquire();
		var sql = "INSERT INTO tenants (name, description, created_at) VALUES (@name, @description, @created_at)";
		try {
			conn.request(Database.buildSql(sql, params));
			var rs = conn.request("SELECT last_insert_rowid() AS id");
			var rec = rs.next();
			if (rec != null && Reflect.hasField(rec, "id")) t.id = Std.int(Reflect.field(rec, "id"));
		} catch (e:Dynamic) {}
		Database.release(conn);
		return t;
	}

	public function getTenant(id:Int):Null<Tenant> {
		try {
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			var conn = Database.acquire();
			var sql = "SELECT id, name, description, created_at FROM tenants WHERE id=@id";
			var rs = conn.request(Database.buildSql(sql, params));
			var rec = rs.next();
			Database.release(conn);
			if (rec == null) return null;
			return {
				id: Std.int(Reflect.field(rec, "id")),
				name: Std.string(Reflect.field(rec, "name")),
				description: Std.string(Reflect.field(rec, "description")),
				createdAt: Date.fromTime(Reflect.field(rec, "created_at"))
			};
		} catch (e:Dynamic) {
			return null;
		}
	}

	public function updateTenant(id:Int, tenant:Tenant):Null<Tenant> {
		try {
			var existing = getTenant(id);
			if (existing == null) return null;
			if (tenant.name != null) existing.name = tenant.name;
			if (tenant.description != null) existing.description = tenant.description;
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			params.set("name", existing.name);
			params.set("description", existing.description);
			var sql = "UPDATE tenants SET name=@name, description=@description WHERE id=@id";
			var conn = Database.acquire();
			conn.request(Database.buildSql(sql, params));
			Database.release(conn);
			return existing;
		} catch (e:Dynamic) {
			return null;
		}
	}

	public function deleteTenant(id:Int):Bool {
		var existed = false;
		try existed = (getTenant(id) != null) catch (e:Dynamic) existed = false;
		if (!existed) return false;
		try {
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			var sql = "DELETE FROM tenants WHERE id=@id";
			var conn = Database.acquire();
			conn.request(Database.buildSql(sql, params));
			Database.release(conn);
		} catch (e:Dynamic) {
			return false;
		}
		// Cascade: remove overrides
		try {
			var tvv:ITenantVariableValueService = DI.get(ITenantVariableValueService);
			if (tvv != null) tvv.deleteOverridesForTenant(id);
		} catch (e:Dynamic) {}
		return true;
	}

	function generateId(prefix:String):String {
		return prefix + "-" + Std.string(Math.floor(Math.random() * 1_000_000)); // retained for potential future non-DB id needs
	}
}
