package sidewinderdeploy.shared;

import sidewinderdeploy.shared.DeployModels;
import hx.injection.Service;

interface IProjectService extends Service {
	@get("/api/projects")
	public function listProjects():Array<Project>;
	@post("/api/projects")
	public function createProject(project:Project):Project; // service will assign id & createdAt regardless of provided values
	@get("/api/projects/:id")
	public function getProject(id:Int):Null<Project>;
	@put("/api/projects/:id")
	public function updateProject(id:Int, project:Project):Null<Project>; // only name/description used
	@delete("/api/projects/:id")
	public function deleteProject(id:Int):Bool;
}
