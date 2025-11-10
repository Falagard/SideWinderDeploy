package ;

import haxe.ui.HaxeUIApp;
import haxe.ui.Toolkit;
import haxe.ui.styles.StyleSheet;
import haxe.ui.styles.CompositeStyleSheet;
import components.Notifications;
import haxe.ui.containers.dialogs.Dialog; // (no direct use yet, kept for future global styling)

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
            app.start();
        });
    }
}



