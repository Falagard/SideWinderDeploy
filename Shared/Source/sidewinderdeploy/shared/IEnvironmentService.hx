package sidewinderdeploy.shared;

import sidewinderdeploy.shared.DeployModels;
import hx.injection.Service;

interface IEnvironmentService extends Service {
	@get("/api/environments")
	public function listEnvironments():Array<Environment>;
	@post("/api/environments")
	public function createEnvironment(env:Environment):Environment;
	@get("/api/environments/:id")
	public function getEnvironment(id:Int):Null<Environment>;
}
