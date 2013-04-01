using ArrayUtil;

// [b, e)区間演算
// b>e(逆方向)なので注意

class Interval {
    public function new(b, e) {
        this.b = b;
        this.e = e;
    }
    
    public var b: Int;
    public var e: Int;
}

class Intervals {
    public function new() {
        this.elems = new Array<Interval>();
    }

    public function lt(x, y) {
        return x > y; // 逆順
    }

    public function leq(x, y) {
        return x >= y; // 逆順
    }

    public function add(b, e) {
        if (leq(e, b)) {
            throw "arguments must be b <= e";
        }
        if(b == e) {
            return;
        }

        var next = this.elems.find_index(
            function(r: Interval) {
                return lt(b, r.b);
            });
        // if(0 < next) {
        //    assert(leq(this.elems[next-1].b, b));
        // }
        
        if (next == null) {
            next = this.elems.length;
        }

        var interval = new Interval(b, e);
        if (0 < next && leq(b, this.elems[next-1].e)) {
            // 前と結合
            if (lt(this.elems[next-1].e, e)) {
                this.elems[next-1].e = e;
            }
        } else {
            // 前と結合できないので挿入
            this.elems.insert(next, interval);
            next++;
        }
        // assert(0 < next);

        // [b,e)に完全に入っているものはすべて削除
        var base = this.elems[next-1];
        var remove_last = next;
        while (remove_last < this.elems.length &&
               leq(this.elems[remove_last].e, base.e)) {
            remove_last++;
        }
        if (next < remove_last) {
            this.elems.splice(next, remove_last - next);
        }

        // [b,e)に頭部だけ含まれているものは結合
        if (next < this.elems.length) {
            if (leq(this.elems[next].b, base.e)) {
                base.e = this.elems[next].e;
                this.elems.splice(next, 1);
            }
        }
    }

    public function print() {
        var s = "";
        for(v in this.elems) {
            s += Std.format("${v.b}-${v.e} ");
        }
        trace(s);
    }

    public function to_array(): Array<Array<Int>> {
        var a = [];
        for(v in this.elems) {
            a.push([v.b, v.e]);
        }
        return a;
    }

    public function from_array(a: Array<Array<Int>>) {
        for(v in a) {
            add(v[0], v[1]);
        }
    }

    public var elems: Array<Interval>;
}
