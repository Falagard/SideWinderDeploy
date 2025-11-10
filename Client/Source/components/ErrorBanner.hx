package components;

import haxe.ui.containers.HBox;
import haxe.ui.components.Label;
import haxe.ui.components.Button;

/** Reusable error banner with retry callback, XML-driven layout. */
@:build(haxe.ui.ComponentBuilder.build("Assets/error-banner.xml"))
class ErrorBanner extends HBox {
    public var onRetry:Void->Void;
    var messageLabel:Label; // from XML id
    var retryBtn:Button; // from XML id

    public function new(message:String, ?retry:Void->Void) {
        super();
        setMessage(message);
        if (retry != null) {
            onRetry = retry;
            if (retryBtn != null) {
                retryBtn.onClick = function(_) if (onRetry != null) onRetry();
                retryBtn.visible = true;
            }
        } else if (retryBtn != null) {
            retryBtn.visible = false; // hide when no retry provided
        }
    }

    public function setMessage(msg:String):Void if (messageLabel != null) messageLabel.text = msg;
}
