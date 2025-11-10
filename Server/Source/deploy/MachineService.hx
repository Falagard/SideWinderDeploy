package deploy;

import sidewinderdeploy.shared.DeployModels;
import sidewinderdeploy.shared.IMachineService;
import Date;
import sidewinder.Database;

class MachineService implements IMachineService {
	public function new() {

	}

	public function listMachines():Array<Machine> {
		var out = new Array<Machine>();
		try {
			var conn = Database.acquire();
			var rs = conn.request("SELECT id, name, roles, environment_ids, created_at FROM machines ORDER BY id ASC");
			var rec = rs.next();
			while (rec != null) {
				out.push(rowToMachine(rec));
				rec = rs.next();
			}
			Database.release(conn);
		} catch (e:Dynamic) {}
		return out;
	}

	public function createMachine(machine:Machine):Machine {
		var now = Date.now();
		var created:Machine = { id:0, name:machine.name, roles:machine.roles, environmentIds:machine.environmentIds, createdAt:now };
		try {
			var params = new Map<String, Dynamic>();
			params.set("name", created.name);
			params.set("roles", created.roles.join(","));
			params.set("environment_ids", created.environmentIds.join(","));
			params.set("created_at", now.getTime());
			var conn = Database.acquire();
			var sql = "INSERT INTO machines (name, roles, environment_ids, created_at) VALUES (@name, @roles, @environment_ids, @created_at)";
			conn.request(Database.buildSql(sql, params));
			var rs = conn.request("SELECT last_insert_rowid() AS id");
			var rec = rs.next();
			if (rec != null && Reflect.hasField(rec, "id")) created.id = Std.int(Reflect.field(rec, "id"));
			Database.release(conn);
		} catch (e:Dynamic) {}
		return created;
	}

	public function getMachine(id:Int):Null<Machine> {
		try {
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			var conn = Database.acquire();
			var sql = "SELECT id, name, roles, environment_ids, created_at FROM machines WHERE id=@id";
			var rs = conn.request(Database.buildSql(sql, params));
			var rec = rs.next();
			Database.release(conn);
			if (rec == null) return null;
			return rowToMachine(rec);
		} catch (e:Dynamic) {
			return null;
		}
	}

	function rowToMachine(rec:Dynamic):Machine {
		var rolesText = Std.string(Reflect.field(rec, "roles"));
		var envText = Std.string(Reflect.field(rec, "environment_ids"));
		return {
			id: Std.int(Reflect.field(rec, "id")),
			name: Std.string(Reflect.field(rec, "name")),
			roles: rolesText.length == 0 ? [] : rolesText.split(","),
			environmentIds: envText.length == 0 ? [] : envText.split(",").map(s -> Std.parseInt(s)).filter(i -> i != null),
			createdAt: Date.fromTime(Reflect.field(rec, "created_at"))
		};
	}
}
