package services;

import sidewinder.AutoClientAsync;
import sidewinderdeploy.shared.IProjectService;
import sidewinderdeploy.shared.IReleaseService;
import sidewinderdeploy.shared.IEnvironmentService;
import sidewinderdeploy.shared.IDeploymentService;
import sidewinderdeploy.shared.ITenantService;
import sidewinderdeploy.shared.IProjectVariableService;
import sidewinderdeploy.shared.ITenantVariableValueService;
import sidewinderdeploy.shared.IMachineService;
import sidewinderdeploy.shared.IAuthService;

/**
 * Holds async (callback-based) service clients generated via AutoClientAsync.
 * Methods are suffixed with Async (e.g. listProjectsAsync). Fields are Dynamic because
 * generated classes do not implement the original interface directly.
 */
class AsyncServiceRegistry {
    public static var instance(default, null):AsyncServiceRegistry = new AsyncServiceRegistry(ServiceRegistry.instance.baseUrl);

    public var baseUrl(default, null):String;

    public var project:Dynamic;
    public var release:Dynamic;
    public var environment:Dynamic;
    public var deployment:Dynamic;
    public var machine:Dynamic; // new machine service client
    public var tenant:Dynamic;
    public var projectVariable:Dynamic;
    public var tenantVariableValue:Dynamic;
    public var auth:Dynamic; // authentication service

    public function new(baseUrl:String) {
        this.baseUrl = baseUrl;
        project = AutoClientAsync.create(IProjectService, baseUrl);
        release = AutoClientAsync.create(IReleaseService, baseUrl);
        environment = AutoClientAsync.create(IEnvironmentService, baseUrl);
        deployment = AutoClientAsync.create(IDeploymentService, baseUrl);
        machine = AutoClientAsync.create(IMachineService, baseUrl);
        tenant = AutoClientAsync.create(ITenantService, baseUrl);
        projectVariable = AutoClientAsync.create(IProjectVariableService, baseUrl);
        tenantVariableValue = AutoClientAsync.create(ITenantVariableValueService, baseUrl);
        auth = AutoClientAsync.create(IAuthService, baseUrl);
    }

    public function resetBaseUrl(newUrl:String):Void {
        if (newUrl == baseUrl) return;
        baseUrl = newUrl;
        // Recreate clients with new base URL
        project = AutoClientAsync.create(IProjectService, baseUrl);
        release = AutoClientAsync.create(IReleaseService, baseUrl);
        environment = AutoClientAsync.create(IEnvironmentService, baseUrl);
        deployment = AutoClientAsync.create(IDeploymentService, baseUrl);
        machine = AutoClientAsync.create(IMachineService, baseUrl);
        tenant = AutoClientAsync.create(ITenantService, baseUrl);
        projectVariable = AutoClientAsync.create(IProjectVariableService, baseUrl);
        tenantVariableValue = AutoClientAsync.create(ITenantVariableValueService, baseUrl);
        auth = AutoClientAsync.create(IAuthService, baseUrl);
    }
}
