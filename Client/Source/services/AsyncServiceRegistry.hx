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
import sidewinder.ICookieJar;
import sidewinder.CookieJar;

/**
 * Holds async (callback-based) service clients generated via AutoClientAsync.
 * Methods are suffixed with Async (e.g. listProjectsAsync). Fields are Dynamic because
 * generated classes do not implement the original interface directly.
 */
class AsyncServiceRegistry {
    public static var instance(default, null):AsyncServiceRegistry = new AsyncServiceRegistry(ServiceRegistry.instance.baseUrl);

    public var baseUrl(default, null):String;
    public var cookieJar(default, null):ICookieJar;

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
        cookieJar = new CookieJar();
        createClients();
    }

    private function createClients():Void {
        project = AutoClientAsync.create(IProjectService, baseUrl, cookieJar);
        release = AutoClientAsync.create(IReleaseService, baseUrl, cookieJar);
        environment = AutoClientAsync.create(IEnvironmentService, baseUrl, cookieJar);
        deployment = AutoClientAsync.create(IDeploymentService, baseUrl, cookieJar);
        machine = AutoClientAsync.create(IMachineService, baseUrl, cookieJar);
        tenant = AutoClientAsync.create(ITenantService, baseUrl, cookieJar);
        projectVariable = AutoClientAsync.create(IProjectVariableService, baseUrl, cookieJar);
        tenantVariableValue = AutoClientAsync.create(ITenantVariableValueService, baseUrl, cookieJar);
        auth = AutoClientAsync.create(IAuthService, baseUrl, cookieJar);
    }

    public function resetBaseUrl(newUrl:String):Void {
        if (newUrl == baseUrl) return;
        baseUrl = newUrl;
        createClients();
    }
}
