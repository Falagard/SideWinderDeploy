package components;

import haxe.ui.core.Component;
import haxe.ui.components.Label;

class StatusBadge extends Component {
    public var status(default, set):String;
    var label:Label;

    public function new(?status:String) {
        super();
        label = new Label();
        addComponent(label);
        this.status = status != null ? status : "unknown";
    }

    function set_status(s:String):String {
        status = s;
        label.text = s;
        // Apply style class based on status (simplified using className)
        var statusClass = switch (s) {
            case "running": "running";
            case "failed": "failed";
            case "succeeded": "succeeded";
            default: "neutral";
        };
        this.className = "statusBadge " + statusClass;
        return s;
    }
}
