package deploy;

import sidewinderdeploy.shared.*;
import sidewinderdeploy.shared.DeployModels;
import sidewinder.DI;
import Date;
import sidewinder.Database;

class ProjectService implements IProjectService {
	public function new() {}

	public function listProjects():Array<Project> {
		var out = new Array<Project>();
		try {
			var conn = Database.acquire();
			var rs = conn.request("SELECT id, name, description, created_at FROM projects ORDER BY id ASC");
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

	public function createProject(project:Project):Project {
		var now = Date.now();
		var p:Project = { id:0, name:project.name, description:project.description, createdAt:now };
		var params = new Map<String, Dynamic>();
		params.set("name", p.name);
		params.set("description", p.description);
		params.set("created_at", p.createdAt.getTime());
		var conn = Database.acquire();
		var insertSql = "INSERT INTO projects (name, description, created_at) VALUES (@name, @description, @created_at)";
		try {
			conn.request(Database.buildSql(insertSql, params));
			var rs = conn.request("SELECT last_insert_rowid() AS id");
			var rec = rs.next();
			if (rec != null && Reflect.hasField(rec, "id")) p.id = Std.int(Reflect.field(rec, "id"));
		} catch (e:Dynamic) {}
		Database.release(conn);
		return p;
	}

	// DB-backed getProject; fallback to in-memory if select fails or record missing.
	public function getProject(id:Int):Null<Project> {
		try {
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			var conn = Database.acquire();
			var sql = "SELECT id, name, description, created_at FROM projects WHERE id=@id";
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

	public function updateProject(id:Int, project:Project):Null<Project> {
		try {
			var existing = getProject(id);
			if (existing == null) return null;
			if (project.name != null) existing.name = project.name;
			if (project.description != null) existing.description = project.description;
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			params.set("name", existing.name);
			params.set("description", existing.description);
			var sql = "UPDATE projects SET name=@name, description=@description WHERE id=@id";
			var conn = Database.acquire();
			conn.request(Database.buildSql(sql, params));
			Database.release(conn);
			return existing;
		} catch (e:Dynamic) {
			return null;
		}
	}

	public function deleteProject(id:Int):Bool {
		var existed = false;
		try {
			// Check existence first
			existed = (getProject(id) != null);
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			var sql = "DELETE FROM projects WHERE id=@id";
			var conn = Database.acquire();
			conn.request(Database.buildSql(sql, params));
			Database.release(conn);
		} catch (e:Dynamic) {
			return false;
		}
		if (existed) {
			try {
				var releaseService:IReleaseService = DI.get(IReleaseService);
				var deploymentService:IDeploymentService = DI.get(IDeploymentService);
				var projectVariableService:IProjectVariableService = DI.get(IProjectVariableService);
				var tenantValueService:ITenantVariableValueService = DI.get(ITenantVariableValueService);
				for (r in releaseService.listReleases(id)) {
					for (d in deploymentService.listDeployments(r.id)) {
						// Deployment deletion not implemented.
					}
				}
				projectVariableService.deleteVariablesForProject(id);
				tenantValueService.deleteOverridesForProject(id);
			} catch (e:Dynamic) {}
		}
		return existed;
	}

	function generateId(prefix:String):String {
		return prefix + "-" + Std.string(Math.floor(Math.random() * 1_000_000));
	}
}
