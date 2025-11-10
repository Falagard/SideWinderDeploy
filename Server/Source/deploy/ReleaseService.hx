package deploy;

import sidewinderdeploy.shared.DeployModels;
import sidewinderdeploy.shared.IReleaseService;
import Date;
import sidewinder.Database;
import sidewinder.HybridLogger;

class ReleaseService implements IReleaseService {
	public function new() {
	}

	public function createRelease(projectId:Int, release:Release):Release {
		// Sanity check: enforce consistency between provided projectId and release.projectId
		if (release.projectId != projectId) {
			HybridLogger.warn('ReleaseService.createRelease mismatch: param projectId=' + projectId + ' release.projectId=' + release.projectId + ' (forcing to param)');
			// Normalize the incoming release object so downstream logic is consistent
			release.projectId = projectId;
		}
		var version = nextVersion(projectId);
		var now = Date.now();
		var created:Release = { id:0, projectId:projectId, version:version, notes:release.notes, createdAt:now };
		try {
			var params = new Map<String, Dynamic>();
			params.set("project_id", created.projectId);
			params.set("version", created.version);
			params.set("notes", created.notes);
			params.set("created_at", now.getTime());
			var conn = Database.acquire();
			var sql = "INSERT INTO releases (project_id, version, notes, created_at) VALUES (@project_id, @version, @notes, @created_at)";
			conn.request(Database.buildSql(sql, params));
			var rs = conn.request("SELECT last_insert_rowid() AS id");
			var rec = rs.next();
			if (rec != null && Reflect.hasField(rec, "id")) created.id = Std.int(Reflect.field(rec, "id"));
			Database.release(conn);
		} catch (e:Dynamic) {}
		return created;
	}

	public function listReleases(projectId:Int):Array<Release> {
		var out = new Array<Release>();
		try {
			var params = new Map<String, Dynamic>();
			params.set("project_id", projectId);
			var conn = Database.acquire();
			var sql = "SELECT id, project_id, version, notes, created_at FROM releases WHERE project_id=@project_id ORDER BY id ASC";
			var rs = conn.request(Database.buildSql(sql, params));
			var rec = rs.next();
			while (rec != null) {
				out.push(rowToRelease(rec));
				rec = rs.next();
			}
			Database.release(conn);
		} catch (e:Dynamic) {}
		return out;
	}

	public function getRelease(id:Int):Null<Release> {
		try {
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			var conn = Database.acquire();
			var sql = "SELECT id, project_id, version, notes, created_at FROM releases WHERE id=@id";
			var rs = conn.request(Database.buildSql(sql, params));
			var rec = rs.next();
			Database.release(conn);
			if (rec == null) return null;
			return rowToRelease(rec);
		} catch (e:Dynamic) {
			return null;
		}
	}

	function rowToRelease(rec:Dynamic):Release {
		return {
			id: Std.int(Reflect.field(rec, "id")),
			projectId: Std.int(Reflect.field(rec, "project_id")),
			version: Std.string(Reflect.field(rec, "version")),
			notes: Std.string(Reflect.field(rec, "notes")),
			createdAt: Date.fromTime(Reflect.field(rec, "created_at"))
		};
	}

	function nextVersion(projectId:Int):String {
		var maxPatch = 0;
		try {
			var params = new Map<String, Dynamic>();
			params.set("project_id", projectId);
			var conn = Database.acquire();
			var sql = "SELECT version FROM releases WHERE project_id=@project_id";
			var rs = conn.request(Database.buildSql(sql, params));
			var rec = rs.next();
			while (rec != null) {
				var ver = Std.string(Reflect.field(rec, "version"));
				var parts = ver.split(".");
				var patch = Std.parseInt(parts[parts.length - 1]);
				if (patch != null && patch > maxPatch) maxPatch = patch;
				rec = rs.next();
			}
			Database.release(conn);
		} catch (e:Dynamic) {}
		return '1.0.${maxPatch + 1}';
	}
}
