(function () { "use strict";
var $hxClasses = {},$estr = function() { return js.Boot.__string_rec(this,''); };
var ArrayUtil = function() { }
$hxClasses["ArrayUtil"] = ArrayUtil;
ArrayUtil.__name__ = ["ArrayUtil"];
ArrayUtil.shuffle = function(a) {
	var i = a.length;
	while(0 < i) {
		var j = Std.random(i);
		var t = a[--i];
		a[i] = a[j];
		a[j] = t;
	}
	return a;
}
ArrayUtil.sample = function(a) {
	return a[Std.random(a.length)];
}
ArrayUtil.find = function(a,f) {
	var _g = 0;
	while(_g < a.length) {
		var e = a[_g];
		++_g;
		if(f(e)) return e;
	}
	return null;
}
ArrayUtil.find_index = function(a,f) {
	var _g1 = 0, _g = a.length;
	while(_g1 < _g) {
		var i = _g1++;
		if(f(a[i])) return i;
	}
	return null;
}
var DateTools = function() { }
$hxClasses["DateTools"] = DateTools;
DateTools.__name__ = ["DateTools"];
DateTools.__format_get = function(d,e) {
	return (function($this) {
		var $r;
		switch(e) {
		case "%":
			$r = "%";
			break;
		case "C":
			$r = StringTools.lpad(Std.string(d.getFullYear() / 100 | 0),"0",2);
			break;
		case "d":
			$r = StringTools.lpad(Std.string(d.getDate()),"0",2);
			break;
		case "D":
			$r = DateTools.__format(d,"%m/%d/%y");
			break;
		case "e":
			$r = Std.string(d.getDate());
			break;
		case "H":case "k":
			$r = StringTools.lpad(Std.string(d.getHours()),e == "H"?"0":" ",2);
			break;
		case "I":case "l":
			$r = (function($this) {
				var $r;
				var hour = d.getHours() % 12;
				$r = StringTools.lpad(Std.string(hour == 0?12:hour),e == "I"?"0":" ",2);
				return $r;
			}($this));
			break;
		case "m":
			$r = StringTools.lpad(Std.string(d.getMonth() + 1),"0",2);
			break;
		case "M":
			$r = StringTools.lpad(Std.string(d.getMinutes()),"0",2);
			break;
		case "n":
			$r = "\n";
			break;
		case "p":
			$r = d.getHours() > 11?"PM":"AM";
			break;
		case "r":
			$r = DateTools.__format(d,"%I:%M:%S %p");
			break;
		case "R":
			$r = DateTools.__format(d,"%H:%M");
			break;
		case "s":
			$r = Std.string(d.getTime() / 1000 | 0);
			break;
		case "S":
			$r = StringTools.lpad(Std.string(d.getSeconds()),"0",2);
			break;
		case "t":
			$r = "\t";
			break;
		case "T":
			$r = DateTools.__format(d,"%H:%M:%S");
			break;
		case "u":
			$r = (function($this) {
				var $r;
				var t = d.getDay();
				$r = t == 0?"7":Std.string(t);
				return $r;
			}($this));
			break;
		case "w":
			$r = Std.string(d.getDay());
			break;
		case "y":
			$r = StringTools.lpad(Std.string(d.getFullYear() % 100),"0",2);
			break;
		case "Y":
			$r = Std.string(d.getFullYear());
			break;
		default:
			$r = (function($this) {
				var $r;
				throw "Date.format %" + e + "- not implemented yet.";
				return $r;
			}($this));
		}
		return $r;
	}(this));
}
DateTools.__format = function(d,f) {
	var r = new StringBuf();
	var p = 0;
	while(true) {
		var np = f.indexOf("%",p);
		if(np < 0) break;
		r.b += HxOverrides.substr(f,p,np - p);
		r.b += Std.string(DateTools.__format_get(d,HxOverrides.substr(f,np + 1,1)));
		p = np + 2;
	}
	r.b += HxOverrides.substr(f,p,f.length - p);
	return r.b;
}
DateTools.format = function(d,f) {
	return DateTools.__format(d,f);
}
DateTools.delta = function(d,t) {
	return (function($this) {
		var $r;
		var d1 = new Date();
		d1.setTime(d.getTime() + t);
		$r = d1;
		return $r;
	}(this));
}
DateTools.getMonthDays = function(d) {
	var month = d.getMonth();
	var year = d.getFullYear();
	if(month != 1) return DateTools.DAYS_OF_MONTH[month];
	var isB = year % 4 == 0 && year % 100 != 0 || year % 400 == 0;
	return isB?29:28;
}
DateTools.seconds = function(n) {
	return n * 1000.0;
}
DateTools.minutes = function(n) {
	return n * 60.0 * 1000.0;
}
DateTools.hours = function(n) {
	return n * 60.0 * 60.0 * 1000.0;
}
DateTools.days = function(n) {
	return n * 24.0 * 60.0 * 60.0 * 1000.0;
}
DateTools.parse = function(t) {
	var s = t / 1000;
	var m = s / 60;
	var h = m / 60;
	return { ms : t % 1000, seconds : s % 60 | 0, minutes : m % 60 | 0, hours : h % 24 | 0, days : h / 24 | 0};
}
DateTools.make = function(o) {
	return o.ms + 1000.0 * (o.seconds + 60.0 * (o.minutes + 60.0 * (o.hours + 24.0 * o.days)));
}
var EReg = function(r,opt) {
	opt = opt.split("u").join("");
	this.r = new RegExp(r,opt);
};
$hxClasses["EReg"] = EReg;
EReg.__name__ = ["EReg"];
EReg.prototype = {
	customReplace: function(s,f) {
		var buf = new StringBuf();
		while(true) {
			if(!this.match(s)) break;
			buf.b += Std.string(this.matchedLeft());
			buf.b += Std.string(f(this));
			s = this.matchedRight();
		}
		buf.b += Std.string(s);
		return buf.b;
	}
	,replace: function(s,by) {
		return s.replace(this.r,by);
	}
	,split: function(s) {
		var d = "#__delim__#";
		return s.replace(this.r,d).split(d);
	}
	,matchedPos: function() {
		if(this.r.m == null) throw "No string matched";
		return { pos : this.r.m.index, len : this.r.m[0].length};
	}
	,matchedRight: function() {
		if(this.r.m == null) throw "No string matched";
		var sz = this.r.m.index + this.r.m[0].length;
		return this.r.s.substr(sz,this.r.s.length - sz);
	}
	,matchedLeft: function() {
		if(this.r.m == null) throw "No string matched";
		return this.r.s.substr(0,this.r.m.index);
	}
	,matched: function(n) {
		return this.r.m != null && n >= 0 && n < this.r.m.length?this.r.m[n]:(function($this) {
			var $r;
			throw "EReg::matched";
			return $r;
		}(this));
	}
	,match: function(s) {
		if(this.r.global) this.r.lastIndex = 0;
		this.r.m = this.r.exec(s);
		this.r.s = s;
		return this.r.m != null;
	}
	,r: null
	,__class__: EReg
}
var Hash = function() {
	this.h = { };
};
$hxClasses["Hash"] = Hash;
Hash.__name__ = ["Hash"];
Hash.prototype = {
	toString: function() {
		var s = new StringBuf();
		s.b += Std.string("{");
		var it = this.keys();
		while( it.hasNext() ) {
			var i = it.next();
			s.b += Std.string(i);
			s.b += Std.string(" => ");
			s.b += Std.string(Std.string(this.get(i)));
			if(it.hasNext()) s.b += Std.string(", ");
		}
		s.b += Std.string("}");
		return s.b;
	}
	,iterator: function() {
		return { ref : this.h, it : this.keys(), hasNext : function() {
			return this.it.hasNext();
		}, next : function() {
			var i = this.it.next();
			return this.ref["$" + i];
		}};
	}
	,keys: function() {
		var a = [];
		for( var key in this.h ) {
		if(this.h.hasOwnProperty(key)) a.push(key.substr(1));
		}
		return HxOverrides.iter(a);
	}
	,remove: function(key) {
		key = "$" + key;
		if(!this.h.hasOwnProperty(key)) return false;
		delete(this.h[key]);
		return true;
	}
	,exists: function(key) {
		return this.h.hasOwnProperty("$" + key);
	}
	,get: function(key) {
		return this.h["$" + key];
	}
	,set: function(key,value) {
		this.h["$" + key] = value;
	}
	,h: null
	,__class__: Hash
}
var HxOverrides = function() { }
$hxClasses["HxOverrides"] = HxOverrides;
HxOverrides.__name__ = ["HxOverrides"];
HxOverrides.dateStr = function(date) {
	var m = date.getMonth() + 1;
	var d = date.getDate();
	var h = date.getHours();
	var mi = date.getMinutes();
	var s = date.getSeconds();
	return date.getFullYear() + "-" + (m < 10?"0" + m:"" + m) + "-" + (d < 10?"0" + d:"" + d) + " " + (h < 10?"0" + h:"" + h) + ":" + (mi < 10?"0" + mi:"" + mi) + ":" + (s < 10?"0" + s:"" + s);
}
HxOverrides.strDate = function(s) {
	switch(s.length) {
	case 8:
		var k = s.split(":");
		var d = new Date();
		d.setTime(0);
		d.setUTCHours(k[0]);
		d.setUTCMinutes(k[1]);
		d.setUTCSeconds(k[2]);
		return d;
	case 10:
		var k = s.split("-");
		return new Date(k[0],k[1] - 1,k[2],0,0,0);
	case 19:
		var k = s.split(" ");
		var y = k[0].split("-");
		var t = k[1].split(":");
		return new Date(y[0],y[1] - 1,y[2],t[0],t[1],t[2]);
	default:
		throw "Invalid date format : " + s;
	}
}
HxOverrides.cca = function(s,index) {
	var x = s.charCodeAt(index);
	if(x != x) return undefined;
	return x;
}
HxOverrides.substr = function(s,pos,len) {
	if(pos != null && pos != 0 && len != null && len < 0) return "";
	if(len == null) len = s.length;
	if(pos < 0) {
		pos = s.length + pos;
		if(pos < 0) pos = 0;
	} else if(len < 0) len = s.length + len - pos;
	return s.substr(pos,len);
}
HxOverrides.remove = function(a,obj) {
	var i = 0;
	var l = a.length;
	while(i < l) {
		if(a[i] == obj) {
			a.splice(i,1);
			return true;
		}
		i++;
	}
	return false;
}
HxOverrides.iter = function(a) {
	return { cur : 0, arr : a, hasNext : function() {
		return this.cur < this.arr.length;
	}, next : function() {
		return this.arr[this.cur++];
	}};
}
var IntHash = function() {
	this.h = { };
};
$hxClasses["IntHash"] = IntHash;
IntHash.__name__ = ["IntHash"];
IntHash.prototype = {
	toString: function() {
		var s = new StringBuf();
		s.b += Std.string("{");
		var it = this.keys();
		while( it.hasNext() ) {
			var i = it.next();
			s.b += Std.string(i);
			s.b += Std.string(" => ");
			s.b += Std.string(Std.string(this.get(i)));
			if(it.hasNext()) s.b += Std.string(", ");
		}
		s.b += Std.string("}");
		return s.b;
	}
	,iterator: function() {
		return { ref : this.h, it : this.keys(), hasNext : function() {
			return this.it.hasNext();
		}, next : function() {
			var i = this.it.next();
			return this.ref[i];
		}};
	}
	,keys: function() {
		var a = [];
		for( var key in this.h ) {
		if(this.h.hasOwnProperty(key)) a.push(key | 0);
		}
		return HxOverrides.iter(a);
	}
	,remove: function(key) {
		if(!this.h.hasOwnProperty(key)) return false;
		delete(this.h[key]);
		return true;
	}
	,exists: function(key) {
		return this.h.hasOwnProperty(key);
	}
	,get: function(key) {
		return this.h[key];
	}
	,set: function(key,value) {
		this.h[key] = value;
	}
	,h: null
	,__class__: IntHash
}
var IntIter = function(min,max) {
	this.min = min;
	this.max = max;
};
$hxClasses["IntIter"] = IntIter;
IntIter.__name__ = ["IntIter"];
IntIter.prototype = {
	next: function() {
		return this.min++;
	}
	,hasNext: function() {
		return this.min < this.max;
	}
	,max: null
	,min: null
	,__class__: IntIter
}
var Interval = function(b,e) {
	this.b = b;
	this.e = e;
};
$hxClasses["Interval"] = Interval;
Interval.__name__ = ["Interval"];
Interval.prototype = {
	e: null
	,b: null
	,__class__: Interval
}
var Intervals = function() {
	this.elems = new Array();
};
$hxClasses["Intervals"] = Intervals;
Intervals.__name__ = ["Intervals"];
Intervals.prototype = {
	elems: null
	,from_array: function(a) {
		var _g = 0;
		while(_g < a.length) {
			var v = a[_g];
			++_g;
			this.add(v[0],v[1]);
		}
	}
	,to_array: function() {
		var a = [];
		var _g = 0, _g1 = this.elems;
		while(_g < _g1.length) {
			var v = _g1[_g];
			++_g;
			a.push([v.b,v.e]);
		}
		return a;
	}
	,print: function() {
		var s = "";
		var _g = 0, _g1 = this.elems;
		while(_g < _g1.length) {
			var v = _g1[_g];
			++_g;
			s += "" + v.b + "-" + v.e + " ";
		}
		console.log(s);
	}
	,add: function(b,e) {
		var _g = this;
		if(this.leq(e,b)) throw "arguments must be b <= e";
		if(b == e) return;
		var next = ArrayUtil.find_index(this.elems,function(r) {
			return _g.lt(b,r.b);
		});
		if(next == null) next = this.elems.length;
		var interval = new Interval(b,e);
		if(0 < next && this.leq(b,this.elems[next - 1].e)) {
			if(this.lt(this.elems[next - 1].e,e)) this.elems[next - 1].e = e;
		} else {
			this.elems.splice(next,0,interval);
			next++;
		}
		var base = this.elems[next - 1];
		var remove_last = next;
		while(remove_last < this.elems.length && this.leq(this.elems[remove_last].e,base.e)) remove_last++;
		if(next < remove_last) this.elems.splice(next,remove_last - next);
		if(next < this.elems.length) {
			if(this.leq(this.elems[next].b,base.e)) {
				base.e = this.elems[next].e;
				this.elems.splice(next,1);
			}
		}
	}
	,leq: function(x,y) {
		return x >= y;
	}
	,lt: function(x,y) {
		return x > y;
	}
	,__class__: Intervals
}
var Lambda = function() { }
$hxClasses["Lambda"] = Lambda;
Lambda.__name__ = ["Lambda"];
Lambda.array = function(it) {
	var a = new Array();
	var $it0 = $iterator(it)();
	while( $it0.hasNext() ) {
		var i = $it0.next();
		a.push(i);
	}
	return a;
}
Lambda.list = function(it) {
	var l = new List();
	var $it0 = $iterator(it)();
	while( $it0.hasNext() ) {
		var i = $it0.next();
		l.add(i);
	}
	return l;
}
Lambda.map = function(it,f) {
	var l = new List();
	var $it0 = $iterator(it)();
	while( $it0.hasNext() ) {
		var x = $it0.next();
		l.add(f(x));
	}
	return l;
}
Lambda.mapi = function(it,f) {
	var l = new List();
	var i = 0;
	var $it0 = $iterator(it)();
	while( $it0.hasNext() ) {
		var x = $it0.next();
		l.add(f(i++,x));
	}
	return l;
}
Lambda.has = function(it,elt,cmp) {
	if(cmp == null) {
		var $it0 = $iterator(it)();
		while( $it0.hasNext() ) {
			var x = $it0.next();
			if(x == elt) return true;
		}
	} else {
		var $it1 = $iterator(it)();
		while( $it1.hasNext() ) {
			var x = $it1.next();
			if(cmp(x,elt)) return true;
		}
	}
	return false;
}
Lambda.exists = function(it,f) {
	var $it0 = $iterator(it)();
	while( $it0.hasNext() ) {
		var x = $it0.next();
		if(f(x)) return true;
	}
	return false;
}
Lambda.foreach = function(it,f) {
	var $it0 = $iterator(it)();
	while( $it0.hasNext() ) {
		var x = $it0.next();
		if(!f(x)) return false;
	}
	return true;
}
Lambda.iter = function(it,f) {
	var $it0 = $iterator(it)();
	while( $it0.hasNext() ) {
		var x = $it0.next();
		f(x);
	}
}
Lambda.filter = function(it,f) {
	var l = new List();
	var $it0 = $iterator(it)();
	while( $it0.hasNext() ) {
		var x = $it0.next();
		if(f(x)) l.add(x);
	}
	return l;
}
Lambda.fold = function(it,f,first) {
	var $it0 = $iterator(it)();
	while( $it0.hasNext() ) {
		var x = $it0.next();
		first = f(x,first);
	}
	return first;
}
Lambda.count = function(it,pred) {
	var n = 0;
	if(pred == null) {
		var $it0 = $iterator(it)();
		while( $it0.hasNext() ) {
			var _ = $it0.next();
			n++;
		}
	} else {
		var $it1 = $iterator(it)();
		while( $it1.hasNext() ) {
			var x = $it1.next();
			if(pred(x)) n++;
		}
	}
	return n;
}
Lambda.empty = function(it) {
	return !$iterator(it)().hasNext();
}
Lambda.indexOf = function(it,v) {
	var i = 0;
	var $it0 = $iterator(it)();
	while( $it0.hasNext() ) {
		var v2 = $it0.next();
		if(v == v2) return i;
		i++;
	}
	return -1;
}
Lambda.concat = function(a,b) {
	var l = new List();
	var $it0 = $iterator(a)();
	while( $it0.hasNext() ) {
		var x = $it0.next();
		l.add(x);
	}
	var $it1 = $iterator(b)();
	while( $it1.hasNext() ) {
		var x = $it1.next();
		l.add(x);
	}
	return l;
}
var List = function() {
	this.length = 0;
};
$hxClasses["List"] = List;
List.__name__ = ["List"];
List.prototype = {
	map: function(f) {
		var b = new List();
		var l = this.h;
		while(l != null) {
			var v = l[0];
			l = l[1];
			b.add(f(v));
		}
		return b;
	}
	,filter: function(f) {
		var l2 = new List();
		var l = this.h;
		while(l != null) {
			var v = l[0];
			l = l[1];
			if(f(v)) l2.add(v);
		}
		return l2;
	}
	,join: function(sep) {
		var s = new StringBuf();
		var first = true;
		var l = this.h;
		while(l != null) {
			if(first) first = false; else s.b += Std.string(sep);
			s.b += Std.string(l[0]);
			l = l[1];
		}
		return s.b;
	}
	,toString: function() {
		var s = new StringBuf();
		var first = true;
		var l = this.h;
		s.b += Std.string("{");
		while(l != null) {
			if(first) first = false; else s.b += Std.string(", ");
			s.b += Std.string(Std.string(l[0]));
			l = l[1];
		}
		s.b += Std.string("}");
		return s.b;
	}
	,iterator: function() {
		return { h : this.h, hasNext : function() {
			return this.h != null;
		}, next : function() {
			if(this.h == null) return null;
			var x = this.h[0];
			this.h = this.h[1];
			return x;
		}};
	}
	,remove: function(v) {
		var prev = null;
		var l = this.h;
		while(l != null) {
			if(l[0] == v) {
				if(prev == null) this.h = l[1]; else prev[1] = l[1];
				if(this.q == l) this.q = prev;
				this.length--;
				return true;
			}
			prev = l;
			l = l[1];
		}
		return false;
	}
	,clear: function() {
		this.h = null;
		this.q = null;
		this.length = 0;
	}
	,isEmpty: function() {
		return this.h == null;
	}
	,pop: function() {
		if(this.h == null) return null;
		var x = this.h[0];
		this.h = this.h[1];
		if(this.h == null) this.q = null;
		this.length--;
		return x;
	}
	,last: function() {
		return this.q == null?null:this.q[0];
	}
	,first: function() {
		return this.h == null?null:this.h[0];
	}
	,push: function(item) {
		var x = [item,this.h];
		this.h = x;
		if(this.q == null) this.q = x;
		this.length++;
	}
	,add: function(item) {
		var x = [item];
		if(this.h == null) this.h = x; else this.q[1] = x;
		this.q = x;
		this.length++;
	}
	,length: null
	,q: null
	,h: null
	,__class__: List
}
var MyPage = function() { }
$hxClasses["MyPage"] = MyPage;
$hxExpose(MyPage, "MyPage");
MyPage.__name__ = ["MyPage"];
MyPage.connected = null;
MyPage.io = null;
MyPage.main = function() {
}
MyPage.testIt = function() {
}
MyPage.init = function() {
	new $("[timeline-id]").each(function(i,elem) {
		var timeline = new $(elem);
		MyPage.fillTimeline(timeline,null);
		if(!timeline["is"]("[editable=\"true\"]")) return;
		timeline.sortable({ handle : ".drag-handle", connectWith : "[timeline-id][editable=\"true\"]", update : function(event,ui) {
			if(ui.sender == null) {
				if(ui.item.parent()[0] == timeline[0]) {
					console.log("same timeline move");
					MyPage.moveArticle(ui.item);
				} else console.log("discard");
			} else {
				console.log("different timeline move");
				MyPage.transferArticle(ui.item,ui.sender);
			}
		}});
	});
	MyPage.startWatch();
}
MyPage.toggleComments = function(obj) {
	var entry = MyPage.getEntry(obj);
	var comments = entry.find("> .comments");
	if(comments["is"](":visible")) MyPage.closeComments(comments); else MyPage.openComments(comments);
	MyPage.updateCommentDisplayText(entry);
	MyPage.subscribeTimelines();
	MyPage.subscribePosts();
	MyPage.saveCommentsOpenStates();
}
MyPage.toggleCommentForm = function(obj) {
	var commentForm = MyPage.getEntry(obj).find("> .comment-form");
	commentForm.toggle();
	if(commentForm["is"](":visible")) {
		MyPage.scrollToElement(commentForm);
		commentForm.find("textarea").focus();
	}
	MyPage.saveCommentFormOpenStates();
}
MyPage.scrollToEntryTail = function(obj) {
	var entry = MyPage.getEntry(obj);
	MyPage.scrollToElement(entry);
	entry.find("> .comment-form").find("textarea").focus();
}
MyPage.postArticle = function(ribbonId,form) {
	$.ajax({ url : "/foo/ajax/m/newarticle", method : "post", data : { content : new $(form).find("[name=\"content\"]").val(), ribbon : ribbonId}}).done(function() {
	});
	form.find("[name=\"content\"]").val("");
	form.find("textarea").focus();
}
MyPage.postComment = function(ribbonId,timelineId,form) {
	$.ajax({ url : "/foo/ajax/m/newcomment", method : "post", data : { parent : new $(form).find("[name=\"parent\"]").val(), content : new $(form).find("[name=\"content\"]").val(), ribbon : ribbonId, timeline : timelineId}}).done(function() {
		MyPage.openComments(MyPage.getEntry(form).find("> .comments"));
		MyPage.saveCommentFormOpenStates();
	});
	form.find("[name=\"content\"]").val("");
	form.find("textarea").focus();
}
MyPage.favor = function(ribbonId,postId) {
	$.ajax({ url : "/foo/ajax/m/favor", method : "post", data : { ribbon : ribbonId, target : postId}});
}
MyPage.unfavor = function(ribbonId,postId) {
	$.ajax({ url : "/foo/ajax/m/unfavor", method : "post", data : { ribbon : ribbonId, target : postId}});
}
MyPage.continueReading = function(obj) {
	var e = new $(obj);
	var timeline = e.closest(".timeline");
	var newestScore = e.attr("newest-score");
	var oldestScore = MyPage.kickUndefined(e.attr("oldest-score"));
	MyPage.fetchTimeline(timeline,newestScore,oldestScore,null);
}
MyPage.chooseStamp = function(obj,ribbonId,timelineId) {
	var chooser = new $("#stamp-chooser");
	chooser.find("a").each(function(i,elem) {
		var e = new $(elem);
		e.unbind("click");
		e.click(function() {
			MyPage.postStamp(ribbonId,timelineId,new $(obj),new $(e));
			chooser.close();
		});
	});
	chooser.justModal();
}
MyPage.makeBoard = function() {
	var dialog = new $("#make-board");
	dialog.justModal();
}
MyPage.joinBoard = function() {
	var dialog = new $("#join-board");
	var userSelect = dialog.find("[name=\"user\"]");
	var boardSelect = dialog.find("[name=\"board\"]");
	var submit = dialog.find("[type=\"submit\"]");
	var username = MyPage.getUserName();
	var boardMenu = new $("#board-menu");
	var boardExists = function(boardId) {
		var options = boardMenu.find("[board-id=\"" + boardId + "\"]");
		return 0 < options.length;
	};
	boardSelect.val(0);
	MyPage.disable(boardSelect);
	MyPage.setupUserSelect(userSelect,function() {
		userSelect.find("option").each(function(i,elem) {
			var e = new $(elem);
			MyPage.setEnabled(e,e.attr("username") != MyPage.getUserName());
		});
	},function(userId) {
		MyPage.disable(submit);
		MyPage.clearSelect(boardSelect);
		if(userId == 0) return;
		MyPage.setupBoardSelect(boardSelect,userId,function(boardId) {
			return !boardExists(boardId);
		},function(boardId) {
			MyPage.setEnabled(submit,boardId != 0);
		});
	});
	dialog.justModal();
}
MyPage.makeRibbon = function() {
	var dialog = new $("#make-ribbon");
	dialog.justModal();
}
MyPage.joinRibbon = function(ownername) {
	var dialog = new $("#join-ribbon");
	var userSelect = dialog.find("[name=\"user\"]");
	var boardSelect = dialog.find("[name=\"board\"]");
	var ribbonSelect = dialog.find("[name=\"ribbon\"]");
	var submit = dialog.find("[type=\"submit\"]");
	var currentBoardId = MyPage.getBoardId();
	boardSelect.val(0);
	MyPage.disable(boardSelect);
	ribbonSelect.val(0);
	MyPage.disable(ribbonSelect);
	MyPage.setupUserSelect(userSelect,function() {
	},function(userId) {
		MyPage.disable(submit);
		MyPage.clearSelect(boardSelect);
		MyPage.clearSelect(ribbonSelect);
		if(userId == 0) return;
		MyPage.setupBoardSelect(boardSelect,userId,function(boardId) {
			return boardId != currentBoardId;
		},function(boardId) {
			MyPage.disable(submit);
			MyPage.clearSelect(ribbonSelect);
			if(boardId == 0) return;
			MyPage.setupRibbonSelect(ribbonSelect,boardId,true,function(ribbonId) {
				MyPage.setEnabled(submit,ribbonId != 0);
			});
		});
	});
	dialog.justModal();
}
MyPage.restoreRibbon = function(boardId) {
	var dialog = new $("#restore-ribbon");
	var ribbonSelect = dialog.find("[name=\"ribbon\"]");
	var submit = dialog.find("[type=\"submit\"]");
	MyPage.clearSelect(ribbonSelect);
	MyPage.setupRemovedRibbonSelect(ribbonSelect,boardId,true,function(ribbonId) {
		MyPage.setEnabled(submit,ribbonId != 0);
	});
	dialog.justModal();
}
MyPage.closeRibbon = function(obj,boardId) {
	var ribbon = new $(obj).closest(".ribbon");
	var ribbonId = ribbon.attr("ribbon-id");
	$.ajax({ url : "/foo/ajax/m/closeribbon", method : "post", data : { board : boardId, ribbon : ribbonId}}).done(function() {
		ribbon.closest(".ribbon-outer").remove();
	});
}
MyPage.editRibbonSettings = function(dialog,boardId,ribbonId) {
	MyPage.setupRadio(dialog,"read_permission");
	MyPage.setupRadio(dialog,"write_permission");
	MyPage.setupRadio(dialog,"edit_permission");
	MyPage.setupEditGroupButton(dialog.find("#edit-readable-group"));
	MyPage.setupEditGroupButton(dialog.find("#edit-writable-group"));
	MyPage.setupEditGroupButton(dialog.find("#edit-editable-group"));
	dialog.justModal();
}
MyPage.moveArticle = function(dragging) {
	var ribbonId = Std.parseInt(dragging.parent().attr("ribbon-id"));
	var postId = Std.parseInt(dragging.attr("post-id"));
	var target = dragging.next();
	console.log(target);
	var targetId = 0;
	if(0 < target.length && target["is"]("article")) targetId = target.attr("post-id");
	$.ajax({ url : "/foo/ajax/m/movearticle", method : "post", data : { ribbon : ribbonId, source : postId, target : targetId}}).done(function(data) {
		console.log("movearticle done");
	});
}
MyPage.transferArticle = function(dragging,sourceRibbon) {
	var sourceRibbonId = Std.parseInt(sourceRibbon.attr("ribbon-id"));
	var targetRibbon = dragging.parent();
	var targetRibbonId = Std.parseInt(targetRibbon.attr("ribbon-id"));
	var postId = Std.parseInt(dragging.attr("post-id"));
	var target = dragging.next();
	console.log(target);
	var targetId = 0;
	if(0 < target.length && target["is"]("article")) targetId = target.attr("post-id");
	$.ajax({ url : "/foo/ajax/m/transferarticle", method : "post", data : { source_ribbon : sourceRibbonId, target_ribbon : targetRibbonId, source : postId, target : targetId}}).done(function(data) {
		console.log("movearticle done");
	});
}
MyPage.doPost = function(obj) {
	MyPage.postForm(MyPage.getForm(obj),function(s) {
		MyPage.redirect(MyPage.makeBoardUrl(s[0],s[1]));
	});
	return false;
}
MyPage.doRibbonTest = function(ribbonId) {
	$.ajax({ url : "/foo/ajax/m/ribbontest", method : "post", data : { ribbon : ribbonId}}).done(function(data) {
		console.log("ribbontest done");
	});
}
MyPage.editBoardSettings = function() {
	var dialog = new $("#board-settings");
	MyPage.setupRadio(dialog,"read_permission");
	MyPage.setupRadio(dialog,"write_permission");
	MyPage.setupRadio(dialog,"edit_permission");
	MyPage.setupEditGroupButton(dialog.find("#edit-readable-group"));
	MyPage.setupEditGroupButton(dialog.find("#edit-writable-group"));
	MyPage.setupEditGroupButton(dialog.find("#edit-editable-group"));
	dialog.justModal();
}
MyPage.setupEditGroupButton = function(button) {
	MyPage.updateStatus(button,["active","loaded"],"loaded",false);
	var groupId = Std.parseInt(button.attr("group-id"));
	var storeName = button.attr("store");
	var displayId = button.attr("display");
	var form = button.closest("form");
	var store = form.find("[name=\"" + storeName + "\"]");
	var display = form.find("#" + displayId);
	$.ajax({ url : "/foo/ajax/v/group", method : "get", data : { group : groupId}, dataType : "jsonp"}).done(function(data) {
		MyPage.updateStatus(button,["active","loaded"],"loaded",true);
		MyPage.updateGroupStore(store,data);
		MyPage.updateGroupDisplay(display,data);
		button.unbind("click");
		button.click(function(e) {
			MyPage.editGroup(data,function(data1) {
				MyPage.updateGroupStore(store,data1);
				MyPage.updateGroupDisplay(display,data1);
			});
			return false;
		});
	});
}
MyPage.updateGroupStore = function(store,data) {
	var memberSet = [];
	var members = data.members;
	var _g = 0;
	while(_g < members.length) {
		var v = members[_g];
		++_g;
		memberSet.push(v.userId);
	}
	console.log(memberSet);
	memberSet.sort(function(a,b) {
		return a - b;
	});
	console.log(memberSet);
	store.val(JSON.stringify(memberSet));
}
MyPage.updateGroupDisplay = function(display,data) {
	var members = data.members;
	display.html("");
	if(members.length == 0) display.html("<p>ユーザが含まれていません</p>"); else {
		var _g = 0;
		while(_g < members.length) {
			var v = members[_g];
			++_g;
			display.append(MyPage.gravatar(v.gravatar,16,v.userId,v.username,v.label));
		}
	}
	display.find("img").tooltip();
	var memberSet = [];
	var _g = 0;
	while(_g < members.length) {
		var v = members[_g];
		++_g;
		memberSet.push(v.userId);
	}
	memberSet.sort(function(a,b) {
		return a - b;
	});
	display.attr("member-set",JSON.stringify(memberSet));
}
MyPage.editGroup = function(data,cb) {
	var dialog = new $("#edit-group");
	var display = dialog.find(".group-members");
	var submit = dialog.find("input:submit");
	submit.unbind("click");
	submit.click(function() {
		cb(data);
		dialog.close();
		return false;
	});
	MyPage.updateGroupDisplay(display,data);
	var oldMemberSet = display.attr("member-set");
	var groupName = dialog.find("[name=\"group_name\"]");
	groupName.val(data.name);
	MyPage.setEnabled(groupName,data.nameEditable);
	var userSelect = dialog.find("[name=\"user\"]");
	var updateUI = function() {
		userSelect.val(0);
		userSelect.find("option").each(function(i,elem) {
			var e = new $(elem);
			var userId = e.attr("user-id");
			var filter = "[user-id=\"" + userId + "\"]";
			MyPage.setEnabled(e,display.find(filter).length == 0);
		});
	};
	var addButton = dialog.find("#add-member");
	MyPage.disable(addButton);
	MyPage.setupUserSelect(userSelect,function() {
		updateUI();
	},function(userId) {
		MyPage.setEnabled(addButton,userId != 0);
	});
	addButton.unbind("click");
	addButton.click(function() {
		display.find("p").remove("");
		var s = userSelect.find(":selected");
		var member = { userId : Std.parseInt(s.attr("user-id")), username : s.attr("username"), label : s.attr("label"), gravatar : s.attr("icon")};
		data.members.push(member);
		MyPage.updateGroupDisplay(display,data);
		updateUI();
		MyPage.setEnabled(submit,oldMemberSet != display.attr("member-set"));
	});
	updateUI();
	dialog.justModal({ overlayZIndex : 20050, modalZIndex : 20100});
}
MyPage.makeBoardUrl = function(username,boardname) {
	var urlinfo = new $("#basic-data");
	var base_url = urlinfo.attr("base-url");
	return "" + base_url + "/" + username + "/" + boardname;
}
MyPage.getUserName = function() {
	return MyPage.getBasicDataAttr("username");
}
MyPage.getOwnerName = function() {
	return MyPage.getBasicDataAttr("owner-name");
}
MyPage.getReferedName = function() {
	return MyPage.getBasicDataAttr("refered-name");
}
MyPage.getBoardId = function() {
	return Std.parseInt(MyPage.getBasicDataAttr("board-id"));
}
MyPage.getBasicDataAttr = function(a) {
	var data = new $("#basic-data");
	return data.attr(a);
}
MyPage.postForm = function(form,f) {
	$.ajax({ url : form.attr("action"), method : form.attr("method"), data : form.serialize(), dataType : "jsonp"}).done(function(data) {
		f(data);
	});
}
MyPage.enable = function(e) {
	e.removeAttr("disabled");
}
MyPage.disable = function(e) {
	e.attr("disabled","disabled");
}
MyPage.setEnabled = function(e,f) {
	if(f) MyPage.enable(e); else MyPage.disable(e);
}
MyPage.setupUserSelect = function(userSelect,onLoad,onChange) {
	MyPage.disable(userSelect);
	MyPage.clearSelect(userSelect);
	$.ajax({ url : "/foo/ajax/v/userlist", method : "get"}).done(function(data) {
		userSelect.append("<option value=\"0\">所有者を選択</option>");
		var users = $.parseJSON(data);
		var _g = 0;
		while(_g < users.length) {
			var v = users[_g];
			++_g;
			var userId = v[0];
			var username = v[1];
			var userLabel = v[2];
			var userIcon = v[3];
			userSelect.append("<option value=\"" + userId + "\" user-id=\"" + userId + "\" username=\"" + username + "\" label=\"" + userLabel + "\" icon=\"" + userIcon + "\">" + username + " - " + userLabel + "</option>");
		}
		userSelect.unbind("change");
		userSelect.change(function(e) {
			onChange(MyPage.getSelected(e.target).val());
		});
		MyPage.enable(userSelect);
		onLoad();
	});
}
MyPage.setupBoardSelect = function(boardSelect,userId,filter,onChange) {
	$.ajax({ url : "/foo/ajax/v/boardlist?user=" + userId, method : "get"}).done(function(data) {
		boardSelect.append("<option value=\"0\">ボードを選択</option>");
		var boards = $.parseJSON(data);
		var _g = 0;
		while(_g < boards.length) {
			var v = boards[_g];
			++_g;
			var boardId = v.boardId;
			var boardlabel = v.label;
			var disabled = filter(boardId)?"":" disabled=\"disabled\"";
			boardSelect.append("<option value=\"" + boardId + "\"" + disabled + ">" + boardlabel + "</option>");
		}
		boardSelect.unbind("change");
		boardSelect.change(function(e) {
			onChange(MyPage.getSelected(e.target).val());
		});
		MyPage.enable(boardSelect);
	});
}
MyPage.setupRibbonSelect = function(ribbonSelect,boardId,disableDup,f) {
	$.ajax({ url : "/foo/ajax/v/ribbonlist?board=" + boardId, method : "get"}).done(function(data) {
		ribbonSelect.append("<option value=\"0\">リボンを選択</option>");
		var ribbons = $.parseJSON(data);
		var _g = 0;
		while(_g < ribbons.length) {
			var v = ribbons[_g];
			++_g;
			var ribbonId = v.ribbonId;
			var ribbonLabel = v.label;
			var disabled = "";
			if(disableDup && 0 < new $("[ribbon-id=\"" + ribbonId + "\"]").length) disabled = " disabled=\"disabled\"";
			ribbonSelect.append("<option value=\"" + ribbonId + "\"" + disabled + ">" + ribbonLabel + "</option>");
		}
		ribbonSelect.unbind("change");
		ribbonSelect.change(function(e) {
			f(MyPage.getSelected(e.target).val());
		});
		MyPage.enable(ribbonSelect);
	});
}
MyPage.setupRemovedRibbonSelect = function(ribbonSelect,boardId,disableDup,f) {
	$.ajax({ url : "/foo/ajax/v/removedribbonlist?board=" + boardId, method : "get"}).done(function(data) {
		ribbonSelect.append("<option value=\"0\">リボンを選択</option>");
		var ribbons = $.parseJSON(data);
		var _g = 0;
		while(_g < ribbons.length) {
			var v = ribbons[_g];
			++_g;
			var ribbonId = v[0];
			var ribbonLabel = v[1];
			ribbonSelect.append("<option value=\"" + ribbonId + "\">" + ribbonLabel + "</option>");
		}
		ribbonSelect.unbind("change");
		ribbonSelect.change(function(e) {
			f(MyPage.getSelected(e.target).val());
		});
		MyPage.enable(ribbonSelect);
	});
}
MyPage.postStamp = function(ribbonId,timelineId,source,selected) {
	var form = source.closest(".comment-form").find("> form");
	var image = selected.attr("image");
	$.ajax({ url : "/foo/ajax/m/stamp", method : "post", data : { ribbon : ribbonId, timeline : timelineId, parent : form.find("[name=\"parent\"]").val(), content : image}}).done(function() {
		MyPage.openComments(MyPage.getEntry(form).find("> .comments"));
		MyPage.saveCommentFormOpenStates();
	});
}
MyPage.fillTimeline = function(timeline,version) {
	MyPage.fetchTimeline(timeline,null,null,version);
}
MyPage.fillNewerTimeline = function(timeline,version) {
	var newestScore = 0;
	timeline.children().each(function(i,elem) {
		var e = new $(elem);
		var score = Std.parseInt(e.attr("score"));
		if(newestScore < score) newestScore = score;
	});
	MyPage.fetchTimeline(timeline,null,newestScore,version);
}
MyPage.fetchTimeline = function(oldTimeline,newestScore,oldestScore,version) {
	var ribbonId = Std.parseInt(oldTimeline.attr("ribbon-id"));
	var timelineId = Std.parseInt(oldTimeline.attr("timeline-id"));
	var level = Std.parseInt(oldTimeline.attr("level"));
	var writable = oldTimeline.attr("writable") == "true";
	if(!MyPage.startLoad(oldTimeline,version)) return;
	$.ajax({ url : "/foo/ajax/v/timeline", data : { ribbon : ribbonId, timeline : timelineId, newest_score : MyPage.kickUndefined(newestScore), oldest_score : MyPage.kickUndefined(oldestScore), count : 3}, dataType : "jsonp"}).done(function(data) {
		data.level = level;
		var posts = data.posts;
		var _g = 0;
		while(_g < posts.length) {
			var post = posts[_g];
			++_g;
			post.detail = MyPage.formatDetail(post.detail,writable);
		}
		data.intervals = "[[" + Std.string(data.newestScore) + ", " + Std.string(data.oldestScore) + "]]";
		MyPage.finishLoad(oldTimeline,function() {
			var output = MyPage.applyTemplate("Timeline",data);
			var entry = MyPage.getEntry(oldTimeline);
			var newTimeline = new $(output);
			MyPage.mergeTimeline(oldTimeline,newTimeline);
			if(level == 0) MyPage.loadOpenStates(); else MyPage.subscribePosts();
		});
	});
}
MyPage.traceTimeline = function(timeline) {
	timeline.find("> article").each(function(i,elem) {
		console.log(elem);
	});
}
MyPage.mergeTimeline = function(oldTimeline,newTimeline) {
	if(newTimeline.children().length == 0) {
		MyPage.setupNoArticle(oldTimeline);
		return;
	}
	oldTimeline.find("> .continue-reading").remove();
	console.log("new");
	MyPage.traceTimeline(newTimeline);
	var remover = newTimeline.find("> article[removed=\"true\"]");
	console.log("remover");
	remover.each(function(i,elem) {
		console.log(elem);
	});
	console.log("old(before applying remover)");
	MyPage.traceTimeline(oldTimeline);
	remover.each(function(i,elem) {
		var e = new $(elem);
		var postId = e.attr("post-id");
		var filter = "[post-id=\"" + postId + "\"]";
		console.log(filter);
		newTimeline.find(filter).addClass("removing");
		oldTimeline.find(filter).addClass("removing");
	});
	newTimeline.find(".removing").remove();
	oldTimeline.find(".removing").remove();
	console.log("old(before)");
	MyPage.traceTimeline(oldTimeline);
	newTimeline.children().each(function(i,elem) {
		var e = new $(elem);
		var postId = e.attr("post-id");
		oldTimeline.find("[post-id=" + postId + "]").addClass("removing");
	});
	oldTimeline.find(".removing").remove();
	var oe = oldTimeline.children().eq(0);
	var ne = newTimeline.children().eq(0);
	while(0 < oe.length && 0 < ne.length) {
		var oldScore = Std.parseInt(oe.attr("score"));
		var newScore = null;
		while(0 < ne.length && oldScore <= (newScore = Std.parseInt(ne.attr("score")))) {
			var newPostId = Std.parseInt(ne.attr("post-id"));
			var oldPostId = Std.parseInt(oe.attr("post-id"));
			console.log("judge newPost: " + newPostId);
			var next_ne = ne.next();
			ne.insertBefore(oe);
			ne = next_ne;
		}
		oe = oe.next();
	}
	if(0 < ne.length) {
		var nextne = ne.nextAll();
		oldTimeline.append(ne);
		oldTimeline.append(nextne);
	}
	var intervals = new Intervals();
	var oldTimelineIntervalsAttr = oldTimeline.attr("intervals");
	if(MyPage.kickUndefined(oldTimelineIntervalsAttr) != null) intervals.from_array($.parseJSON(oldTimelineIntervalsAttr));
	console.log("newTimeline intervals");
	console.log(newTimeline.attr("intervals"));
	var tmpIntervalArray = $.parseJSON(newTimeline.attr("intervals"));
	var _g = 0;
	while(_g < tmpIntervalArray.length) {
		var v = tmpIntervalArray[_g];
		++_g;
		intervals.add(v[0],v[1]);
	}
	var _g = 0, _g1 = intervals.elems;
	while(_g < _g1.length) {
		var v = _g1[_g];
		++_g;
		if(v.e != 0) MyPage.insertContinueReading(oldTimeline,v.e);
	}
	oldTimeline.attr("intervals",JSON.stringify(intervals.to_array()));
	console.log("old(after)");
	MyPage.traceTimeline(oldTimeline);
	MyPage.setupDragHandles(oldTimeline);
	MyPage.setupNoArticle(oldTimeline);
}
MyPage.setupDragHandles = function(timeline) {
	if(!timeline["is"]("[editable=\"true\"]")) return;
	var articles = timeline.find("> .post");
	articles.find("> .avatar").addClass("drag-handle");
	articles.find("> .entry > .detail").addClass("drag-handle");
}
MyPage.setupNoArticle = function(timeline) {
	timeline.find("> .no-article").remove();
	if(timeline.find("> article").length == 0) timeline.append("<div class=\"no-article\">ポストがありません</div>");
}
MyPage.insertContinueReading = function(timeline,score) {
	var link = new $("<a class=\"continue-reading\" href=\"#\" onclick=\"MyPage.continueReading(this);return false;\">続きを読む</a>");
	link.attr("newest-score",score);
	var a = timeline.children().get();
	var _g = 0;
	while(_g < a.length) {
		var v = a[_g];
		++_g;
		var oldScore = Std.parseInt(new $(v).attr("score"));
		if(oldScore < score) {
			link.attr("oldest-score",oldScore);
			link.insertBefore(v);
			return;
		}
	}
	timeline.append(link);
}
MyPage.saveCommentsOpenStates = function() {
	MyPage.saveOpenStatesAux("comments");
}
MyPage.saveCommentFormOpenStates = function() {
	MyPage.saveOpenStatesAux("comment-form");
}
MyPage.saveOpenStatesAux = function(label) {
	var a = new $("." + label + ":visible").map(function(i,elem) {
		return Std.parseInt(MyPage.getTimelineIdFromEntryContent(elem));
	});
	js.Cookie.set(label,JSON.stringify(a.get()),7);
}
MyPage.loadOpenStates = function() {
	MyPage.loadOpenStatesAux("comments",function(e) {
		MyPage.openComments(e);
	});
	MyPage.loadOpenStatesAux("comment-form",function(e) {
		e.show();
	});
	MyPage.subscribeTimelines();
	MyPage.subscribePosts();
}
MyPage.loadOpenStatesAux = function(label,f) {
	var cookie = MyPage.kickUndefined(js.Cookie.get(label));
	if(cookie == null) return;
	var rawOpened = $.parseJSON(cookie);
	var opened = new Hash();
	var _g = 0;
	while(_g < rawOpened.length) {
		var v = rawOpened[_g];
		++_g;
		opened.set(Std.string(v),v);
	}
	new $("." + label).each(function(i,elem) {
		var e = new $(elem);
		var timelineId = MyPage.getTimelineIdFromEntryContent(e);
		if(opened.exists(timelineId)) f(e);
	});
}
MyPage.getTimelineIdFromEntryContent = function(e) {
	return MyPage.getEntry(e).find("> .comments > .timeline").attr("timeline-id");
}
MyPage.startLoad = function(timeline,version) {
	if(timeline.attr("loading") != null) {
		var oldWaiting = MyPage.kickUndefined(timeline.attr("waiting"));
		if(version != null && oldWaiting == null || Std.parseInt(oldWaiting) < version) timeline.attr("waiting",version);
		return false;
	}
	if(version != null) {
		if(version <= Std.parseInt(timeline.attr("version"))) return false;
	}
	timeline.attr("loading","true");
	return true;
}
MyPage.finishLoad = function(timeline,f) {
	timeline.removeAttr("loading");
	var waitingVersion = timeline.attr("waiting");
	timeline.removeAttr("waiting");
	f();
	if(waitingVersion != null) MyPage.fillNewerTimeline(timeline,Std.parseInt(waitingVersion));
}
MyPage.scrollToElement = function(e) {
	var window = new $(js.Lib.window);
	var document = new $(js.Lib.document);
	var bottomMargin = 32;
	var target = e.offset().top - window.height() + e.height() + bottomMargin;
	if(document.scrollTop() < target) document.scrollTop(target);
}
MyPage.getEntry = function(obj) {
	var e = new $(obj);
	if(e["is"](".entry")) return e; else return e.closest(".entry");
}
MyPage.getForm = function(obj) {
	var e = new $(obj);
	if(e["is"]("form")) return e; else return e.closest("form");
}
MyPage.updateCommentDisplayText = function(entry) {
	var comments = entry.find("> .comments");
	var showComment = entry.find("> .operation .show-comment-label");
	if(comments["is"](":visible")) showComment.html("隠す"); else {
		var count = entry.find("> .detail").attr("comment-count");
		showComment.html("×" + count);
	}
}
MyPage.subscribeTimelines = function() {
	if(MyPage.connected) {
		var targets = new $("[timeline-id]:visible").map(function(i,e) {
			return Std.parseInt(new $(e).attr("timeline-id"));
		});
		MyPage.io.push("watch-timeline",{ targets : targets.get()});
	}
}
MyPage.subscribePosts = function() {
	if(MyPage.connected) {
		var targets = new $("[post-id]:visible").map(function(i,e) {
			return Std.parseInt(new $(e).attr("post-id"));
		});
		MyPage.io.push("watch-post",{ targets : targets.get()});
	}
}
MyPage.loadTimeline = function(timelineId,version) {
	new $("[timeline-id=\"" + timelineId + "\"]").each(function(i,elem) {
		MyPage.fillNewerTimeline(new $(elem),version);
	});
}
MyPage.loadDetail = function(postId,version) {
	var posts = new $("[post-id=\"" + postId + "\"]");
	posts.each(function(i,e) {
		var post = new $(e);
		var ribbonId = post.closest(".ribbon").attr("ribbon-id");
		var writable = post.closest(".timeline").attr("writable") == "true";
		var level = Std.parseInt(post.parent().attr("level"));
		$.ajax({ url : "/foo/ajax/v/detail", data : { ribbon : ribbonId, post : postId, level : level}, dataType : "jsonp"}).done(function(data) {
			var output = MyPage.formatDetail(data,writable);
			var entry = post.find("> .entry");
			entry.find("> .detail").replaceWith(output);
			MyPage.updateCommentDisplayText(entry);
		});
	});
}
MyPage.formatDetail = function(detail,writable) {
	var favoredBy = "";
	var srcFavoredBy = detail.favoredBy;
	var _g = 0;
	while(_g < srcFavoredBy.length) {
		var vv = srcFavoredBy[_g];
		++_g;
		favoredBy += MyPage.gravatar(vv,16);
	}
	detail.favoredBy = favoredBy;
	detail.elapsed = MyPage.elapsedInWords(detail.elapsed);
	detail.writable = writable;
	console.log(detail.writable);
	console.log(detail.userExists);
	console.log(detail.postType);
	return MyPage.applyTemplate("Detail",detail);
}
MyPage.applyTemplate = function(codename,data) {
	var templateCode = haxe.Resource.getString(codename);
	var template = new haxe.Template(templateCode);
	return template.execute(data);
}
MyPage.startWatch = function() {
	MyPage.io = new RocketIO().connect();
	MyPage.io.on("connect",function(session) {
		MyPage.connected = true;
		MyPage.subscribeTimelines();
		MyPage.subscribePosts();
	});
	MyPage.io.on("watch-timeline",function(data) {
		MyPage.loadTimeline(data.timeline,data.version);
	});
	MyPage.io.on("watch-post",function(data) {
		MyPage.loadDetail(data.post,data.version);
	});
}
MyPage.openComments = function(comments) {
	comments.show();
	var n = MyPage.getEntry(comments).find("> .detail").attr("comments-version");
	if(n != null) {
		var idealVersion = Std.parseInt(n);
		var timeline = comments.find("> .timeline");
		MyPage.fillNewerTimeline(timeline,idealVersion);
	}
}
MyPage.closeComments = function(comments) {
	comments.hide();
}
MyPage.redirect = function(url) {
	js.Lib.window.location.href = url;
}
MyPage.getThis = function() {
	return this;
}
MyPage.isUndefined = function(x) {
	return "undefined" === typeof x;
}
MyPage.kickUndefined = function(x) {
	if(MyPage.isUndefined(x)) return null;
	return x;
}
MyPage.getSelected = function(select) {
	return new $(select).find(":selected");
}
MyPage.clearSelect = function(select) {
	MyPage.disable(select);
	select.html("");
}
MyPage.setupRadio = function(root,name) {
	var radios = root.find("[name=\"" + name + "\"]");
	var onChange = function() {
		radios.each(function(i,elem) {
			var radio = new $(elem);
			var label = radio.closest("label.radio");
			var inputs = label.find("input:not(:radio),select");
			var checked = radio["is"](":checked");
			MyPage.updateStatus(inputs,["active","loaded"],"active",checked);
		});
		return true;
	};
	onChange();
	radios.unbind("change");
	radios.change(onChange);
}
MyPage.updateStatus = function(all,statuses,s,f) {
	if(f) all.addClass(s); else all.removeClass(s);
	all.each(function(i,elem) {
		var e = new $(elem);
		var _g = 0;
		while(_g < statuses.length) {
			var s1 = statuses[_g];
			++_g;
			if(!e.hasClass(s1)) {
				MyPage.disable(e);
				return;
			}
		}
		MyPage.enable(e);
	});
}
MyPage.elapsedInWords = function(elapsedInSeconds) {
	if(elapsedInSeconds <= 10) return "今"; else if(elapsedInSeconds < 60) return "" + elapsedInSeconds + "秒前";
	var elapsedInMinutes = Math.round(elapsedInSeconds / 60);
	if(elapsedInMinutes < 60) return "" + elapsedInMinutes + "分前";
	var elapsedInHours = Math.round(elapsedInMinutes / 60);
	if(elapsedInHours < 24) return "" + elapsedInHours + "時間前";
	var elapsedInDays = Math.round(elapsedInHours / 24);
	if(elapsedInDays < 30) return "" + elapsedInDays + "日前";
	var elapsedInMonths = Math.round(elapsedInDays / 30);
	if(elapsedInMonths < 12) return "" + elapsedInMonths + "ヶ月前";
	var elapsedInYears = Math.round(elapsedInMonths / 12);
	return "" + elapsedInYears + "年前";
}
MyPage.gravatar = function(hash,size,userId,username,label) {
	if(label == null) label = "";
	if(username == null) username = "";
	if(userId == null) userId = 0;
	return "<img src=\"http://www.gravatar.com/avatar/" + hash + "?s=" + size + "&d=mm\" alt=\"gravatar\" user-id=\"" + userId + "\" username=\"" + username + "\" title=\"" + label + "\" data-toggle=\"tooltip\"/>";
}
var Reflect = function() { }
$hxClasses["Reflect"] = Reflect;
Reflect.__name__ = ["Reflect"];
Reflect.hasField = function(o,field) {
	return Object.prototype.hasOwnProperty.call(o,field);
}
Reflect.field = function(o,field) {
	var v = null;
	try {
		v = o[field];
	} catch( e ) {
	}
	return v;
}
Reflect.setField = function(o,field,value) {
	o[field] = value;
}
Reflect.getProperty = function(o,field) {
	var tmp;
	return o == null?null:o.__properties__ && (tmp = o.__properties__["get_" + field])?o[tmp]():o[field];
}
Reflect.setProperty = function(o,field,value) {
	var tmp;
	if(o.__properties__ && (tmp = o.__properties__["set_" + field])) o[tmp](value); else o[field] = value;
}
Reflect.callMethod = function(o,func,args) {
	return func.apply(o,args);
}
Reflect.fields = function(o) {
	var a = [];
	if(o != null) {
		var hasOwnProperty = Object.prototype.hasOwnProperty;
		for( var f in o ) {
		if(hasOwnProperty.call(o,f)) a.push(f);
		}
	}
	return a;
}
Reflect.isFunction = function(f) {
	return typeof(f) == "function" && !(f.__name__ || f.__ename__);
}
Reflect.compare = function(a,b) {
	return a == b?0:a > b?1:-1;
}
Reflect.compareMethods = function(f1,f2) {
	if(f1 == f2) return true;
	if(!Reflect.isFunction(f1) || !Reflect.isFunction(f2)) return false;
	return f1.scope == f2.scope && f1.method == f2.method && f1.method != null;
}
Reflect.isObject = function(v) {
	if(v == null) return false;
	var t = typeof(v);
	return t == "string" || t == "object" && !v.__enum__ || t == "function" && (v.__name__ || v.__ename__);
}
Reflect.deleteField = function(o,f) {
	if(!Reflect.hasField(o,f)) return false;
	delete(o[f]);
	return true;
}
Reflect.copy = function(o) {
	var o2 = { };
	var _g = 0, _g1 = Reflect.fields(o);
	while(_g < _g1.length) {
		var f = _g1[_g];
		++_g;
		o2[f] = Reflect.field(o,f);
	}
	return o2;
}
Reflect.makeVarArgs = function(f) {
	return function() {
		var a = Array.prototype.slice.call(arguments);
		return f(a);
	};
}
var Std = function() { }
$hxClasses["Std"] = Std;
Std.__name__ = ["Std"];
Std["is"] = function(v,t) {
	return js.Boot.__instanceof(v,t);
}
Std.string = function(s) {
	return js.Boot.__string_rec(s,"");
}
Std["int"] = function(x) {
	return x | 0;
}
Std.parseInt = function(x) {
	var v = parseInt(x,10);
	if(v == 0 && (HxOverrides.cca(x,1) == 120 || HxOverrides.cca(x,1) == 88)) v = parseInt(x);
	if(isNaN(v)) return null;
	return v;
}
Std.parseFloat = function(x) {
	return parseFloat(x);
}
Std.random = function(x) {
	return Math.floor(Math.random() * x);
}
var StringBuf = function() {
	this.b = "";
};
$hxClasses["StringBuf"] = StringBuf;
StringBuf.__name__ = ["StringBuf"];
StringBuf.prototype = {
	toString: function() {
		return this.b;
	}
	,addSub: function(s,pos,len) {
		this.b += HxOverrides.substr(s,pos,len);
	}
	,addChar: function(c) {
		this.b += String.fromCharCode(c);
	}
	,add: function(x) {
		this.b += Std.string(x);
	}
	,b: null
	,__class__: StringBuf
}
var StringTools = function() { }
$hxClasses["StringTools"] = StringTools;
StringTools.__name__ = ["StringTools"];
StringTools.urlEncode = function(s) {
	return encodeURIComponent(s);
}
StringTools.urlDecode = function(s) {
	return decodeURIComponent(s.split("+").join(" "));
}
StringTools.htmlEscape = function(s) {
	return s.split("&").join("&amp;").split("<").join("&lt;").split(">").join("&gt;");
}
StringTools.htmlUnescape = function(s) {
	return s.split("&gt;").join(">").split("&lt;").join("<").split("&amp;").join("&");
}
StringTools.startsWith = function(s,start) {
	return s.length >= start.length && HxOverrides.substr(s,0,start.length) == start;
}
StringTools.endsWith = function(s,end) {
	var elen = end.length;
	var slen = s.length;
	return slen >= elen && HxOverrides.substr(s,slen - elen,elen) == end;
}
StringTools.isSpace = function(s,pos) {
	var c = HxOverrides.cca(s,pos);
	return c >= 9 && c <= 13 || c == 32;
}
StringTools.ltrim = function(s) {
	var l = s.length;
	var r = 0;
	while(r < l && StringTools.isSpace(s,r)) r++;
	if(r > 0) return HxOverrides.substr(s,r,l - r); else return s;
}
StringTools.rtrim = function(s) {
	var l = s.length;
	var r = 0;
	while(r < l && StringTools.isSpace(s,l - r - 1)) r++;
	if(r > 0) return HxOverrides.substr(s,0,l - r); else return s;
}
StringTools.trim = function(s) {
	return StringTools.ltrim(StringTools.rtrim(s));
}
StringTools.rpad = function(s,c,l) {
	var sl = s.length;
	var cl = c.length;
	while(sl < l) if(l - sl < cl) {
		s += HxOverrides.substr(c,0,l - sl);
		sl = l;
	} else {
		s += c;
		sl += cl;
	}
	return s;
}
StringTools.lpad = function(s,c,l) {
	var ns = "";
	var sl = s.length;
	if(sl >= l) return s;
	var cl = c.length;
	while(sl < l) if(l - sl < cl) {
		ns += HxOverrides.substr(c,0,l - sl);
		sl = l;
	} else {
		ns += c;
		sl += cl;
	}
	return ns + s;
}
StringTools.replace = function(s,sub,by) {
	return s.split(sub).join(by);
}
StringTools.hex = function(n,digits) {
	var s = "";
	var hexChars = "0123456789ABCDEF";
	do {
		s = hexChars.charAt(n & 15) + s;
		n >>>= 4;
	} while(n > 0);
	if(digits != null) while(s.length < digits) s = "0" + s;
	return s;
}
StringTools.fastCodeAt = function(s,index) {
	return s.charCodeAt(index);
}
StringTools.isEOF = function(c) {
	return c != c;
}
var ValueType = $hxClasses["ValueType"] = { __ename__ : ["ValueType"], __constructs__ : ["TNull","TInt","TFloat","TBool","TObject","TFunction","TClass","TEnum","TUnknown"] }
ValueType.TNull = ["TNull",0];
ValueType.TNull.toString = $estr;
ValueType.TNull.__enum__ = ValueType;
ValueType.TInt = ["TInt",1];
ValueType.TInt.toString = $estr;
ValueType.TInt.__enum__ = ValueType;
ValueType.TFloat = ["TFloat",2];
ValueType.TFloat.toString = $estr;
ValueType.TFloat.__enum__ = ValueType;
ValueType.TBool = ["TBool",3];
ValueType.TBool.toString = $estr;
ValueType.TBool.__enum__ = ValueType;
ValueType.TObject = ["TObject",4];
ValueType.TObject.toString = $estr;
ValueType.TObject.__enum__ = ValueType;
ValueType.TFunction = ["TFunction",5];
ValueType.TFunction.toString = $estr;
ValueType.TFunction.__enum__ = ValueType;
ValueType.TClass = function(c) { var $x = ["TClass",6,c]; $x.__enum__ = ValueType; $x.toString = $estr; return $x; }
ValueType.TEnum = function(e) { var $x = ["TEnum",7,e]; $x.__enum__ = ValueType; $x.toString = $estr; return $x; }
ValueType.TUnknown = ["TUnknown",8];
ValueType.TUnknown.toString = $estr;
ValueType.TUnknown.__enum__ = ValueType;
var Type = function() { }
$hxClasses["Type"] = Type;
Type.__name__ = ["Type"];
Type.getClass = function(o) {
	if(o == null) return null;
	return o.__class__;
}
Type.getEnum = function(o) {
	if(o == null) return null;
	return o.__enum__;
}
Type.getSuperClass = function(c) {
	return c.__super__;
}
Type.getClassName = function(c) {
	var a = c.__name__;
	return a.join(".");
}
Type.getEnumName = function(e) {
	var a = e.__ename__;
	return a.join(".");
}
Type.resolveClass = function(name) {
	var cl = $hxClasses[name];
	if(cl == null || !cl.__name__) return null;
	return cl;
}
Type.resolveEnum = function(name) {
	var e = $hxClasses[name];
	if(e == null || !e.__ename__) return null;
	return e;
}
Type.createInstance = function(cl,args) {
	switch(args.length) {
	case 0:
		return new cl();
	case 1:
		return new cl(args[0]);
	case 2:
		return new cl(args[0],args[1]);
	case 3:
		return new cl(args[0],args[1],args[2]);
	case 4:
		return new cl(args[0],args[1],args[2],args[3]);
	case 5:
		return new cl(args[0],args[1],args[2],args[3],args[4]);
	case 6:
		return new cl(args[0],args[1],args[2],args[3],args[4],args[5]);
	case 7:
		return new cl(args[0],args[1],args[2],args[3],args[4],args[5],args[6]);
	case 8:
		return new cl(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7]);
	default:
		throw "Too many arguments";
	}
	return null;
}
Type.createEmptyInstance = function(cl) {
	function empty() {}; empty.prototype = cl.prototype;
	return new empty();
}
Type.createEnum = function(e,constr,params) {
	var f = Reflect.field(e,constr);
	if(f == null) throw "No such constructor " + constr;
	if(Reflect.isFunction(f)) {
		if(params == null) throw "Constructor " + constr + " need parameters";
		return f.apply(e,params);
	}
	if(params != null && params.length != 0) throw "Constructor " + constr + " does not need parameters";
	return f;
}
Type.createEnumIndex = function(e,index,params) {
	var c = e.__constructs__[index];
	if(c == null) throw index + " is not a valid enum constructor index";
	return Type.createEnum(e,c,params);
}
Type.getInstanceFields = function(c) {
	var a = [];
	for(var i in c.prototype) a.push(i);
	HxOverrides.remove(a,"__class__");
	HxOverrides.remove(a,"__properties__");
	return a;
}
Type.getClassFields = function(c) {
	var a = Reflect.fields(c);
	HxOverrides.remove(a,"__name__");
	HxOverrides.remove(a,"__interfaces__");
	HxOverrides.remove(a,"__properties__");
	HxOverrides.remove(a,"__super__");
	HxOverrides.remove(a,"prototype");
	return a;
}
Type.getEnumConstructs = function(e) {
	var a = e.__constructs__;
	return a.slice();
}
Type["typeof"] = function(v) {
	switch(typeof(v)) {
	case "boolean":
		return ValueType.TBool;
	case "string":
		return ValueType.TClass(String);
	case "number":
		if(Math.ceil(v) == v % 2147483648.0) return ValueType.TInt;
		return ValueType.TFloat;
	case "object":
		if(v == null) return ValueType.TNull;
		var e = v.__enum__;
		if(e != null) return ValueType.TEnum(e);
		var c = v.__class__;
		if(c != null) return ValueType.TClass(c);
		return ValueType.TObject;
	case "function":
		if(v.__name__ || v.__ename__) return ValueType.TObject;
		return ValueType.TFunction;
	case "undefined":
		return ValueType.TNull;
	default:
		return ValueType.TUnknown;
	}
}
Type.enumEq = function(a,b) {
	if(a == b) return true;
	try {
		if(a[0] != b[0]) return false;
		var _g1 = 2, _g = a.length;
		while(_g1 < _g) {
			var i = _g1++;
			if(!Type.enumEq(a[i],b[i])) return false;
		}
		var e = a.__enum__;
		if(e != b.__enum__ || e == null) return false;
	} catch( e ) {
		return false;
	}
	return true;
}
Type.enumConstructor = function(e) {
	return e[0];
}
Type.enumParameters = function(e) {
	return e.slice(2);
}
Type.enumIndex = function(e) {
	return e[1];
}
Type.allEnums = function(e) {
	var all = [];
	var cst = e.__constructs__;
	var _g = 0;
	while(_g < cst.length) {
		var c = cst[_g];
		++_g;
		var v = Reflect.field(e,c);
		if(!Reflect.isFunction(v)) all.push(v);
	}
	return all;
}
var haxe = {}
haxe.Resource = function() { }
$hxClasses["haxe.Resource"] = haxe.Resource;
haxe.Resource.__name__ = ["haxe","Resource"];
haxe.Resource.content = null;
haxe.Resource.listNames = function() {
	var names = new Array();
	var _g = 0, _g1 = haxe.Resource.content;
	while(_g < _g1.length) {
		var x = _g1[_g];
		++_g;
		names.push(x.name);
	}
	return names;
}
haxe.Resource.getString = function(name) {
	var _g = 0, _g1 = haxe.Resource.content;
	while(_g < _g1.length) {
		var x = _g1[_g];
		++_g;
		if(x.name == name) {
			if(x.str != null) return x.str;
			var b = haxe.Unserializer.run(x.data);
			return b.toString();
		}
	}
	return null;
}
haxe.Resource.getBytes = function(name) {
	var _g = 0, _g1 = haxe.Resource.content;
	while(_g < _g1.length) {
		var x = _g1[_g];
		++_g;
		if(x.name == name) {
			if(x.str != null) return haxe.io.Bytes.ofString(x.str);
			return haxe.Unserializer.run(x.data);
		}
	}
	return null;
}
haxe._Template = {}
haxe._Template.TemplateExpr = $hxClasses["haxe._Template.TemplateExpr"] = { __ename__ : ["haxe","_Template","TemplateExpr"], __constructs__ : ["OpVar","OpExpr","OpIf","OpStr","OpBlock","OpForeach","OpMacro"] }
haxe._Template.TemplateExpr.OpVar = function(v) { var $x = ["OpVar",0,v]; $x.__enum__ = haxe._Template.TemplateExpr; $x.toString = $estr; return $x; }
haxe._Template.TemplateExpr.OpExpr = function(expr) { var $x = ["OpExpr",1,expr]; $x.__enum__ = haxe._Template.TemplateExpr; $x.toString = $estr; return $x; }
haxe._Template.TemplateExpr.OpIf = function(expr,eif,eelse) { var $x = ["OpIf",2,expr,eif,eelse]; $x.__enum__ = haxe._Template.TemplateExpr; $x.toString = $estr; return $x; }
haxe._Template.TemplateExpr.OpStr = function(str) { var $x = ["OpStr",3,str]; $x.__enum__ = haxe._Template.TemplateExpr; $x.toString = $estr; return $x; }
haxe._Template.TemplateExpr.OpBlock = function(l) { var $x = ["OpBlock",4,l]; $x.__enum__ = haxe._Template.TemplateExpr; $x.toString = $estr; return $x; }
haxe._Template.TemplateExpr.OpForeach = function(expr,loop) { var $x = ["OpForeach",5,expr,loop]; $x.__enum__ = haxe._Template.TemplateExpr; $x.toString = $estr; return $x; }
haxe._Template.TemplateExpr.OpMacro = function(name,params) { var $x = ["OpMacro",6,name,params]; $x.__enum__ = haxe._Template.TemplateExpr; $x.toString = $estr; return $x; }
haxe.Template = function(str) {
	var tokens = this.parseTokens(str);
	this.expr = this.parseBlock(tokens);
	if(!tokens.isEmpty()) throw "Unexpected '" + Std.string(tokens.first().s) + "'";
};
$hxClasses["haxe.Template"] = haxe.Template;
haxe.Template.__name__ = ["haxe","Template"];
haxe.Template.prototype = {
	run: function(e) {
		var $e = (e);
		switch( $e[1] ) {
		case 0:
			var v = $e[2];
			this.buf.b += Std.string(Std.string(this.resolve(v)));
			break;
		case 1:
			var e1 = $e[2];
			this.buf.b += Std.string(Std.string(e1()));
			break;
		case 2:
			var eelse = $e[4], eif = $e[3], e1 = $e[2];
			var v = e1();
			if(v == null || v == false) {
				if(eelse != null) this.run(eelse);
			} else this.run(eif);
			break;
		case 3:
			var str = $e[2];
			this.buf.b += Std.string(str);
			break;
		case 4:
			var l = $e[2];
			var $it0 = l.iterator();
			while( $it0.hasNext() ) {
				var e1 = $it0.next();
				this.run(e1);
			}
			break;
		case 5:
			var loop = $e[3], e1 = $e[2];
			var v = e1();
			try {
				var x = $iterator(v)();
				if(x.hasNext == null) throw null;
				v = x;
			} catch( e2 ) {
				try {
					if(v.hasNext == null) throw null;
				} catch( e3 ) {
					throw "Cannot iter on " + Std.string(v);
				}
			}
			this.stack.push(this.context);
			var v1 = v;
			while( v1.hasNext() ) {
				var ctx = v1.next();
				this.context = ctx;
				this.run(loop);
			}
			this.context = this.stack.pop();
			break;
		case 6:
			var params = $e[3], m = $e[2];
			var v = Reflect.field(this.macros,m);
			var pl = new Array();
			var old = this.buf;
			pl.push($bind(this,this.resolve));
			var $it1 = params.iterator();
			while( $it1.hasNext() ) {
				var p = $it1.next();
				var $e = (p);
				switch( $e[1] ) {
				case 0:
					var v1 = $e[2];
					pl.push(this.resolve(v1));
					break;
				default:
					this.buf = new StringBuf();
					this.run(p);
					pl.push(this.buf.b);
				}
			}
			this.buf = old;
			try {
				this.buf.b += Std.string(Std.string(v.apply(this.macros,pl)));
			} catch( e1 ) {
				var plstr = (function($this) {
					var $r;
					try {
						$r = pl.join(",");
					} catch( e2 ) {
						$r = "???";
					}
					return $r;
				}(this));
				var msg = "Macro call " + m + "(" + plstr + ") failed (" + Std.string(e1) + ")";
				throw msg;
			}
			break;
		}
	}
	,makeExpr2: function(l) {
		var p = l.pop();
		if(p == null) throw "<eof>";
		if(p.s) return this.makeConst(p.p);
		switch(p.p) {
		case "(":
			var e1 = this.makeExpr(l);
			var p1 = l.pop();
			if(p1 == null || p1.s) throw p1.p;
			if(p1.p == ")") return e1;
			var e2 = this.makeExpr(l);
			var p2 = l.pop();
			if(p2 == null || p2.p != ")") throw p2.p;
			return (function($this) {
				var $r;
				switch(p1.p) {
				case "+":
					$r = function() {
						return e1() + e2();
					};
					break;
				case "-":
					$r = function() {
						return e1() - e2();
					};
					break;
				case "*":
					$r = function() {
						return e1() * e2();
					};
					break;
				case "/":
					$r = function() {
						return e1() / e2();
					};
					break;
				case ">":
					$r = function() {
						return e1() > e2();
					};
					break;
				case "<":
					$r = function() {
						return e1() < e2();
					};
					break;
				case ">=":
					$r = function() {
						return e1() >= e2();
					};
					break;
				case "<=":
					$r = function() {
						return e1() <= e2();
					};
					break;
				case "==":
					$r = function() {
						return e1() == e2();
					};
					break;
				case "!=":
					$r = function() {
						return e1() != e2();
					};
					break;
				case "&&":
					$r = function() {
						return e1() && e2();
					};
					break;
				case "||":
					$r = function() {
						return e1() || e2();
					};
					break;
				default:
					$r = (function($this) {
						var $r;
						throw "Unknown operation " + p1.p;
						return $r;
					}($this));
				}
				return $r;
			}(this));
		case "!":
			var e = this.makeExpr(l);
			return function() {
				var v = e();
				return v == null || v == false;
			};
		case "-":
			var e = this.makeExpr(l);
			return function() {
				return -e();
			};
		}
		throw p.p;
	}
	,makeExpr: function(l) {
		return this.makePath(this.makeExpr2(l),l);
	}
	,makePath: function(e,l) {
		var p = l.first();
		if(p == null || p.p != ".") return e;
		l.pop();
		var field = l.pop();
		if(field == null || !field.s) throw field.p;
		var f = field.p;
		haxe.Template.expr_trim.match(f);
		f = haxe.Template.expr_trim.matched(1);
		return this.makePath(function() {
			return Reflect.field(e(),f);
		},l);
	}
	,makeConst: function(v) {
		haxe.Template.expr_trim.match(v);
		v = haxe.Template.expr_trim.matched(1);
		if(HxOverrides.cca(v,0) == 34) {
			var str = HxOverrides.substr(v,1,v.length - 2);
			return function() {
				return str;
			};
		}
		if(haxe.Template.expr_int.match(v)) {
			var i = Std.parseInt(v);
			return function() {
				return i;
			};
		}
		if(haxe.Template.expr_float.match(v)) {
			var f = Std.parseFloat(v);
			return function() {
				return f;
			};
		}
		var me = this;
		return function() {
			return me.resolve(v);
		};
	}
	,parseExpr: function(data) {
		var l = new List();
		var expr = data;
		while(haxe.Template.expr_splitter.match(data)) {
			var p = haxe.Template.expr_splitter.matchedPos();
			var k = p.pos + p.len;
			if(p.pos != 0) l.add({ p : HxOverrides.substr(data,0,p.pos), s : true});
			var p1 = haxe.Template.expr_splitter.matched(0);
			l.add({ p : p1, s : p1.indexOf("\"") >= 0});
			data = haxe.Template.expr_splitter.matchedRight();
		}
		if(data.length != 0) l.add({ p : data, s : true});
		var e;
		try {
			e = this.makeExpr(l);
			if(!l.isEmpty()) throw l.first().p;
		} catch( s ) {
			if( js.Boot.__instanceof(s,String) ) {
				throw "Unexpected '" + s + "' in " + expr;
			} else throw(s);
		}
		return function() {
			try {
				return e();
			} catch( exc ) {
				throw "Error : " + Std.string(exc) + " in " + expr;
			}
		};
	}
	,parse: function(tokens) {
		var t = tokens.pop();
		var p = t.p;
		if(t.s) return haxe._Template.TemplateExpr.OpStr(p);
		if(t.l != null) {
			var pe = new List();
			var _g = 0, _g1 = t.l;
			while(_g < _g1.length) {
				var p1 = _g1[_g];
				++_g;
				pe.add(this.parseBlock(this.parseTokens(p1)));
			}
			return haxe._Template.TemplateExpr.OpMacro(p,pe);
		}
		if(HxOverrides.substr(p,0,3) == "if ") {
			p = HxOverrides.substr(p,3,p.length - 3);
			var e = this.parseExpr(p);
			var eif = this.parseBlock(tokens);
			var t1 = tokens.first();
			var eelse;
			if(t1 == null) throw "Unclosed 'if'";
			if(t1.p == "end") {
				tokens.pop();
				eelse = null;
			} else if(t1.p == "else") {
				tokens.pop();
				eelse = this.parseBlock(tokens);
				t1 = tokens.pop();
				if(t1 == null || t1.p != "end") throw "Unclosed 'else'";
			} else {
				t1.p = HxOverrides.substr(t1.p,4,t1.p.length - 4);
				eelse = this.parse(tokens);
			}
			return haxe._Template.TemplateExpr.OpIf(e,eif,eelse);
		}
		if(HxOverrides.substr(p,0,8) == "foreach ") {
			p = HxOverrides.substr(p,8,p.length - 8);
			var e = this.parseExpr(p);
			var efor = this.parseBlock(tokens);
			var t1 = tokens.pop();
			if(t1 == null || t1.p != "end") throw "Unclosed 'foreach'";
			return haxe._Template.TemplateExpr.OpForeach(e,efor);
		}
		if(haxe.Template.expr_splitter.match(p)) return haxe._Template.TemplateExpr.OpExpr(this.parseExpr(p));
		return haxe._Template.TemplateExpr.OpVar(p);
	}
	,parseBlock: function(tokens) {
		var l = new List();
		while(true) {
			var t = tokens.first();
			if(t == null) break;
			if(!t.s && (t.p == "end" || t.p == "else" || HxOverrides.substr(t.p,0,7) == "elseif ")) break;
			l.add(this.parse(tokens));
		}
		if(l.length == 1) return l.first();
		return haxe._Template.TemplateExpr.OpBlock(l);
	}
	,parseTokens: function(data) {
		var tokens = new List();
		while(haxe.Template.splitter.match(data)) {
			var p = haxe.Template.splitter.matchedPos();
			if(p.pos > 0) tokens.add({ p : HxOverrides.substr(data,0,p.pos), s : true, l : null});
			if(HxOverrides.cca(data,p.pos) == 58) {
				tokens.add({ p : HxOverrides.substr(data,p.pos + 2,p.len - 4), s : false, l : null});
				data = haxe.Template.splitter.matchedRight();
				continue;
			}
			var parp = p.pos + p.len;
			var npar = 1;
			while(npar > 0) {
				var c = HxOverrides.cca(data,parp);
				if(c == 40) npar++; else if(c == 41) npar--; else if(c == null) throw "Unclosed macro parenthesis";
				parp++;
			}
			var params = HxOverrides.substr(data,p.pos + p.len,parp - (p.pos + p.len) - 1).split(",");
			tokens.add({ p : haxe.Template.splitter.matched(2), s : false, l : params});
			data = HxOverrides.substr(data,parp,data.length - parp);
		}
		if(data.length > 0) tokens.add({ p : data, s : true, l : null});
		return tokens;
	}
	,resolve: function(v) {
		if(Reflect.hasField(this.context,v)) return Reflect.field(this.context,v);
		var $it0 = this.stack.iterator();
		while( $it0.hasNext() ) {
			var ctx = $it0.next();
			if(Reflect.hasField(ctx,v)) return Reflect.field(ctx,v);
		}
		if(v == "__current__") return this.context;
		return Reflect.field(haxe.Template.globals,v);
	}
	,execute: function(context,macros) {
		this.macros = macros == null?{ }:macros;
		this.context = context;
		this.stack = new List();
		this.buf = new StringBuf();
		this.run(this.expr);
		return this.buf.b;
	}
	,buf: null
	,stack: null
	,macros: null
	,context: null
	,expr: null
	,__class__: haxe.Template
}
haxe.Unserializer = function(buf) {
	this.buf = buf;
	this.length = buf.length;
	this.pos = 0;
	this.scache = new Array();
	this.cache = new Array();
	var r = haxe.Unserializer.DEFAULT_RESOLVER;
	if(r == null) {
		r = Type;
		haxe.Unserializer.DEFAULT_RESOLVER = r;
	}
	this.setResolver(r);
};
$hxClasses["haxe.Unserializer"] = haxe.Unserializer;
haxe.Unserializer.__name__ = ["haxe","Unserializer"];
haxe.Unserializer.initCodes = function() {
	var codes = new Array();
	var _g1 = 0, _g = haxe.Unserializer.BASE64.length;
	while(_g1 < _g) {
		var i = _g1++;
		codes[haxe.Unserializer.BASE64.charCodeAt(i)] = i;
	}
	return codes;
}
haxe.Unserializer.run = function(v) {
	return new haxe.Unserializer(v).unserialize();
}
haxe.Unserializer.prototype = {
	unserialize: function() {
		switch(this.buf.charCodeAt(this.pos++)) {
		case 110:
			return null;
		case 116:
			return true;
		case 102:
			return false;
		case 122:
			return 0;
		case 105:
			return this.readDigits();
		case 100:
			var p1 = this.pos;
			while(true) {
				var c = this.buf.charCodeAt(this.pos);
				if(c >= 43 && c < 58 || c == 101 || c == 69) this.pos++; else break;
			}
			return Std.parseFloat(HxOverrides.substr(this.buf,p1,this.pos - p1));
		case 121:
			var len = this.readDigits();
			if(this.buf.charCodeAt(this.pos++) != 58 || this.length - this.pos < len) throw "Invalid string length";
			var s = HxOverrides.substr(this.buf,this.pos,len);
			this.pos += len;
			s = StringTools.urlDecode(s);
			this.scache.push(s);
			return s;
		case 107:
			return Math.NaN;
		case 109:
			return Math.NEGATIVE_INFINITY;
		case 112:
			return Math.POSITIVE_INFINITY;
		case 97:
			var buf = this.buf;
			var a = new Array();
			this.cache.push(a);
			while(true) {
				var c = this.buf.charCodeAt(this.pos);
				if(c == 104) {
					this.pos++;
					break;
				}
				if(c == 117) {
					this.pos++;
					var n = this.readDigits();
					a[a.length + n - 1] = null;
				} else a.push(this.unserialize());
			}
			return a;
		case 111:
			var o = { };
			this.cache.push(o);
			this.unserializeObject(o);
			return o;
		case 114:
			var n = this.readDigits();
			if(n < 0 || n >= this.cache.length) throw "Invalid reference";
			return this.cache[n];
		case 82:
			var n = this.readDigits();
			if(n < 0 || n >= this.scache.length) throw "Invalid string reference";
			return this.scache[n];
		case 120:
			throw this.unserialize();
			break;
		case 99:
			var name = this.unserialize();
			var cl = this.resolver.resolveClass(name);
			if(cl == null) throw "Class not found " + name;
			var o = Type.createEmptyInstance(cl);
			this.cache.push(o);
			this.unserializeObject(o);
			return o;
		case 119:
			var name = this.unserialize();
			var edecl = this.resolver.resolveEnum(name);
			if(edecl == null) throw "Enum not found " + name;
			var e = this.unserializeEnum(edecl,this.unserialize());
			this.cache.push(e);
			return e;
		case 106:
			var name = this.unserialize();
			var edecl = this.resolver.resolveEnum(name);
			if(edecl == null) throw "Enum not found " + name;
			this.pos++;
			var index = this.readDigits();
			var tag = Type.getEnumConstructs(edecl)[index];
			if(tag == null) throw "Unknown enum index " + name + "@" + index;
			var e = this.unserializeEnum(edecl,tag);
			this.cache.push(e);
			return e;
		case 108:
			var l = new List();
			this.cache.push(l);
			var buf = this.buf;
			while(this.buf.charCodeAt(this.pos) != 104) l.add(this.unserialize());
			this.pos++;
			return l;
		case 98:
			var h = new Hash();
			this.cache.push(h);
			var buf = this.buf;
			while(this.buf.charCodeAt(this.pos) != 104) {
				var s = this.unserialize();
				h.set(s,this.unserialize());
			}
			this.pos++;
			return h;
		case 113:
			var h = new IntHash();
			this.cache.push(h);
			var buf = this.buf;
			var c = this.buf.charCodeAt(this.pos++);
			while(c == 58) {
				var i = this.readDigits();
				h.set(i,this.unserialize());
				c = this.buf.charCodeAt(this.pos++);
			}
			if(c != 104) throw "Invalid IntHash format";
			return h;
		case 118:
			var d = HxOverrides.strDate(HxOverrides.substr(this.buf,this.pos,19));
			this.cache.push(d);
			this.pos += 19;
			return d;
		case 115:
			var len = this.readDigits();
			var buf = this.buf;
			if(this.buf.charCodeAt(this.pos++) != 58 || this.length - this.pos < len) throw "Invalid bytes length";
			var codes = haxe.Unserializer.CODES;
			if(codes == null) {
				codes = haxe.Unserializer.initCodes();
				haxe.Unserializer.CODES = codes;
			}
			var i = this.pos;
			var rest = len & 3;
			var size = (len >> 2) * 3 + (rest >= 2?rest - 1:0);
			var max = i + (len - rest);
			var bytes = haxe.io.Bytes.alloc(size);
			var bpos = 0;
			while(i < max) {
				var c1 = codes[buf.charCodeAt(i++)];
				var c2 = codes[buf.charCodeAt(i++)];
				bytes.b[bpos++] = (c1 << 2 | c2 >> 4) & 255;
				var c3 = codes[buf.charCodeAt(i++)];
				bytes.b[bpos++] = (c2 << 4 | c3 >> 2) & 255;
				var c4 = codes[buf.charCodeAt(i++)];
				bytes.b[bpos++] = (c3 << 6 | c4) & 255;
			}
			if(rest >= 2) {
				var c1 = codes[buf.charCodeAt(i++)];
				var c2 = codes[buf.charCodeAt(i++)];
				bytes.b[bpos++] = (c1 << 2 | c2 >> 4) & 255;
				if(rest == 3) {
					var c3 = codes[buf.charCodeAt(i++)];
					bytes.b[bpos++] = (c2 << 4 | c3 >> 2) & 255;
				}
			}
			this.pos += len;
			this.cache.push(bytes);
			return bytes;
		case 67:
			var name = this.unserialize();
			var cl = this.resolver.resolveClass(name);
			if(cl == null) throw "Class not found " + name;
			var o = Type.createEmptyInstance(cl);
			this.cache.push(o);
			o.hxUnserialize(this);
			if(this.buf.charCodeAt(this.pos++) != 103) throw "Invalid custom data";
			return o;
		default:
		}
		this.pos--;
		throw "Invalid char " + this.buf.charAt(this.pos) + " at position " + this.pos;
	}
	,unserializeEnum: function(edecl,tag) {
		if(this.buf.charCodeAt(this.pos++) != 58) throw "Invalid enum format";
		var nargs = this.readDigits();
		if(nargs == 0) return Type.createEnum(edecl,tag);
		var args = new Array();
		while(nargs-- > 0) args.push(this.unserialize());
		return Type.createEnum(edecl,tag,args);
	}
	,unserializeObject: function(o) {
		while(true) {
			if(this.pos >= this.length) throw "Invalid object";
			if(this.buf.charCodeAt(this.pos) == 103) break;
			var k = this.unserialize();
			if(!js.Boot.__instanceof(k,String)) throw "Invalid object key";
			var v = this.unserialize();
			o[k] = v;
		}
		this.pos++;
	}
	,readDigits: function() {
		var k = 0;
		var s = false;
		var fpos = this.pos;
		while(true) {
			var c = this.buf.charCodeAt(this.pos);
			if(c != c) break;
			if(c == 45) {
				if(this.pos != fpos) break;
				s = true;
				this.pos++;
				continue;
			}
			if(c < 48 || c > 57) break;
			k = k * 10 + (c - 48);
			this.pos++;
		}
		if(s) k *= -1;
		return k;
	}
	,get: function(p) {
		return this.buf.charCodeAt(p);
	}
	,getResolver: function() {
		return this.resolver;
	}
	,setResolver: function(r) {
		if(r == null) this.resolver = { resolveClass : function(_) {
			return null;
		}, resolveEnum : function(_) {
			return null;
		}}; else this.resolver = r;
	}
	,resolver: null
	,scache: null
	,cache: null
	,length: null
	,pos: null
	,buf: null
	,__class__: haxe.Unserializer
}
haxe.io = {}
haxe.io.Bytes = function(length,b) {
	this.length = length;
	this.b = b;
};
$hxClasses["haxe.io.Bytes"] = haxe.io.Bytes;
haxe.io.Bytes.__name__ = ["haxe","io","Bytes"];
haxe.io.Bytes.alloc = function(length) {
	var a = new Array();
	var _g = 0;
	while(_g < length) {
		var i = _g++;
		a.push(0);
	}
	return new haxe.io.Bytes(length,a);
}
haxe.io.Bytes.ofString = function(s) {
	var a = new Array();
	var _g1 = 0, _g = s.length;
	while(_g1 < _g) {
		var i = _g1++;
		var c = s.charCodeAt(i);
		if(c <= 127) a.push(c); else if(c <= 2047) {
			a.push(192 | c >> 6);
			a.push(128 | c & 63);
		} else if(c <= 65535) {
			a.push(224 | c >> 12);
			a.push(128 | c >> 6 & 63);
			a.push(128 | c & 63);
		} else {
			a.push(240 | c >> 18);
			a.push(128 | c >> 12 & 63);
			a.push(128 | c >> 6 & 63);
			a.push(128 | c & 63);
		}
	}
	return new haxe.io.Bytes(a.length,a);
}
haxe.io.Bytes.ofData = function(b) {
	return new haxe.io.Bytes(b.length,b);
}
haxe.io.Bytes.prototype = {
	getData: function() {
		return this.b;
	}
	,toHex: function() {
		var s = new StringBuf();
		var chars = [];
		var str = "0123456789abcdef";
		var _g1 = 0, _g = str.length;
		while(_g1 < _g) {
			var i = _g1++;
			chars.push(HxOverrides.cca(str,i));
		}
		var _g1 = 0, _g = this.length;
		while(_g1 < _g) {
			var i = _g1++;
			var c = this.b[i];
			s.b += String.fromCharCode(chars[c >> 4]);
			s.b += String.fromCharCode(chars[c & 15]);
		}
		return s.b;
	}
	,toString: function() {
		return this.readString(0,this.length);
	}
	,readString: function(pos,len) {
		if(pos < 0 || len < 0 || pos + len > this.length) throw haxe.io.Error.OutsideBounds;
		var s = "";
		var b = this.b;
		var fcc = String.fromCharCode;
		var i = pos;
		var max = pos + len;
		while(i < max) {
			var c = b[i++];
			if(c < 128) {
				if(c == 0) break;
				s += fcc(c);
			} else if(c < 224) s += fcc((c & 63) << 6 | b[i++] & 127); else if(c < 240) {
				var c2 = b[i++];
				s += fcc((c & 31) << 12 | (c2 & 127) << 6 | b[i++] & 127);
			} else {
				var c2 = b[i++];
				var c3 = b[i++];
				s += fcc((c & 15) << 18 | (c2 & 127) << 12 | c3 << 6 & 127 | b[i++] & 127);
			}
		}
		return s;
	}
	,compare: function(other) {
		var b1 = this.b;
		var b2 = other.b;
		var len = this.length < other.length?this.length:other.length;
		var _g = 0;
		while(_g < len) {
			var i = _g++;
			if(b1[i] != b2[i]) return b1[i] - b2[i];
		}
		return this.length - other.length;
	}
	,sub: function(pos,len) {
		if(pos < 0 || len < 0 || pos + len > this.length) throw haxe.io.Error.OutsideBounds;
		return new haxe.io.Bytes(len,this.b.slice(pos,pos + len));
	}
	,blit: function(pos,src,srcpos,len) {
		if(pos < 0 || srcpos < 0 || len < 0 || pos + len > this.length || srcpos + len > src.length) throw haxe.io.Error.OutsideBounds;
		var b1 = this.b;
		var b2 = src.b;
		if(b1 == b2 && pos > srcpos) {
			var i = len;
			while(i > 0) {
				i--;
				b1[i + pos] = b2[i + srcpos];
			}
			return;
		}
		var _g = 0;
		while(_g < len) {
			var i = _g++;
			b1[i + pos] = b2[i + srcpos];
		}
	}
	,set: function(pos,v) {
		this.b[pos] = v & 255;
	}
	,get: function(pos) {
		return this.b[pos];
	}
	,b: null
	,length: null
	,__class__: haxe.io.Bytes
}
haxe.io.Error = $hxClasses["haxe.io.Error"] = { __ename__ : ["haxe","io","Error"], __constructs__ : ["Blocked","Overflow","OutsideBounds","Custom"] }
haxe.io.Error.Blocked = ["Blocked",0];
haxe.io.Error.Blocked.toString = $estr;
haxe.io.Error.Blocked.__enum__ = haxe.io.Error;
haxe.io.Error.Overflow = ["Overflow",1];
haxe.io.Error.Overflow.toString = $estr;
haxe.io.Error.Overflow.__enum__ = haxe.io.Error;
haxe.io.Error.OutsideBounds = ["OutsideBounds",2];
haxe.io.Error.OutsideBounds.toString = $estr;
haxe.io.Error.OutsideBounds.__enum__ = haxe.io.Error;
haxe.io.Error.Custom = function(e) { var $x = ["Custom",3,e]; $x.__enum__ = haxe.io.Error; $x.toString = $estr; return $x; }
var js = {}
js.Boot = function() { }
$hxClasses["js.Boot"] = js.Boot;
js.Boot.__name__ = ["js","Boot"];
js.Boot.__unhtml = function(s) {
	return s.split("&").join("&amp;").split("<").join("&lt;").split(">").join("&gt;");
}
js.Boot.__trace = function(v,i) {
	var msg = i != null?i.fileName + ":" + i.lineNumber + ": ":"";
	msg += js.Boot.__string_rec(v,"");
	var d;
	if(typeof(document) != "undefined" && (d = document.getElementById("haxe:trace")) != null) d.innerHTML += js.Boot.__unhtml(msg) + "<br/>"; else if(typeof(console) != "undefined" && console.log != null) console.log(msg);
}
js.Boot.__clear_trace = function() {
	var d = document.getElementById("haxe:trace");
	if(d != null) d.innerHTML = "";
}
js.Boot.isClass = function(o) {
	return o.__name__;
}
js.Boot.isEnum = function(e) {
	return e.__ename__;
}
js.Boot.getClass = function(o) {
	return o.__class__;
}
js.Boot.__string_rec = function(o,s) {
	if(o == null) return "null";
	if(s.length >= 5) return "<...>";
	var t = typeof(o);
	if(t == "function" && (o.__name__ || o.__ename__)) t = "object";
	switch(t) {
	case "object":
		if(o instanceof Array) {
			if(o.__enum__) {
				if(o.length == 2) return o[0];
				var str = o[0] + "(";
				s += "\t";
				var _g1 = 2, _g = o.length;
				while(_g1 < _g) {
					var i = _g1++;
					if(i != 2) str += "," + js.Boot.__string_rec(o[i],s); else str += js.Boot.__string_rec(o[i],s);
				}
				return str + ")";
			}
			var l = o.length;
			var i;
			var str = "[";
			s += "\t";
			var _g = 0;
			while(_g < l) {
				var i1 = _g++;
				str += (i1 > 0?",":"") + js.Boot.__string_rec(o[i1],s);
			}
			str += "]";
			return str;
		}
		var tostr;
		try {
			tostr = o.toString;
		} catch( e ) {
			return "???";
		}
		if(tostr != null && tostr != Object.toString) {
			var s2 = o.toString();
			if(s2 != "[object Object]") return s2;
		}
		var k = null;
		var str = "{\n";
		s += "\t";
		var hasp = o.hasOwnProperty != null;
		for( var k in o ) { ;
		if(hasp && !o.hasOwnProperty(k)) {
			continue;
		}
		if(k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" || k == "__properties__") {
			continue;
		}
		if(str.length != 2) str += ", \n";
		str += s + k + " : " + js.Boot.__string_rec(o[k],s);
		}
		s = s.substring(1);
		str += "\n" + s + "}";
		return str;
	case "function":
		return "<function>";
	case "string":
		return o;
	default:
		return String(o);
	}
}
js.Boot.__interfLoop = function(cc,cl) {
	if(cc == null) return false;
	if(cc == cl) return true;
	var intf = cc.__interfaces__;
	if(intf != null) {
		var _g1 = 0, _g = intf.length;
		while(_g1 < _g) {
			var i = _g1++;
			var i1 = intf[i];
			if(i1 == cl || js.Boot.__interfLoop(i1,cl)) return true;
		}
	}
	return js.Boot.__interfLoop(cc.__super__,cl);
}
js.Boot.__instanceof = function(o,cl) {
	try {
		if(o instanceof cl) {
			if(cl == Array) return o.__enum__ == null;
			return true;
		}
		if(js.Boot.__interfLoop(o.__class__,cl)) return true;
	} catch( e ) {
		if(cl == null) return false;
	}
	switch(cl) {
	case Int:
		return Math.ceil(o%2147483648.0) === o;
	case Float:
		return typeof(o) == "number";
	case Bool:
		return o === true || o === false;
	case String:
		return typeof(o) == "string";
	case Dynamic:
		return true;
	default:
		if(o == null) return false;
		if(cl == Class && o.__name__ != null) return true; else null;
		if(cl == Enum && o.__ename__ != null) return true; else null;
		return o.__enum__ == cl;
	}
}
js.Boot.__cast = function(o,t) {
	if(js.Boot.__instanceof(o,t)) return o; else throw "Cannot cast " + Std.string(o) + " to " + Std.string(t);
}
js.Cookie = function() { }
$hxClasses["js.Cookie"] = js.Cookie;
js.Cookie.__name__ = ["js","Cookie"];
js.Cookie.set = function(name,value,expireDelay,path,domain) {
	var s = name + "=" + StringTools.urlEncode(value);
	if(expireDelay != null) {
		var d = DateTools.delta(new Date(),expireDelay * 1000);
		s += ";expires=" + d.toGMTString();
	}
	if(path != null) s += ";path=" + path;
	if(domain != null) s += ";domain=" + domain;
	js.Lib.document.cookie = s;
}
js.Cookie.all = function() {
	var h = new Hash();
	var a = js.Lib.document.cookie.split(";");
	var _g = 0;
	while(_g < a.length) {
		var e = a[_g];
		++_g;
		e = StringTools.ltrim(e);
		var t = e.split("=");
		if(t.length < 2) continue;
		h.set(t[0],StringTools.urlDecode(t[1]));
	}
	return h;
}
js.Cookie.get = function(name) {
	return js.Cookie.all().get(name);
}
js.Cookie.exists = function(name) {
	return js.Cookie.all().exists(name);
}
js.Cookie.remove = function(name,path,domain) {
	js.Cookie.set(name,"",-10,path,domain);
}
js.Lib = function() { }
$hxClasses["js.Lib"] = js.Lib;
js.Lib.__name__ = ["js","Lib"];
js.Lib.document = null;
js.Lib.window = null;
js.Lib.debug = function() {
	debugger;
}
js.Lib.alert = function(v) {
	alert(js.Boot.__string_rec(v,""));
}
js.Lib["eval"] = function(code) {
	return eval(code);
}
js.Lib.setErrorHandler = function(f) {
	js.Lib.onerror = f;
}
function $iterator(o) { if( o instanceof Array ) return function() { return HxOverrides.iter(o); }; return typeof(o.iterator) == 'function' ? $bind(o,o.iterator) : o.iterator; };
var $_;
function $bind(o,m) { var f = function(){ return f.method.apply(f.scope, arguments); }; f.scope = o; f.method = m; return f; };
if(Array.prototype.indexOf) HxOverrides.remove = function(a,o) {
	var i = a.indexOf(o);
	if(i == -1) return false;
	a.splice(i,1);
	return true;
}; else null;
Math.__name__ = ["Math"];
Math.NaN = Number.NaN;
Math.NEGATIVE_INFINITY = Number.NEGATIVE_INFINITY;
Math.POSITIVE_INFINITY = Number.POSITIVE_INFINITY;
$hxClasses.Math = Math;
Math.isFinite = function(i) {
	return isFinite(i);
};
Math.isNaN = function(i) {
	return isNaN(i);
};
String.prototype.__class__ = $hxClasses.String = String;
String.__name__ = ["String"];
Array.prototype.__class__ = $hxClasses.Array = Array;
Array.__name__ = ["Array"];
Date.prototype.__class__ = $hxClasses.Date = Date;
Date.__name__ = ["Date"];
var Int = $hxClasses.Int = { __name__ : ["Int"]};
var Dynamic = $hxClasses.Dynamic = { __name__ : ["Dynamic"]};
var Float = $hxClasses.Float = Number;
Float.__name__ = ["Float"];
var Bool = $hxClasses.Bool = Boolean;
Bool.__ename__ = ["Bool"];
var Class = $hxClasses.Class = { __name__ : ["Class"]};
var Enum = { };
var Void = $hxClasses.Void = { __ename__ : ["Void"]};
haxe.Resource.content = [{ name : "Detail", data : "s1098:PGRpdiBjbGFzcz0iZGV0YWlsIiBjb21tZW50LWNvdW50PSI6OmNvbW1lbnRzTGVuZ3RoOjoiIGNvbW1lbnRzLXZlcnNpb249Ijo6Y29tbWVudHNWZXJzaW9uOjoiPgogIDxkaXYgY2xhc3M9ImF1dGhvciI%CiAgICA8c3Ryb25nPgogICAgICA6OmF1dGhvckxhYmVsOjoKICAgIDwvc3Ryb25nPgogICAgPHNwYW4gY2xhc3M9InVzZXJuYW1lIj4KICAgICAgQDo6YXV0aG9yVXNlcm5hbWU6OgogICAgPC9zcGFuPgogICAgPHNwYW4gY2xhc3M9ImZhdm9yZWQtYnkiPgogICAgICA6OmZhdm9yZWRCeTo6CiAgICA8L3NwYW4%CiAgICA8c3BhbiBjbGFzcz0iZWxhcHNlZCI%CiAgICAgIDo6ZWxhcHNlZDo6CiAgICA8L3NwYW4%CiAgICA8c3BhbiBjbGFzcz0iZmF2b3JpdGUiPgogICAgICA6OmlmICh1c2VyRXhpc3RzKTo6CiAgICAgIDo6aWYgKHdyaXRhYmxlKTo6CiAgICAgIDo6aWYgKGZhdm9yZWQpOjoKICAgICAgPGEgaHJlZj0iIyIgb25jbGljaz0iTXlQYWdlLnVuZmF2b3IoOjpyaWJib25JZDo6LCA6OnBvc3RJZDo6KTtyZXR1cm4gZmFsc2U7Ij4KICAgICAgICDjgZ3jgYbjgafjgoLjgarjgYQKICAgICAgPC9hPgogICAgICA6OmVsc2U6OgogICAgICA8YSBocmVmPSIjIiBvbmNsaWNrPSJNeVBhZ2UuZmF2b3IoOjpyaWJib25JZDo6LCA6OnBvc3RJZDo6KTtyZXR1cm4gZmFsc2U7Ij4KICAgICAgICDjgZ3jgYbjgYvjgoIKICAgICAgPC9hPgogICAgICA6OmVuZDo6CiAgICAgIDo6ZW5kOjoKICAgICAgOjplbmQ6OgogICAgPC9zcGFuPgogIDwvZGl2PgogIDxkaXYgY2xhc3M9ImNvbnRlbnQiPgogICAgOjpjb250ZW50OjoKICA8L2Rpdj4KPC9kaXY%Cg"},{ name : "Timeline", data : "s2754:PHNlY3Rpb24KICAgY2xhc3M9InRpbWVsaW5lIgogICBsZXZlbD0iOjpsZXZlbDo6IgogICByaWJib24taWQ9Ijo6cmliYm9uSWQ6OiIKICAgdGltZWxpbmUtaWQ9Ijo6dGltZWxpbmVJZDo6IgogICB2ZXJzaW9uPSI6OnRpbWVsaW5lVmVyc2lvbjo6IgogICBpbnRlcnZhbHM9Ijo6aW50ZXJ2YWxzOjoiCiAgIGVkaXRhYmxlPSI6OmVkaXRhYmxlOjoiCiAgID4KICA6OmZvcmVhY2ggcG9zdHM6OgogIDxhcnRpY2xlCiAgICAgY2xhc3M9InBvc3QiCiAgICAgc2NvcmU9Ijo6X19jdXJyZW50X18uc2NvcmU6OiIKICAgICBwb3N0LWlkPSI6Ol9fY3VycmVudF9fLnBvc3RJZDo6IgogICAgIHBvc3QtdHlwZT0iOjpfX2N1cnJlbnRfXy5wb3N0VHlwZTo6IgogICAgIHZlcnNpb249Ijo6X19jdXJyZW50X18ucG9zdFZlcnNpb246OiIKICAgICByZW1vdmVkPSI6Ol9fY3VycmVudF9fLnJlbW92ZWQ6OiIKICAgICA%CiAgICA8ZGl2IGNsYXNzPSJhdmF0YXIiPgogICAgICA8ZGl2IGNsYXNzPSJpY29uIj4KICAgICAgICA8aW1nIHNyYz0iaHR0cDovL3d3dy5ncmF2YXRhci5jb20vYXZhdGFyLzo6X19jdXJyZW50X18uaWNvbjo6P3M9NDAmZD1tbSIgYWx0PSJncmF2YXRvciIvPgogICAgICA8L2Rpdj4KICAgIDwvZGl2PgogICAgPGRpdiBjbGFzcz0iZW50cnkiPgogICAgICA6Ol9fY3VycmVudF9fLmRldGFpbDo6CgogICAgICA6OmlmIChsZXZlbCA9PSAwKTo6CiAgICAgIDxkaXYgY2xhc3M9Im9wZXJhdGlvbiI%CiAgICAgICAgPGEgY2xhc3M9InNob3ctY29tbWVudCIgaHJlZj0iIyIgb25jbGljaz0iTXlQYWdlLnRvZ2dsZUNvbW1lbnRzKHRoaXMpO3JldHVybiBmYWxzZTsiPgogICAgICAgICAgPGltZyBzcmM9Ijo6Y2hhdEljb25Vcmw6OiI%CiAgICAgICAgICA8c3BhbiBjbGFzcz0ic2hvdy1jb21tZW50LWxhYmVsIj7Dlzo6X19jdXJyZW50X18uY29tbWVudHNMZW5ndGg6Ojwvc3Bhbj4KICAgICAgICA8L2E%CiAgICAgICAgOjppZiBlZGl0YWJsZTo6CiAgICAgICAgPHNwYW4gY2xhc3M9InVpLWRlbGltaXRlci04Ij48L3NwYW4%CiAgICAgICAgPGEgY2xhc3M9InBvc3QtY29tbWVudCIgaHJlZj0iIyIgb25jbGljaz0iTXlQYWdlLnRvZ2dsZUNvbW1lbnRGb3JtKHRoaXMpO3JldHVybiBmYWxzZTsiPuOCs%ODoeODs%ODiOOBmeOCizwvYT4KICAgICAgICA6OmVuZDo6CiAgICAgIDwvZGl2PgogICAgICA6OmVuZDo6CgogICAgICA6OmlmIGVkaXRhYmxlOjoKICAgICAgPGRpdiBjbGFzcz0iY29tbWVudC1mb3JtIj4KICAgICAgICA8Zm9ybT4KICAgICAgICAgIDxpbnB1dCB0eXBlPSJoaWRkZW4iIG5hbWU9InBhcmVudCIgdmFsdWU9Ijo6X19jdXJyZW50X18ucG9zdElkOjoiLz4KICAgICAgICAgIDx0ZXh0YXJlYSBuYW1lPSJjb250ZW50Ij48L3RleHRhcmVhPjxici8%CiAgICAgICAgICA8aW5wdXQgY2xhc3M9ImJ0biBidG4tcHJpbWFyeSIgdHlwZT0iYnV0dG9uIiB2YWx1ZT0i5oqV56i:IiBvbmNsaWNrPSJNeVBhZ2UucG9zdENvbW1lbnQoOjpyaWJib25JZDo6LCA6Ol9fY3VycmVudF9fLmNvbW1lbnRzSWQ6OiwgJCh0aGlzKS5wYXJlbnQoKSk7cmV0dXJuIGZhbHNlOyIvPgogICAgICAgICAgPGEgY2xhc3M9ImJ0biBidG4taW5mbyIgaHJlZj0iIyIgb25jbGljaz0iTXlQYWdlLmNob29zZVN0YW1wKHRoaXMsIDo6cmliYm9uSWQ6OiwgOjpfX2N1cnJlbnRfXy5jb21tZW50c0lkOjopO3JldHVybiBmYWxzZTsiPuOCueOCv%ODs%ODlzwvYT4KICAgICAgICA8L2Zvcm0%CiAgICAgIDwvZGl2PgogICAgICA6OmVuZDo6CiAgICAgIAogICAgICA8ZGl2IGNsYXNzPSJjb21tZW50cyIgY291bnQ9Ijo6X19jdXJyZW50X18uY29tbWVudHNMZW5ndGg6OiI%CiAgICAgICAgPHNlY3Rpb24gY2xhc3M9InRpbWVsaW5lIiBsZXZlbD0iOjoobGV2ZWwgKyAxKTo6IiByaWJib24taWQ9Ijo6cmliYm9uSWQ6OiIgdGltZWxpbmUtaWQ9Ijo6X19jdXJyZW50X18uY29tbWVudHNJZDo6IiB2ZXJzaW9uPSIwIj4KICAgICAgICA8L3NlY3Rpb24%ICAgICAgICAKICAgICAgPC9kaXY%CiAgICA8L2Rpdj4KICA8L2FydGljbGU%CiAgOjplbmQ6Ogo8L3NlY3Rpb24%Cg"}];
js.XMLHttpRequest = window.XMLHttpRequest?XMLHttpRequest:window.ActiveXObject?function() {
	try {
		return new ActiveXObject("Msxml2.XMLHTTP");
	} catch( e ) {
		try {
			return new ActiveXObject("Microsoft.XMLHTTP");
		} catch( e1 ) {
			throw "Unable to create XMLHttpRequest object.";
		}
	}
}:(function($this) {
	var $r;
	throw "Unable to create XMLHttpRequest object.";
	return $r;
}(this));
if(typeof document != "undefined") js.Lib.document = document;
if(typeof window != "undefined") {
	js.Lib.window = window;
	js.Lib.window.onerror = function(msg,url,line) {
		var f = js.Lib.onerror;
		if(f == null) return false;
		return f(msg,[url + ":" + line]);
	};
}
DateTools.DAYS_OF_MONTH = [31,28,31,30,31,30,31,31,30,31,30,31];
haxe.Template.splitter = new EReg("(::[A-Za-z0-9_ ()&|!+=/><*.\"-]+::|\\$\\$([A-Za-z0-9_-]+)\\()","");
haxe.Template.expr_splitter = new EReg("(\\(|\\)|[ \r\n\t]*\"[^\"]*\"[ \r\n\t]*|[!+=/><*.&|-]+)","");
haxe.Template.expr_trim = new EReg("^[ ]*([^ ]+)[ ]*$","");
haxe.Template.expr_int = new EReg("^[0-9]+$","");
haxe.Template.expr_float = new EReg("^([+-]?)(?=\\d|,\\d)\\d*(,\\d*)?([Ee]([+-]?\\d+))?$","");
haxe.Template.globals = { };
haxe.Unserializer.DEFAULT_RESOLVER = Type;
haxe.Unserializer.BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%:";
haxe.Unserializer.CODES = null;
js.Lib.onerror = null;
MyPage.main();
function $hxExpose(src, path) {
	var o = window;
	var parts = path.split(".");
	for(var ii = 0; ii < parts.length-1; ++ii) {
		var p = parts[ii];
		if(typeof o[p] == "undefined") o[p] = {};
		o = o[p];
	}
	o[parts[parts.length-1]] = src;
}
})();
