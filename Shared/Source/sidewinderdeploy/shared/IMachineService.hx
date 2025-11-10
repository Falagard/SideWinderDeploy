package sidewinderdeploy.shared;

import sidewinderdeploy.shared.DeployModels;
import hx.injection.Service;

interface IMachineService extends Service {
	@get("/api/machines")
	public function listMachines():Array<Machine>;
	@post("/api/machines")
	public function createMachine(machine:Machine):Machine;
	@get("/api/machines/:id")
	public function getMachine(id:Int):Null<Machine>;
}
