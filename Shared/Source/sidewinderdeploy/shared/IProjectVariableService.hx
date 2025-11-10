package sidewinderdeploy.shared;

import sidewinderdeploy.shared.DeployModels;
import hx.injection.Service;

interface IProjectVariableService extends Service {
	@get("/api/projects/:projectId/variables")
	public function listProjectVariables(projectId:Int):Array<ProjectVariable>;
	@post("/api/projects/:projectId/variables") 
	public function createProjectVariable(projectId:Int, variable:ProjectVariable):ProjectVariable;
	@get("/api/variables/:id")
	public function getProjectVariable(id:Int):Null<ProjectVariable>;
	@put("/api/variables/:id") 
	public function updateProjectVariable(id:Int, variable:ProjectVariable):Null<ProjectVariable>;
	@delete("/api/variables/:id")
	public function deleteProjectVariable(id:Int):Bool;
	@delete("/api/projects/:projectId/variables") 
	public function deleteVariablesForProject(projectId:Int):Void;
}
