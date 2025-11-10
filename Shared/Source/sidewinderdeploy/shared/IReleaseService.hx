package sidewinderdeploy.shared;

import sidewinderdeploy.shared.DeployModels;
import hx.injection.Service;

interface IReleaseService extends Service {
	@post("/api/projects/:projectId/releases")
	public function createRelease(projectId:Int, release:Release):Release;
	@get("/api/projects/:projectId/releases")
	public function listReleases(projectId:Int):Array<Release>;
	@get("/api/releases/:id")
	public function getRelease(id:Int):Null<Release>;
}
