package sidewinderdeploy.shared;

import Date;

typedef Project = {
	var id:Int;
	var name:String;
	var description:String;
	var createdAt:Date;
}

typedef Environment = {
	var id:Int;
	var name:String;
	var createdAt:Date;
}

typedef Machine = {
	var id:Int;
	var name:String;
	var roles:Array<String>;
	var environmentIds:Array<Int>; // environments where this machine participates
	var createdAt:Date;
}

typedef Release = {
	var id:Int;
	var projectId:Int;
	var version:String;
	var notes:String;
	var createdAt:Date;
}


enum abstract DeploymentStatus(String) {
	var Queued = "Queued";
	var Executing = "Executing";
	var Succeeded = "Succeeded";
	var Failed = "Failed";
}

typedef Deployment = {
	var id:Int;
	var releaseId:Int;
	var environmentId:Int;
	var status:DeploymentStatus;
	var startedAt:Date;
	var finishedAt:Null<Date>;
}

// Tenants represent logical customer or business units that can have per-project variable overrides
typedef Tenant = {
	var id:Int;
	var name:String;
	var description:String;
	var createdAt:Date;
}

// Variables defined at the project level; tenants may override their values
typedef ProjectVariable = {
	var id:Int;
	var projectId:Int;
	var name:String; // unique per project
	var defaultValue:String;
	var createdAt:Date;
}

// Value override for a tenant; if absent, ProjectVariable.defaultValue applies.
typedef TenantProjectVariableValue = {
	var id:Int; // separate id for tracking changes/history potential
	var projectId:Int;
	var variableId:Int;
	var tenantId:Int;
	var value:String;
	var createdAt:Date;
}
