import jQuery.JQuery;
import js.Lib;
import js.Cookie;
import Lambda;
import ArrayUtil;

using Lambda;
using ArrayUtil;

import RocketIO;

extern class JSON {
    static public function stringify(s: Dynamic): String;
}

@:expose
class MyPage {
    static private var connected: Bool;
    static private var io: Dynamic;

    ////////////////////////////////////////////////////////////////
    // public functions
    static function main() {
    }

    static function testIt() {
    }

    static function init(timelineId: Int) {
        fillPosts(timelineId, null);
        startWatch();
    }

    static function toggleComments(obj: Dynamic) {
        var entry = getEntry(obj);
        var comments = entry.find('> .comments');
        comments.toggle();
        if (comments.is(':visible')) {
            var n = entry.find('> .detail').attr('comments-version');
            if (n != null) {
                var idealVersion = Std.parseInt(n);
                var timeline = comments.find('> .timeline');
                var actualVersion = Std.parseInt(timeline.attr('version'));
                if (actualVersion < idealVersion) {
                    var timelineId = Std.parseInt(timeline.attr('timeline-id'));
                    trace(timeline);
                    trace(timeline.attr('timeline-id'));
                    fillPosts(timelineId, idealVersion);
                }
            }
        }
        updateCommentDisplayText();
        subscribeTimelines();
        subscribePosts();
        saveOpenStates();
    }

    static function toggleCommentForm(obj: Dynamic) {
        var commentForm = getEntry(obj).find('> .comment-form');
        commentForm.toggle();
        if (commentForm.is(':visible')) {
            scrollToElement(commentForm);
            commentForm.find('textarea').focus();
        }
    }

    static function scrollToEntryTail(obj: Dynamic) {
        var entry = getEntry(obj);
        scrollToElement(entry);
        entry.find('> .comment-form').find('textarea').focus();
    }

    static function postArticle(timelineId: Int, form: Dynamic) {
        JQuery._static.ajax({
            url: "/foo/m/newarticle",
            method: "post",
            data: {
                content: new JQuery(form).find('[name="content"]').val(),
                timeline: timelineId
            }
        }).done(function() {
            fillPosts(timelineId, 0);
        });
        form.find('[name="content"]').val('');
        form.find('textarea').focus();
    }

    static function postComment(timelineId: Int,form: Dynamic) {
        JQuery._static.ajax({
            url: "/foo/m/newcomment",
            method: "post",
            data: {
                parent: new JQuery(form).find('[name="parent"]').val(),
                content: new JQuery(form).find('[name="content"]').val(),
                timeline: timelineId
            }
        }).done(function() {
            fillPosts(timelineId, 0);
            var entry = getEntry(form);
            var comments = entry.find('> .comments');
            if (!comments.is(':visible')) {
                toggleComments(entry);
            }
        });
        form.find('[name="content"]').val('');
        form.find('textarea').focus();
    }

    static function toggleFavorite(postId: Int) {
        JQuery._static.ajax({
            url: "/foo/m/favor",
            data: {
                target: postId
            }
        });
    }

    ////////////////////////////////////////////////////////////////
    // private functions
    static private function fillPosts(timelineId: Int, version: Int) {
        trace(Std.format('fillPosts($timelineId, $version) executed'));
        var timeline = new JQuery(Std.format('[timeline-id="$timelineId"]'));
        var level = Std.parseInt(timeline.attr('level'));

        if (!startLoad(timeline, version)) {
            return;
        }

        trace("running ajax(jsonp)");
        JQuery._static.ajax({ 
            url: "/foo/p/timeline",
            data: {
                timeline: timelineId,
                level: level
            },
            dataType: 'jsonp'
        }).done(function(data: Dynamic) {
            trace("timeline response receivied");
            trace(data);
            var posts: Array<Dynamic> = data.posts;
            for(i in 0...posts.length) {
                var post: Dynamic = posts[i];
                var favoredBy = "";
                var srcFavoredBy: Array<String> = post.detail.favoredBy;
                for(j in 0...srcFavoredBy.length) {
                    favoredBy += Std.format('<img src="http://www.gravatar.com/avatar/${srcFavoredBy[j]}?s=16&d=mm" alt="gravator"/>');
                }
                post.detail.favoredBy = favoredBy;
                post.detail = applyTemplate("Detail", post.detail);
            }
            finishLoad(timeline, function() {
                var output = applyTemplate("Timeline", data);
                var entry = getEntry(timeline);
                var newPosts = new JQuery(output);
                timeline.replaceWith(newPosts);
                if (level == 0) {
                    loadOpenStates();
                } else {
                    var count = newPosts.find('> .post').length;
                    entry.find('> .detail').attr('comment-count', count);
                    updateCommentDisplayText();
                    subscribePosts();
                    var commentForm = entry.find('> .comment-form');
                    trace(new JQuery(':focus'));
                    if (commentForm.find('textarea').is(':focus')) {
                        trace("submit focused");
                        scrollToElement(entry);
                    }
                }
            });
        });
    }

    static private function saveOpenStates() {
        var a = new JQuery('.comments:visible').map(
            function(i: Int, elem: Dynamic) {
                var e = new JQuery(elem);
                return Std.parseInt(e.find('> .timeline').attr('timeline-id'));
            }
        );
        Cookie.set('opened', JSON.stringify(a.get()), 7);
    }

