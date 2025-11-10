package deploy;

import sidewinderdeploy.shared.DeployModels;
import sidewinderdeploy.shared.IEnvironmentService;
import Date;
import sidewinder.Database;

class EnvironmentService implements IEnvironmentService {
	public function new() {
	}

	public function listEnvironments():Array<Environment> {
		var out = new Array<Environment>();
		try {
			var conn = Database.acquire();
			var rs = conn.request("SELECT id, name, created_at FROM environments ORDER BY id ASC");
			var rec = rs.next();
			while (rec != null) {
				out.push({
					id: Std.int(Reflect.field(rec, "id")),
					name: Std.string(Reflect.field(rec, "name")),
					createdAt: Date.fromTime(Reflect.field(rec, "created_at"))
				});
				rec = rs.next();
			}
			Database.release(conn);
		} catch (e:Dynamic) {}
		return out;
	}

	public function createEnvironment(env:Environment):Environment {
		var now = Date.now();
		var created:Environment = { id:0, name:env.name, createdAt:now };
		try {
			var params = new Map<String, Dynamic>();
			params.set("name", created.name);
			params.set("created_at", now.getTime());
			var conn = Database.acquire();
			var sql = "INSERT INTO environments (name, created_at) VALUES (@name, @created_at)";
			conn.request(Database.buildSql(sql, params));
			var rs = conn.request("SELECT last_insert_rowid() AS id");
			var rec = rs.next();
			if (rec != null && Reflect.hasField(rec, "id")) created.id = Std.int(Reflect.field(rec, "id"));
			Database.release(conn);
		} catch (e:Dynamic) {}
		return created;
	}

	public function getEnvironment(id:Int):Null<Environment> {
		try {
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			var conn = Database.acquire();
			var sql = "SELECT id, name, created_at FROM environments WHERE id=@id";
			var rs = conn.request(Database.buildSql(sql, params));
			var rec = rs.next();
			Database.release(conn);
			if (rec == null) return null;
			return {
				id: Std.int(Reflect.field(rec, "id")),
				name: Std.string(Reflect.field(rec, "name")),
				createdAt: Date.fromTime(Reflect.field(rec, "created_at"))
			};
		} catch (e:Dynamic) {
			return null;
		}
	}
}
