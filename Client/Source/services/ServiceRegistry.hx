package services;

import sidewinder.AutoClient;
// TODO: Adjust these imports to actual package paths in SideWinderDeployShared
import sidewinderdeploy.shared.IProjectService;
import sidewinderdeploy.shared.IReleaseService;
import sidewinderdeploy.shared.IEnvironmentService;
import sidewinderdeploy.shared.IDeploymentService;
import sidewinderdeploy.shared.ITenantService;
import sidewinderdeploy.shared.IAuthService;

/**
 * Central place to create & hold generated AutoClient service proxies.
 * Uses a singleton for simplicity; can be refactored to DI later.
 */
class ServiceRegistry {
    #if (js || html5)
    // For html5: determine default base at runtime (inline const not possible for dynamic values)
    public static var instance(default, null):ServiceRegistry = new ServiceRegistry(determineDefaultBase());
    static function determineDefaultBase():String {
        var defined = util.BuildConfig.apiHost(); // compile-time literal ("" if not set)
        if (defined != null && defined != "") return defined;
        return js.Browser.window.location.origin + "/api"; // adjust '/api' if not needed
    }
    #else
    public static var instance(default, null):ServiceRegistry = new ServiceRegistry("http://localhost:8000");
    #end

    public var project(default, null):IProjectService;
    public var release(default, null):IReleaseService;
    public var environment(default, null):IEnvironmentService;
    public var deployment(default, null):IDeploymentService;
    public var tenant(default, null):ITenantService;
    public var auth(default, null):IAuthService;

    public var baseUrl(default, null):String;

    public function new(baseUrl:String) {
        // Ensure trailing slash not required; callers pass base without slash
        if (StringTools.endsWith(baseUrl, "/")) baseUrl = baseUrl.substr(0, baseUrl.length - 1);
        this.baseUrl = baseUrl;
        project = AutoClient.create(IProjectService, baseUrl);
        release = AutoClient.create(IReleaseService, baseUrl);
        environment = AutoClient.create(IEnvironmentService, baseUrl);
        deployment = AutoClient.create(IDeploymentService, baseUrl);
        tenant = AutoClient.create(ITenantService, baseUrl);
        auth = AutoClient.create(IAuthService, baseUrl);
    }
}
