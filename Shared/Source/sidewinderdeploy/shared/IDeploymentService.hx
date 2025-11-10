package sidewinderdeploy.shared;

import sidewinderdeploy.shared.DeployModels;
import hx.injection.Service;

interface IDeploymentService extends Service {
	@post("/api/releases/:releaseId/deployments")
	public function createDeployment(releaseId:Int, deployment:Deployment):Deployment;
	@get("/api/releases/:releaseId/deployments")
	public function listDeployments(releaseId:Int):Array<Deployment>;
	@get("/api/deployments/:id")
	public function getDeployment(id:Int):Null<Deployment>;
}
