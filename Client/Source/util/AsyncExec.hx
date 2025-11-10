package util;

import haxe.ui.Toolkit;
// Use sys.thread.Thread when available (HashLink, cpp, etc.)
#if (sys || hl || hxcpp || neko)
import sys.thread.Thread;
#end
import haxe.Timer;

/** Utility to run blocking service calls off the UI thread (where supported). */
class AsyncExec {
    /**
     * Execute a function returning T asynchronously and invoke callback on UI thread.
     * On sys targets uses Thread.create; on js falls back to Timer (still single-threaded but defers execution).
     */
    public static function run<T>(fn:Void->T, callback:T->Void, ?error:(Dynamic->Void)):Void {
        #if js
        // Defer execution to allow UI to update before potential blocking work.
        Timer.delay(function() {
            var result:T = null;
            try {
                result = fn();
            } catch (e:Dynamic) {
                if (error != null) error(e); else trace('AsyncExec error: ' + e);
                return;
            }
            Toolkit.callLater(function() callback(result));
        }, 1);
        #else
        Thread.create(function() {
            var result:T = null;
            try {
                result = fn();
            } catch (e:Dynamic) {
                if (error != null) error(e); else trace('AsyncExec error: ' + e);
                return;
            }
            Toolkit.callLater(function() callback(result));
        });
        #end
    }
}
