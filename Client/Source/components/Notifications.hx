package components;

import haxe.ui.core.Component;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.notifications.NotificationType;
import haxe.ui.notifications.NotificationData;

/**
 * Type-safe wrapper around HaxeUI's NotificationManager.
 * Provides a unified entry point plus convenience helpers.
 */
class Notifications {
    static var _root:Component; // reserved for future scoping / multi-root handling

    public static function init(root:Component):Void {
        _root = root;
    }

    /** Show a notification with duration (ms) and kind: info|success|error|warning */
    public static function show(message:String, kind:String = "info", duration:Int = 4000):Void {
        var normalized = normalizeKind(kind);
        var t:NotificationType = switch (normalized) {
            case "success": NotificationType.Success;
            case "error": NotificationType.Error;
            case "warning": NotificationType.Warning;
            case "info": NotificationType.Info;
            case _: NotificationType.Info;
        };
        var data:NotificationData = {
            body: message,
            type: t,
            expiryMs: duration
        };
        NotificationManager.instance.addNotification(data);
    }

    static inline function normalizeKind(kind:String):String {
        return switch (kind) {
            case "success" | "error" | "info" | "warning": kind;
            default: "info";
        };
    }

    // Convenience shortcuts
    public static inline function success(msg:String, duration:Int = 4000) show(msg, "success", duration);
    public static inline function error(msg:String, duration:Int = 4000) show(msg, "error", duration);
    public static inline function info(msg:String, duration:Int = 4000) show(msg, "info", duration);
    public static inline function warning(msg:String, duration:Int = 4000) show(msg, "warning", duration);
}
