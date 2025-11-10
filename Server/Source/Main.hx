package;

import sidewinder.AsyncBlockerPool;
import sidewinder.UserService;
import sidewinder.CacheService;
import sidewinder.IUserService;
import sidewinder.App;
import sidewinder.AutoRouter;
import sidewinder.DI;
import sidewinder.HybridLogger;
import sidewinder.SideWinderRequestHandler;
import sidewinder.ICacheService;
import hx.injection.ServiceCollection;
import haxe.Json;
import haxe.Http;
import haxe.Timer;
import sidewinder.Router.Response;
import sidewinder.Router.Request;
import sys.thread.Thread;
import lime.app.Application;
import lime.ui.WindowAttributes;
import lime.ui.Window;
import snake.http.*;
import snake.socket.*;
import sys.net.Host;
import sys.net.Socket;
import snake.server.*;
import sidewinder.SideWinderServer;
import lime.ui.Gamepad;
import lime.ui.GamepadButton;
import Date;
import sidewinder.Database; 

import hx.injection.Service;
// Removed DeployApi; using AutoRouter-based controllers
import sidewinderdeploy.shared.*;
import deploy.*;

using hx.injection.ServiceExtensions;

class Main extends Application {
	private static final DEFAULT_PROTOCOL = "HTTP/1.0"; // snake-server needs more work for 1.1 connections
	private static final DEFAULT_ADDRESS = "127.0.0.1";
	private static final DEFAULT_PORT = 8000;

	private var httpServer:SideWinderServer;

	public static var router = SideWinderRequestHandler.router;

	public var cache:ICacheService;

	public function new() {
		super();

		// Initialize database and run migrations
		Database.runMigrations();
		HybridLogger.init(true);

		// Cache service will be resolved from DI

		var directory:String = null;

		// Configure SideWinderRequestHandler
		BaseHTTPRequestHandler.protocolVersion = DEFAULT_PROTOCOL;
		SideWinderRequestHandler.corsEnabled = false;
		SideWinderRequestHandler.cacheEnabled = true;
		SideWinderRequestHandler.silent = true;

		DI.init(c -> {
			c.addSingleton(ICacheService, CacheService);
			c.addScoped(IProjectService, ProjectService);
			c.addScoped(IEnvironmentService, EnvironmentService);
			c.addScoped(IMachineService, MachineService);
			c.addScoped(IReleaseService, ReleaseService);
			c.addScoped(IDeploymentService, DeploymentService);
			c.addScoped(ITenantService, TenantService);
			c.addScoped(IProjectVariableService, ProjectVariableService);
			c.addScoped(ITenantVariableValueService, TenantVariableValueService);
		});

		cache = DI.get(ICacheService);

		httpServer = new SideWinderServer(new Host(DEFAULT_ADDRESS), DEFAULT_PORT, SideWinderRequestHandler, true, directory);

		// Example middleware: logging
		App.use((req, res, next) -> {
			//
			HybridLogger.info('${req.method} ${req.path} ' + Sys.time());
			next();
		}); 

		// Build AutoRouter mappings for all controllers
		AutoRouter.build(router, IProjectService, () -> DI.get(IProjectService));
		AutoRouter.build(router, IEnvironmentService, () -> DI.get(IEnvironmentService));
		AutoRouter.build(router, IMachineService, () -> DI.get(IMachineService));
		AutoRouter.build(router, IReleaseService, () -> DI.get(IReleaseService));
		AutoRouter.build(router, IDeploymentService, () -> DI.get(IDeploymentService));
		AutoRouter.build(router, ITenantService, () -> DI.get(ITenantService));
		AutoRouter.build(router, IProjectVariableService, () -> DI.get(IProjectVariableService));
		AutoRouter.build(router, ITenantVariableValueService, () -> DI.get(ITenantVariableValueService));
	}

	// Entry point
	public static function main() {
		var app:Main = new Main();
		app.exec();
	}

	// Override update to serve HTTP requests
	public override function update(deltaTime:Int):Void {
		httpServer.handleRequest();
	}

	// Override createWindow to prevent Lime from creating a window
	override public function createWindow(attributes:WindowAttributes):Window {
		return null;
	}
}
