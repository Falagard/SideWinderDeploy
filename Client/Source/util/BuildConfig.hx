package util;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
 * Compile-time accessors for build defines. Use the macro methods to inject
 * string literals so normal runtime code doesn't need to reference unknown identifiers.
 */
class BuildConfig {
    /**
     * Returns the value of -D api_host as a string literal, or "" if not defined.
     */
    public static macro function apiHost():Expr {
        var v = Context.definedValue("api_host");
        if (v == null) v = "";
        return macro $v{v};
    }
}
