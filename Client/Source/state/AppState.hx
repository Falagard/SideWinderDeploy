package state;

import services.ServiceRegistry;
import services.AsyncServiceRegistry;

/** Global application state & selections */
class AppState {
    public static var instance(default, null):AppState = new AppState();

    public var services:ServiceRegistry;
    public var asyncServices:AsyncServiceRegistry; // global async service access

    // Current selections
    public var selectedProjectId:Observable<Int> = new Observable<Int>(-1);
    public var selectedEnvironmentId:Observable<Int> = new Observable<Int>(-1);
    public var selectedMachineId:Observable<Int> = new Observable<Int>(-1);
    public var selectedTenantId:Observable<Int> = new Observable<Int>(-1);
    public var selectedPrimaryCategory:Observable<String> = new Observable<String>("Projects");

    private function new() {
        services = ServiceRegistry.instance;
        asyncServices = AsyncServiceRegistry.instance;
    }
}
