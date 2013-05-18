extern class JSON {
    static public function stringify(s: Dynamic): String;
}

class Misc {
    static public function redirect(url: String) {
        js.Lib.window.location.href = url;
    }

    static public function enable(e: Dynamic) {
        e.removeAttr('disabled');
    }

    static public function disable(e: Dynamic) {
        e.attr('disabled', 'disabled');
    }

    static public function setEnabled(e: Dynamic, f: Bool) {
        if (f) {
            enable(e);
        } else {
            disable(e);
        }
    }

    static public function gravatar(
        hash: String,
        size: Int,
        userId: Int=0,
        username: String="",
        label: String=""): String {
        return Std.format('<img src="http://www.gravatar.com/avatar/${hash}?s=${size}&d=mm" alt="gravatar" user-id="$userId" username="$username" title="$label" data-toggle="tooltip"/>');
    }

    static public function tooltip(s: String, desc: String) {
        return Std.format('<a href="#" data-toggle="tooltip" title="$desc" onmouseover="$(this).tooltip(\'show\');" onmouseout="$(this).tooltip(\'hide\');">$s</a>');
        
    }
    
    static public function makeBoardUrl(username, boardname): String {
        var urlinfo: Dynamic = new JQuery('#basic-data');
        var base_url = urlinfo.attr('base-url');
        return Std.format("$base_url/$username/$boardname");
    }

}
