package deploy;

import sidewinderdeploy.shared.DeployModels;
import sidewinderdeploy.shared.IDeploymentService;
import Date;
import sidewinder.Database;
import sidewinder.HybridLogger;

class DeploymentService implements IDeploymentService {
	public function new() {
	}

	public function createDeployment(releaseId:Int, deployment:Deployment):Deployment {
		// Sanity check: enforce consistency between provided releaseId and deployment.releaseId
		if (deployment.releaseId != releaseId) {
			HybridLogger.warn('DeploymentService.createDeployment mismatch: param releaseId=' + releaseId + ' deployment.releaseId=' + deployment.releaseId + ' (forcing to param)');
			deployment.releaseId = releaseId;
		}
		var now = Date.now();
		var created:Deployment = { id:0, releaseId:releaseId, environmentId:deployment.environmentId, status:DeploymentStatus.Queued, startedAt:now, finishedAt:null };
		try {
			var params = new Map<String, Dynamic>();
			params.set("release_id", created.releaseId);
			params.set("environment_id", created.environmentId);
			params.set("status", Std.string(created.status));
			params.set("started_at", now.getTime());
			params.set("finished_at", -1);
			var conn = Database.acquire();
			var sql = "INSERT INTO deployments (release_id, environment_id, status, started_at, finished_at) VALUES (@release_id, @environment_id, @status, @started_at, @finished_at)";
			conn.request(Database.buildSql(sql, params));
			var rs = conn.request("SELECT last_insert_rowid() AS id");
			var rec = rs.next();
			if (rec != null && Reflect.hasField(rec, "id")) created.id = Std.int(Reflect.field(rec, "id"));
			Database.release(conn);
		} catch (e:Dynamic) {}
		simulateDeployment(created);
		return created;
	}

	public function listDeployments(releaseId:Int):Array<Deployment> {
		var out = new Array<Deployment>();
		try {
			var params = new Map<String, Dynamic>();
			params.set("release_id", releaseId);
			var conn = Database.acquire();
			var sql = "SELECT id, release_id, environment_id, status, started_at, finished_at FROM deployments WHERE release_id=@release_id ORDER BY id ASC";
			var rs = conn.request(Database.buildSql(sql, params));
			var rec = rs.next();
			while (rec != null) {
				out.push(rowToDeployment(rec));
				rec = rs.next();
			}
			Database.release(conn);
		} catch (e:Dynamic) {}
		return out;
	}

	public function getDeployment(id:Int):Null<Deployment> {
		try {
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			var conn = Database.acquire();
			var sql = "SELECT id, release_id, environment_id, status, started_at, finished_at FROM deployments WHERE id=@id";
			var rs = conn.request(Database.buildSql(sql, params));
			var rec = rs.next();
			Database.release(conn);
			if (rec == null) return null;
			return rowToDeployment(rec);
		} catch (e:Dynamic) {
			return null;
		}
	}

	function rowToDeployment(rec:Dynamic):Deployment {
		var finishedVal:Dynamic = Reflect.field(rec, "finished_at");
		var finishedNum:Int = (finishedVal == null) ? -1 : Std.int(finishedVal);
		var finishedDate:Null<Date> = (finishedNum < 0) ? null : Date.fromTime(finishedNum);
		var statusStr = Std.string(Reflect.field(rec, "status"));
		var status:DeploymentStatus = cast statusStr;
		return {
			id: Std.int(Reflect.field(rec, "id")),
			releaseId: Std.int(Reflect.field(rec, "release_id")),
			environmentId: Std.int(Reflect.field(rec, "environment_id")),
			status: status,
			startedAt: Date.fromTime(Reflect.field(rec, "started_at")),
			finishedAt: finishedDate
		};
	}

	function simulateDeployment(d:Deployment) {
		sys.thread.Thread.create(() -> {
			updateStatus(d.id, DeploymentStatus.Executing);
			Sys.sleep(2);
			updateStatus(d.id, DeploymentStatus.Succeeded);
		});
	}

	function updateStatus(id:Int, status:DeploymentStatus) {
		try {
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			params.set("status", Std.string(status));
			var finishedAt = (status == DeploymentStatus.Succeeded || status == DeploymentStatus.Failed) ? Date.now().getTime() : -1;
			params.set("finished_at", finishedAt);
			var sql = "UPDATE deployments SET status=@status, finished_at=@finished_at WHERE id=@id";
			var conn = Database.acquire();
			conn.request(Database.buildSql(sql, params));
			Database.release(conn);
		} catch (e:Dynamic) {}
	}
}
