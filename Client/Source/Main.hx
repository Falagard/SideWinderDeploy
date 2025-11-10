package ;

import haxe.ui.HaxeUIApp;
import haxe.ui.Toolkit;
import haxe.ui.styles.StyleSheet;
import haxe.ui.styles.CompositeStyleSheet;
import components.Notifications;
import haxe.ui.containers.dialogs.Dialog; // (no direct use yet, kept for future global styling)
import views.auth.AuthManager;

class Main {
    public static function main() {
        var app = new HaxeUIApp();
        app.ready(function() {
            // Inject custom styles for errorBanner
            var css = "" +
                ".errorBanner { background-color:#ffe5e5; border:1px solid #d35454; padding:6px 10px; border-radius:4px; color:#7d1f1f; font-size:13px; }" +
                ".errorBanner Button { margin-left:8px; }" +
                ".errorBanner .errorText { font-weight:bold; }" +
                // (Toast styles removed; using built-in HaxeUI notifications now)
                "";
                // variable row styling + separator rule under each row
                css += ".variableRow { padding:4px 6px; border-bottom:1px solid #d8d8d8; } .variableRow:last-child { border-bottom:none; } .variableRow:nth-child(odd) { background-color:#f5f5f5; }";
                css += ".variableForm {  }";
                css += ".variableFormOverlay { background-color:#ffffff; border:1px solid #a8b8d0; border-radius:6px; box-shadow:0 4px 14px rgba(0,0,0,0.28); }";
                css += ".releaseFormOverlay { background-color:#ffffff; border:1px solid #b0c4e0; border-radius:6px; padding:14px 18px; box-shadow:0 5px 18px rgba(0,0,0,0.30); }";
                // legacy ModalManager styles removed; dialog-specific styles applied via overlay classes
                // Authentication dialog styles
                css += ".loginDialog { background-color:#ffffff; border:1px solid #a8b8d0; border-radius:6px; box-shadow:0 4px 14px rgba(0,0,0,0.28); }";
                css += ".registerDialog { background-color:#ffffff; border:1px solid #a8b8d0; border-radius:6px; box-shadow:0 4px 14px rgba(0,0,0,0.28); }";
                css += ".dialogTitle { font-size:18px; font-weight:bold; margin-bottom:10px; }";
                css += ".topSpacing { margin-top:8px; }";
                // Top bar styles
                css += ".topBar { background-color:#2c3e50; padding:8px 16px; border-bottom:2px solid #34495e; }";
                css += ".appTitle { color:#ecf0f1; font-size:16px; font-weight:bold; }";
                css += ".userLabel { color:#bdc3c7; font-size:14px; margin-right:12px; }";
                css += ".logoutBtn { background-color:#e74c3c; color:#ffffff; border:none; padding:6px 12px; border-radius:4px; }";
            var sheet = new StyleSheet();
            sheet.parse(css);
            if (Toolkit.styleSheet == null) {
                var composite = new CompositeStyleSheet();
                composite.addStyleSheet(sheet);
                Toolkit.styleSheet = composite;
            } else {
                Toolkit.styleSheet.addStyleSheet(sheet);
            }
            var mainView = new MainView();
            app.addComponent(mainView);
            Notifications.init(mainView);
            // ModalManager removed; dialogs use Screen overlay by default
            
            // Initialize authentication
            var authManager = new AuthManager(mainView);
            authManager.checkAuthentication();
            
            app.start();
        });
    }
}


