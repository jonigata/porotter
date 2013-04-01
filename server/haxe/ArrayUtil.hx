class ArrayUtil {
    static public function shuffle<T>(a:Array<T>) {
        var i = a.length;
        while(0 < i) {
            var j = Std.random(i);
            var t = a[--i];
            a[i] = a[j];
            a[j] = t;
        }
        return a;
    }

    static public function sample<T>(a:Array<T>) {
        return a[Std.random(a.length)];
    }

    static public function find<T>(a:Array<T>, f:T->Bool): T {
        for(e in a) {
            if (f(e)) {
                return e;
            }
        }
        return null;
    }

    static public function find_index<T>(a:Array<T>, f:T->Bool): Null<Int> {
        for(i in 0...a.length) {
            if (f(a[i])) {
                return i;
            }
        }
        return null;
    }
}


