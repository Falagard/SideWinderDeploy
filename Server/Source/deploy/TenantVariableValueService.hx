package deploy;

import sidewinderdeploy.shared.DeployModels;
import sidewinderdeploy.shared.ITenantVariableValueService;
import Date;
import sidewinder.Database;

class TenantVariableValueService implements ITenantVariableValueService {
	public function new() {}

	// Insert or update a tenant variable override in the database.
	public function setTenantVariableValue(valueObj:TenantProjectVariableValue):TenantProjectVariableValue {
		var projectId = valueObj.projectId;
		var variableId = valueObj.variableId;
		var tenantId = valueObj.tenantId;
		var result:TenantProjectVariableValue = null;
		try {
			var params = new Map<String, Dynamic>();
			params.set("project_id", projectId);
			params.set("variable_id", variableId);
			params.set("tenant_id", tenantId);
			var conn = Database.acquire();
			// Try to find existing override.
			var selectSql = "SELECT id, project_id, variable_id, tenant_id, value, created_at FROM tenant_variable_values WHERE project_id=@project_id AND variable_id=@variable_id AND tenant_id=@tenant_id";
			var rs = conn.request(Database.buildSql(selectSql, params));
			var rec = rs.next();
			if (rec != null) {
				// Update existing value.
				var updateParams = new Map<String, Dynamic>();
				updateParams.set("id", Reflect.field(rec, "id"));
				updateParams.set("value", valueObj.value);
				var updateSql = "UPDATE tenant_variable_values SET value=@value WHERE id=@id";
				conn.request(Database.buildSql(updateSql, updateParams));
				result = {
					id: Std.int(Reflect.field(rec, "id")),
					projectId: projectId,
					variableId: variableId,
					tenantId: tenantId,
					value: valueObj.value,
					createdAt: Date.fromTime(Reflect.field(rec, "created_at"))
				};
			} else {
				// Insert new override.
				var now = Date.now();
				params.set("value", valueObj.value);
				params.set("created_at", now.getTime());
				var insertSql = "INSERT INTO tenant_variable_values (project_id, variable_id, tenant_id, value, created_at) VALUES (@project_id, @variable_id, @tenant_id, @value, @created_at)";
				conn.request(Database.buildSql(insertSql, params));
				var idRs = conn.request("SELECT last_insert_rowid() AS id");
				var idRec = idRs.next();
				var newId:Int = (idRec != null && Reflect.hasField(idRec, "id")) ? Std.int(Reflect.field(idRec, "id")) : 0;
				result = {
					id: newId,
					projectId: projectId,
					variableId: variableId,
					tenantId: tenantId,
					value: valueObj.value,
					createdAt: now
				};
			}
			Database.release(conn);
		} catch (e:Dynamic) {
			if (result == null) {
				// Fallback object (unsaved) on failure.
				result = {
					id: 0,
					projectId: projectId,
					variableId: variableId,
					tenantId: tenantId,
					value: valueObj.value,
					createdAt: Date.now()
				};
			}
		}
		return result;
	}

	public function getTenantVariableValue(projectId:Int, variableId:Int, tenantId:Int):String {
		try {
			var params = new Map<String, Dynamic>();
			params.set("project_id", projectId);
			params.set("variable_id", variableId);
			params.set("tenant_id", tenantId);
			var conn = Database.acquire();
			var sql = "SELECT value FROM tenant_variable_values WHERE project_id=@project_id AND variable_id=@variable_id AND tenant_id=@tenant_id";
			var rs = conn.request(Database.buildSql(sql, params));
			var rec = rs.next();
			Database.release(conn);
			if (rec == null) return null;
			return Std.string(Reflect.field(rec, "value"));
		} catch (e:Dynamic) {
			return null;
		}
	}

	public function listTenantVariableValues(projectId:Int, tenantId:Int):Array<TenantProjectVariableValue> {
		var out = new Array<TenantProjectVariableValue>();
		try {
			var params = new Map<String, Dynamic>();
			params.set("project_id", projectId);
			params.set("tenant_id", tenantId);
			var conn = Database.acquire();
			var sql = "SELECT id, project_id, variable_id, tenant_id, value, created_at FROM tenant_variable_values WHERE project_id=@project_id AND tenant_id=@tenant_id ORDER BY variable_id ASC";
			var rs = conn.request(Database.buildSql(sql, params));
			var rec = rs.next();
			while (rec != null) {
				out.push({
					id: Std.int(Reflect.field(rec, "id")),
					projectId: Std.int(Reflect.field(rec, "project_id")),
					variableId: Std.int(Reflect.field(rec, "variable_id")),
					tenantId: Std.int(Reflect.field(rec, "tenant_id")),
					value: Std.string(Reflect.field(rec, "value")),
					createdAt: Date.fromTime(Reflect.field(rec, "created_at"))
				});
				rec = rs.next();
			}
			Database.release(conn);
		} catch (e:Dynamic) {}
		return out;
	}

	public function deleteOverridesForProject(projectId:Int):Void {
		try {
			var params = new Map<String, Dynamic>();
			params.set("project_id", projectId);
			var conn = Database.acquire();
			var sql = "DELETE FROM tenant_variable_values WHERE project_id=@project_id";
			conn.request(Database.buildSql(sql, params));
			Database.release(conn);
		} catch (e:Dynamic) {}
	}

	public function deleteOverridesForVariable(variableId:Int):Void {
		try {
			var params = new Map<String, Dynamic>();
			params.set("variable_id", variableId);
			var conn = Database.acquire();
			var sql = "DELETE FROM tenant_variable_values WHERE variable_id=@variable_id";
			conn.request(Database.buildSql(sql, params));
			Database.release(conn);
		} catch (e:Dynamic) {}
	}

	public function deleteOverridesForTenant(tenantId:Int):Void {
		try {
			var params = new Map<String, Dynamic>();
			params.set("tenant_id", tenantId);
			var conn = Database.acquire();
			var sql = "DELETE FROM tenant_variable_values WHERE tenant_id=@tenant_id";
			conn.request(Database.buildSql(sql, params));
			Database.release(conn);
		} catch (e:Dynamic) {}
	}
}
