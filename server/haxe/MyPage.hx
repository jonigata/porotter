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
        fillTimeline(getTimeline(timelineId), null);
        startWatch();
    }

    static function toggleComments(obj: Dynamic) {
        var entry = getEntry(obj);
        var comments = entry.find('> .comments');
        if (comments.is(':visible')) {
            closeComments(comments);
        } else {
            openComments(comments);
        }
        updateCommentDisplayText(entry);
        subscribeTimelines();
        subscribePosts();
        saveCommentsOpenStates();
    }

    static function toggleCommentForm(obj: Dynamic) {
        var commentForm = getEntry(obj).find('> .comment-form');
        commentForm.toggle();
        if (commentForm.is(':visible')) {
            scrollToElement(commentForm);
            commentForm.find('textarea').focus();
        }
        saveCommentFormOpenStates();
    }

    static function scrollToEntryTail(obj: Dynamic) {
        var entry = getEntry(obj);
        scrollToElement(entry);
        entry.find('> .comment-form').find('textarea').focus();
    }

    static function postArticle(timelineId: Int, form: Dynamic) {
        JQuery._static.ajax({
            url: "/foo/ajax/m/newarticle",
            method: "post",
            data: {
                content: new JQuery(form).find('[name="content"]').val(),
                timeline: timelineId
            }
        }).done(function() {
        });
        form.find('[name="content"]').val('');
        form.find('textarea').focus();
    }

    static function postComment(timelineId: Int,form: Dynamic) {
        JQuery._static.ajax({
            url: "/foo/ajax/m/newcomment",
            method: "post",
            data: {
                parent: new JQuery(form).find('[name="parent"]').val(),
                content: new JQuery(form).find('[name="content"]').val(),
                timeline: timelineId
            }
        }).done(function() {
            openComments(getEntry(form).find('> .comments'));
            saveCommentFormOpenStates();
        });
        form.find('[name="content"]').val('');
        form.find('textarea').focus();
    }

    static function toggleFavorite(postId: Int) {
        JQuery._static.ajax({
            url: "/foo/ajax/m/favor",
            method: "post",
            data: {
                target: postId
            }
        });
    }

    static function continueReading(obj: Dynamic) {
        var e = new JQuery(obj);
        var timeline = e.closest('.timeline');
        var newestScore = e.attr('newest-score');
        var oldestScore = kickUndefined(e.attr('oldest-score'));
        fetchTimeline(timeline, newestScore, oldestScore, null);
    }

    static function chooseStamp(obj: Dynamic, timelineId: Int) {
        var chooser: Dynamic = new JQuery('#stamp-chooser');
        chooser.find('a').each(
            function(i: Int, elem: Dynamic) {
                var e = new JQuery(elem);
                e.unbind('click');
                e.click(
                    function() {
                        postStamp(timelineId, new JQuery(obj), new JQuery(e));
                        chooser.close();
                    });
            });
        chooser.justModal();
    }

    ////////////////////////////////////////////////////////////////
    // private functions
    static private function postStamp(
        timelineId: Int, source: Dynamic, selected: Dynamic) {
        var form = source.closest('.comment-form').find('> form');
        var image = selected.attr('image');
        JQuery._static.ajax({
            url: "/foo/ajax/m/stamp",
            method: "post",
            data: {
                parent: form.find('[name="parent"]').val(),
                content: image,
                timeline: timelineId
            }
        }).done(function() {
            openComments(getEntry(form).find('> .comments'));
            saveCommentFormOpenStates();
        });
    }

    static private function fillTimeline(timeline: Dynamic, version: Int) {
        fetchTimeline(timeline, null, null, version);
    }

    static private function fillNewerTimeline(timeline: Dynamic, version: Int) {
        var oldestScore =
            kickUndefined(timeline.children().eq(0).attr('newest-score'));
        fetchTimeline(timeline, null, oldestScore, version);
    }
    
    static private function getTimeline(timelineId: Int) {
        return new JQuery(Std.format('[timeline-id="$timelineId"]'));
    }
    
    static private function fetchTimeline(
        oldTimeline: Dynamic,
        newestScore: Dynamic,
        oldestScore: Dynamic,
        version: Int) {
        
        var timelineId = Std.parseInt(oldTimeline.attr('timeline-id'));
        var level = Std.parseInt(oldTimeline.attr('level'));

        if (!startLoad(oldTimeline, version)) {
            return;
        }

        JQuery._static.ajax({ 
            url: "/foo/ajax/v/timeline",
            data: {
                timeline: timelineId,
                newest_score: kickUndefined(newestScore),
                oldest_score: kickUndefined(oldestScore),
                count: 3
            },
            dataType: 'jsonp'
        }).done(function(data: Dynamic) {
            data.level = level;
            var posts: Array<Dynamic> = data.posts;
            for(post in posts) {
                var favoredBy = "";
                var srcFavoredBy: Array<String> = post.detail.favoredBy;
                for(vv in srcFavoredBy) {
                    favoredBy += Std.format('<img src="http://www.gravatar.com/avatar/${vv}?s=16&d=mm" alt="gravator"/>');
                }
                post.detail.favoredBy = favoredBy;
                post.detail = applyTemplate("Detail", post.detail);
            }
            data.intervals =
                Std.format("[[${data.newestScore}, ${data.oldestScore}]]");
            finishLoad(oldTimeline, function() {
                var output = applyTemplate("Timeline", data);
                var entry = getEntry(oldTimeline);
                var newTimeline = new JQuery(output);
                mergeTimeline(oldTimeline, newTimeline);
                if (level == 0) {
                    loadOpenStates();
                } else {
                    subscribePosts();
                }
            });
        });
    }

    static private function mergeTimeline(
        oldTimeline: Dynamic, newTimeline: Dynamic) {

        oldTimeline.find('> .continue-reading').remove();

        var ne: Dynamic = newTimeline.children().eq(0);
        var oldTimelineElements: Array<Dynamic> = oldTimeline.children().get();
        for(ore in oldTimelineElements) {
            var oe = new JQuery(ore);
            var oldScore = Std.parseInt(oe.attr('score'));
            var newScore: Int = null;
            while(oldScore <= (newScore = Std.parseInt(ne.attr('score')))) {
                if (oldScore == newScore) {
                    oe.replaceWith(ne);
                } else {
                    ne.insertBefore(oe);
                    // 古いものがある場合は子供を奪って消す
                    var postId = ne.attr('post-id');
                    var oldPost = ne.nextAll(Std.format('[post-id=$postId]'));
                    if (0 < oldPost.length) {
                        var entry = ne.find('> .entry');
                        entry.find('> .comments').replaceWith(
                            oldPost.find('> .entry > .comments'));
                        updateCommentDisplayText(entry);
                    }
                    oldPost.remove();
                }
                ne = ne.next();
                if (ne.length == 0) {
                    break;
                }
            }
            if (ne.length == 0) {
                break;
            }
        }
        if (0 < ne.length) {
            var nextne = ne.nextAll();
            oldTimeline.append(ne);
            oldTimeline.append(nextne);
        }

        // interval処理
        var intervals = new Intervals();
        var oldTimelineIntervalsAttr = oldTimeline.attr('intervals');
        if (kickUndefined(oldTimelineIntervalsAttr) != null) {
            intervals.from_array(JQuery._static.parseJSON(oldTimelineIntervalsAttr));
        }

        var tmpIntervalArray: Array<Array<Int>> =
            JQuery._static.parseJSON(newTimeline.attr('intervals'));
        for(v in tmpIntervalArray) {
            intervals.add(v[0], v[1]);
        }

        for(v in intervals.elems) {
            if(v.e != 0) {
                insertContinueReading(oldTimeline, v.e);
            }
        }
        oldTimeline.attr('intervals', JSON.stringify(intervals.to_array()));
    }

    static private function insertContinueReading(
        timeline: Dynamic, score: Int) {

        var link = new JQuery('<a class="continue-reading" href="#" onclick="MyPage.continueReading(this);return false;">続きを読む</a>');
        link.attr('newest-score', score);
        var a: Array<Dynamic> = timeline.children().get();
        for(v in a) {
            var oldScore = Std.parseInt(new JQuery(v).attr('score'));
            if (oldScore < score) {
                link.attr('oldest-score', oldScore);
                link.insertBefore(v);
                return;
            }
        }
        timeline.append(link);
    }

    static private function saveCommentsOpenStates() {
        saveOpenStatesAux("comments");
    }

    static private function saveCommentFormOpenStates() {
        saveOpenStatesAux("comment-form");
    }

    static private function saveOpenStatesAux(label: String) {
        var a = new JQuery(Std.format('.$label:visible')).map(
            function(i: Int, elem: Dynamic) {
                return Std.parseInt(getTimelineIdFromEntryContent(elem));
            }
        );
        Cookie.set(label, JSON.stringify(a.get()), 7);
    }

    static private function loadOpenStates() {
        loadOpenStatesAux(
            "comments",
            function(e: Dynamic) {
                openComments(e);
            });
        loadOpenStatesAux(
            "comment-form",
            function(e: Dynamic) {
                e.show();
            });
        
        subscribeTimelines();
        subscribePosts();
    }

    static private function loadOpenStatesAux(
        label: String, f: Dynamic->Void) {

        var cookie = kickUndefined(Cookie.get(label));
        if (cookie == null) {
            return;
        }
        
        var rawOpened: Array<Int> = JQuery._static.parseJSON(cookie);
        var opened = new Hash<Int>();
        for(v in rawOpened) {
            opened.set(Std.string(v), v);
        }

        new JQuery(Std.format(".$label")).each(
            function(i: Int, elem: Dynamic) {
                var e = new JQuery(elem);
                var timelineId: String = getTimelineIdFromEntryContent(e);
                if (opened.exists(timelineId)) {
                    f(e);
                }
            });
    }

    static private function getTimelineIdFromEntryContent(e: Dynamic) {
        return getEntry(e).find('> .comments > .timeline').attr('timeline-id');
    }

    static private function startLoad(timeline: Dynamic, version: Int): Bool {
        if (timeline.attr('loading') != null) {
            var oldWaiting = kickUndefined(timeline.attr('waiting'));
            if( version != null &&
                oldWaiting == null ||
                Std.parseInt(oldWaiting) < version) {
                timeline.attr('waiting', version);
            }
            return false;
        }

        if (version != null) {
            if (version <= Std.parseInt(timeline.attr('version'))) {
                return false;
            }
        }

        timeline.attr('loading', 'true');
        return true;
    }

    static private function finishLoad(timeline: Dynamic, f: Void->Void) {
        timeline.removeAttr('loading');
        var waitingVersion = timeline.attr('waiting');
        timeline.removeAttr('waiting');

        f();

        if (waitingVersion != null) {
            // loading中に更新リクエストが来ている場合は再試行
            fillNewerTimeline(timeline, Std.parseInt(waitingVersion));
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
            return e.closest(".entry");
        }
    }

    static private function updateCommentDisplayText(entry: Dynamic) {
        var comments = entry.find('> .comments');
        var showComment = entry.find('> .operation .show-comment-label');
        if (comments.is(':visible')) {
            showComment.html('隠す');
        } else {
            var count = entry.find('> .detail').attr('comment-count');
            showComment.html(Std.format('×$count'));
        }
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
        fillNewerTimeline(getTimeline(timelineId), version);
    }

    static function updateDetail(postId: Int, version: Int) {
        var post = new JQuery(Std.format('[post-id="$postId"]'));
        var level = Std.parseInt(post.parent().attr('level'));

        JQuery._static.ajax({
            url: "/foo/ajax/v/detail",
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
            var entry = post.find('> .entry');
            entry.find('> .detail').replaceWith(output);
            updateCommentDisplayText(entry);
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
            updateTimeline(data.timeline, data.version);
        });
        io.on("watch-post", function(data: Dynamic<Int>) {
            updateDetail(data.post, data.version);
        });
    }

    static private function openComments(comments: Dynamic) {
        comments.show();
        var n = getEntry(comments).find('> .detail').attr('comments-version');
        if (n != null) {
            var idealVersion = Std.parseInt(n);
            var timeline = comments.find('> .timeline');
            fillNewerTimeline(timeline, idealVersion);
        }
    }

    static private function closeComments(comments: Dynamic) {
        comments.hide();
    }

    static private function isUndefined(x: Dynamic) {
        return untyped __js__('"undefined" === typeof x');
    }

    static private function kickUndefined(x: Dynamic): Dynamic {
        if (isUndefined(x)) {
            return null;
        }
        return x;
    }
}