    static private function loadOpenStates() {
        var cookie = Cookie.get('opened');
        if (cookie != null) {
            var rawOpened: Array<Int> = JQuery._static.parseJSON(cookie);
            var opened = new Hash<Int>();
            for(i in 0...rawOpened.length) {
                opened.set(Std.string(rawOpened[i]), rawOpened[i]);
            }
            new JQuery('.comments').each(function(i: Int, elem: Dynamic) {
                    var e = new JQuery(elem);
                    var timelineId = e.find('> .timeline').attr('timeline-id');
                    if (opened.exists(timelineId)) {
                        e.show();
                    }
                });
        }
        updateCommentDisplayText();
        subscribeTimelines();
        subscribePosts();
    }

    static private function startLoad(timeline: Dynamic, version: Int): Bool {
        trace(timeline.attr('loading'));
        if (timeline.attr('loading') != null) {
            trace("タイムライン取得中なので待機キューに入れる");
            timeline.attr('waiting', version);
            return false;
        }

        if (version != null) {
            if (version <= Std.parseInt(timeline.attr('version'))) {
                trace('version older or equal');
                return false;
            }
        }

        timeline.attr('loading', 'true');
        return true;
    }

    static private function finishLoad(timeline: Dynamic, f: Void->Void) {
        var timelineId = Std.parseInt(timeline.attr('timeline-id'));

        timeline.removeAttr('loading');
        var waitingVersion = timeline.attr('waiting');
        timeline.removeAttr('waiting');

        f();

        if (waitingVersion != null) {
            // loading中に更新リクエストが来ている場合は再試行
            trace("waiting versionの取得を開始");
            fillPosts(timelineId, Std.parseInt(waitingVersion));
        }
    }

    static private function scrollToElement(e: Dynamic) {
        var window = new JQuery(js.Lib.window);
        var document = new JQuery(js.Lib.document);

        var bottomMargin = 32;
        var target =
            e.offset().top - window.height() + e.height() + bottomMargin;
        if (document.scrollTop() < target) {
            document.scrollTop(target);
        }
    }

    static private function getEntry(obj: Dynamic): JQuery {
        var e = new JQuery(obj);
        if (e.is('.entry')) {
            return e;
        } else {
            return e.parents(".entry").eq(0);
        }
    }

    static private function updateCommentDisplayText() {
        new JQuery('.comments').each(function(i: Int, e: Dynamic) {
            var comments = new JQuery(e);
            var entry = getEntry(comments);
            var showComment = entry.find('> .operation .show-comment-label');
            if (comments.is(':visible')) {
                showComment.html('隠す');
            } else {
                var count = entry.find('> .detail').attr('comment-count');
                showComment.html(Std.format('×$count'));
            }
        });
        
    }

    static private function subscribeTimelines() {
        if (connected) {
            var targets = new JQuery('[timeline-id]:visible').map(
                function(i: Int, e: Dynamic) {
                    return Std.parseInt(new JQuery(e).attr('timeline-id'));
                }
            );
            io.push("watch-timeline", {targets: targets.get()});
        }
    }

    static private function subscribePosts() {
        if (connected) {
            var targets = new JQuery('[post-id]:visible').map(
                function(i: Int, e: Dynamic) {
                    return Std.parseInt(new JQuery(e).attr('post-id'));
                }
            );
            io.push("watch-post", {targets: targets.get()});
        }
    }

    static private function updateTimeline(timelineId: Int, version: Int) {
        trace("update timeline");
        fillPosts(timelineId, version);
    }

    static function updateDetail(postId: Int, version: Int) {
        var post = new JQuery(Std.format('[post-id="$postId"]'));
        var level = Std.parseInt(post.parent().attr('level'));

        JQuery._static.ajax({
            url: "/foo/p/detail",
            data: {
                post: postId,
                level: level
            },
            dataType: 'jsonp'
        }).done(function(data: Dynamic) {
            var favoredBy = "";
            for(i in 0...data.favoredBy.length) {
                favoredBy += Std.format('<img src="http://www.gravatar.com/avatar/${data.favoredBy[i]}?s=16&d=mm" alt="gravator"/>');
            }
            data.favoredBy = favoredBy;

            var output = applyTemplate("Detail", data);
            post.find('> .entry > .detail').replaceWith(output);
            updateCommentDisplayText();
        });

    }

    static private function applyTemplate(codename: String, data: Dynamic): String {
        var templateCode = haxe.Resource.getString(codename);
        var template = new haxe.Template(templateCode);
        return template.execute(data);
    }

    static private function startWatch() {
        io = new RocketIO().connect();
        io.on("connect", function(session) {
            connected = true;
            subscribeTimelines();
            subscribePosts();
        });
        io.on("watch-timeline", function(data: Dynamic<Int>) {
            trace("timeline update signal received");
            trace(data);
            updateTimeline(data.timeline, data.version);
        });
        io.on("watch-post", function(data: Dynamic<Int>) {
            trace("post update signal received");
            trace(data);
            updateDetail(data.post, data.version);
        });
    }

}

