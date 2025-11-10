package deploy;

import sidewinderdeploy.shared.DeployModels;
import sidewinderdeploy.shared.ITenantVariableValueService;
import sidewinderdeploy.shared.IProjectVariableService;
import sidewinder.DI;
import Date;
import sidewinder.Database;

class ProjectVariableService implements IProjectVariableService {
	public function new() {
	}

	public function listProjectVariables(projectId:Int):Array<ProjectVariable> {
		var out = new Array<ProjectVariable>();
		try {
			var params = new Map<String, Dynamic>();
			params.set("project_id", projectId);
			var conn = Database.acquire();
			var sql = "SELECT id, project_id, name, default_value, created_at FROM project_variables WHERE project_id=@project_id ORDER BY id ASC";
			var rs = conn.request(Database.buildSql(sql, params));
			var rec = rs.next();
			while (rec != null) {
				out.push(rowToVariable(rec));
				rec = rs.next();
			}
			Database.release(conn);
		} catch (e:Dynamic) {
            
        }
		return out;
	}

	public function createProjectVariable(projectId:Int, variable:ProjectVariable):ProjectVariable {
		var now = Date.now();
		var created:ProjectVariable = { id:0, projectId:projectId, name:variable.name, defaultValue:variable.defaultValue, createdAt:now };
		try {
			var params = new Map<String, Dynamic>();
			params.set("project_id", created.projectId);
			params.set("name", created.name);
			params.set("default_value", created.defaultValue);
			params.set("created_at", now.getTime());
			var conn = Database.acquire();
			var sql = "INSERT INTO project_variables (project_id, name, default_value, created_at) VALUES (@project_id, @name, @default_value, @created_at)";
			conn.request(Database.buildSql(sql, params));
			var rs = conn.request("SELECT last_insert_rowid() AS id");
			var rec = rs.next();
			if (rec != null && Reflect.hasField(rec, "id")) created.id = Std.int(Reflect.field(rec, "id"));
			Database.release(conn);
		} catch (e:Dynamic) {}
		return created;
	}

	public function getProjectVariable(id:Int):Null<ProjectVariable> {
		try {
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			var conn = Database.acquire();
			var sql = "SELECT id, project_id, name, default_value, created_at FROM project_variables WHERE id=@id";
			var rs = conn.request(Database.buildSql(sql, params));
			var rec = rs.next();
			Database.release(conn);
			if (rec == null) return null;
			return rowToVariable(rec);
		} catch (e:Dynamic) {
			return null;
		}
	}

	public function updateProjectVariable(id:Int, variable:ProjectVariable):Null<ProjectVariable> {
		try {
			var existing = getProjectVariable(id);
			if (existing == null) return null;
			if (variable.name != null) existing.name = variable.name;
			if (variable.defaultValue != null) existing.defaultValue = variable.defaultValue;
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			params.set("name", existing.name);
			params.set("default_value", existing.defaultValue);
			var sql = "UPDATE project_variables SET name=@name, default_value=@default_value WHERE id=@id";
			var conn = Database.acquire();
			conn.request(Database.buildSql(sql, params));
			Database.release(conn);
			return existing;
		} catch (e:Dynamic) {
			return null;
		}
	}

	public function deleteProjectVariable(id:Int):Bool {
		var existed = false;
		try {
			existed = (getProjectVariable(id) != null);
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			var sql = "DELETE FROM project_variables WHERE id=@id";
			var conn = Database.acquire();
			conn.request(Database.buildSql(sql, params));
			Database.release(conn);
		} catch (e:Dynamic) {}
		if (existed) {
			try {
				var tvv:ITenantVariableValueService = DI.get(ITenantVariableValueService);
				if (tvv != null) tvv.deleteOverridesForVariable(id);
			} catch (e:Dynamic) {}
		}
		return existed;
	}

	public function deleteVariablesForProject(projectId:Int):Void {
		try {
			// Gather variable ids first for cascade overrides.
			var ids = new Array<Int>();
			var params = new Map<String, Dynamic>();
			params.set("project_id", projectId);
			var conn = Database.acquire();
			var sel = "SELECT id FROM project_variables WHERE project_id=@project_id";
			var rs = conn.request(Database.buildSql(sel, params));
			var rec = rs.next();
			while (rec != null) {
				if (Reflect.hasField(rec, "id")) ids.push(Std.int(Reflect.field(rec, "id")));
				rec = rs.next();
			}
			// Delete variables.
			var delSql = "DELETE FROM project_variables WHERE project_id=@project_id";
			conn.request(Database.buildSql(delSql, params));
			Database.release(conn);
			// Cascade tenant overrides.
			try {
				var tvv:ITenantVariableValueService = DI.get(ITenantVariableValueService);
				for (vid in ids) tvv.deleteOverridesForVariable(vid);
			} catch (e:Dynamic) {}
		} catch (e:Dynamic) {}
	}

	function rowToVariable(rec:Dynamic):ProjectVariable {
		return {
			id: Std.int(Reflect.field(rec, "id")),
			projectId: Std.int(Reflect.field(rec, "project_id")),
			name: Std.string(Reflect.field(rec, "name")),
			defaultValue: Std.string(Reflect.field(rec, "default_value")),
			createdAt: Date.fromTime(Reflect.field(rec, "created_at"))
		};
	}
}
