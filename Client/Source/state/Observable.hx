package state;

typedef Listener<T> = T -> Void;

/** Simple observable wrapper for primitive & object types */
class Observable<T> {
    public var value(get, set):T;
    var _value:T;
    var listeners:Array<Listener<T>> = [];

    public function new(initial:T) {
        _value = initial;
    }

    inline function get_value():T return _value;

    function set_value(v:T):T {
        if (v != _value) {
            _value = v;
            for (l in listeners) l(_value);
        }
        return v;
    }

    public function watch(l:Listener<T>):Void listeners.push(l);
    public function unwatch(l:Listener<T>):Void listeners.remove(l);
}
