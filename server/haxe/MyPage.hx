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

    static function init() {
        new JQuery('[timeline-id]').each(
            function(i: Int, elem: Dynamic) {
                fillTimeline(new JQuery(elem), null);
            });
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

    static function postArticle(ribbonId: Int, form: Dynamic) {
        JQuery._static.ajax({
            url: "/foo/ajax/m/newarticle",
            method: "post",
            data: {
                content: new JQuery(form).find('[name="content"]').val(),
                ribbon: ribbonId
            }
        }).done(function() {
        });
        form.find('[name="content"]').val('');
        form.find('textarea').focus();
    }

    static function postComment(ribbonId: Int, timelineId: Int,form: Dynamic) {
        JQuery._static.ajax({
            url: "/foo/ajax/m/newcomment",
            method: "post",
            data: {
                parent: new JQuery(form).find('[name="parent"]').val(),
                content: new JQuery(form).find('[name="content"]').val(),
                ribbon: ribbonId,
                timeline: timelineId
            }
        }).done(function() {
            openComments(getEntry(form).find('> .comments'));
            saveCommentFormOpenStates();
        });
        form.find('[name="content"]').val('');
        form.find('textarea').focus();
    }

    static function favor(ribbonId: Int, postId: Int) {
        JQuery._static.ajax({
            url: "/foo/ajax/m/favor",
            method: "post",
            data: {
                ribbon: ribbonId,
                target: postId
            }
        });
    }

    static function unfavor(ribbonId: Int, postId: Int) {
        JQuery._static.ajax({
            url: "/foo/ajax/m/unfavor",
            method: "post",
            data: {
                ribbon: ribbonId,
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

    static function chooseStamp(obj: Dynamic, ribbonId: Int, timelineId: Int) {
        var chooser: Dynamic = new JQuery('#stamp-chooser');
        chooser.find('a').each(
            function(i: Int, elem: Dynamic) {
                var e = new JQuery(elem);
                e.unbind('click');
                e.click(
                    function() {
                        postStamp(
                            ribbonId,
                            timelineId,
                            new JQuery(obj),
                            new JQuery(e));
                        chooser.close();
                    });
            });
        chooser.justModal();
    }

    static function makeBoard() {
        var dialog: Dynamic = new JQuery('#make-board');
        dialog.justModal();
    }

    static function joinBoard(ownername: String) {
        var dialog: Dynamic = new JQuery('#join-board');
        var userSelect: Dynamic = dialog.find('[name="user"]');
        var boardSelect: Dynamic = dialog.find('[name="board"]');
        var submit: Dynamic = dialog.find('[type="submit"]');

        clearSelect(userSelect);
        setupUserSelect(
            userSelect,
            ownername,
            function(userId: Int) {
                disable(submit);
                clearSelect(boardSelect);
                if (userId == 0) { return; }
                        
                setupBoardSelect(
                    boardSelect,
                    userId,
                    function(boardId: Int) {
                        setEnabled(submit, boardId != 0);
                    });
            });
        dialog.justModal();
    }

    static function makeRibbon() {
        var dialog: Dynamic = new JQuery('#make-ribbon');
        dialog.justModal();
    }

    static function joinRibbon(ownername: String) {
        var dialog: Dynamic = new JQuery('#join-ribbon');
        var userSelect: Dynamic = dialog.find('[name="user"]');
        var boardSelect: Dynamic = dialog.find('[name="board"]');
        var ribbonSelect: Dynamic = dialog.find('[name="ribbon"]');
        var submit: Dynamic = dialog.find('[type="submit"]');

        clearSelect(userSelect);
        setupUserSelect(
            userSelect,
            ownername,
            function(userId: Int) {
                disable(submit);
                clearSelect(boardSelect);
                clearSelect(ribbonSelect);
                if (userId == 0) { return; }
                        
                setupBoardSelect(
                    boardSelect,
                    userId,
                    function(boardId: Int) {
                        disable(submit);
                        clearSelect(ribbonSelect);
                        if (boardId == 0) { return; }

                        setupRibbonSelect(
                            ribbonSelect,
                            boardId,
                            function(ribbonId: Int) {
                                setEnabled(submit, ribbonId != 0);
                            });
                    });
            });
        dialog.justModal();
    }

    static function closeRibbon(obj: Dynamic, boardId: Int) {
        var ribbon = new JQuery(obj).closest('.ribbon');
        var ribbonId = ribbon.attr('ribbon-id');

        JQuery._static.ajax({
            url: "/foo/ajax/m/closeribbon",
            method: "post",
            data: {
                board: boardId,
                ribbon: ribbonId
            }
        }).done(function() {
            ribbon.closest('.ribbon-outer').remove();
        });
    }        

    static function editPermissions(
        boardId: Int, ribbonId: Int, isPublic: Bool) {
        var dialog: Dynamic = new JQuery('#edit-permission');
        dialog.find('[name="ribbon"]').val(ribbonId);
        if (isPublic) {
            dialog.find('[name="permission"][value="public"]').attr('checked', 'checked');
        } else {
            dialog.find('[name="permission"][value="private"]').attr('checked', 'checked');
        }

        dialog.justModal();
    }

    static function doPost(obj: Dynamic) {
        postForm(getForm(obj), function(s: String) {
                redirect(makeBoardUrl(s));
            });
        return false;
    }

    ////////////////////////////////////////////////////////////////
    // private functions
    static private function makeBoardUrl(boardname): String {
        var urlinfo: Dynamic = new JQuery('#board-url');
        var base_url = urlinfo.attr('base-url');
        var username = urlinfo.attr('username');
        return Std.format("$base_url/$username/$boardname");
    }

    static private function postForm(form: Dynamic, f: String->Void) {
        JQuery._static.ajax({
            url: form.attr('action'),
            method: form.attr('method'),
            data: form.serialize()
        }).done(function(data) {
            f(data);
        });
    }

    static private function enable(e: Dynamic) {
        e.removeAttr('disabled');
    }

    static private function disable(e: Dynamic) {
        e.attr('disabled', 'disabled');
    }

    static private function setEnabled(e: Dynamic, f: Bool) {
        if (f) {
            enable(e);
        } else {
            disable(e);
        }
    }
    
    static private function setupUserAndBoardSelect(
        dialog: Dynamic,
        ownername: String,
        userChange: Int->Void,
        boardChange: Int->Void) {
        var userSelect = dialog.find('[name="user"]');
        var boardSelect: Dynamic = dialog.find('[name="board"]');

        userChange(0);
    }

    static private function setupUserSelect(
        userSelect: Dynamic, ownername: String, f: Int->Void) {

        JQuery._static.ajax({
            url: "/foo/ajax/v/userlist",
            method: "get"
        }).done(function(data) {
            userSelect.append('<option value="0">所有者を選択</option>');
                
            var users: Array<Dynamic> = JQuery._static.parseJSON(data);
            for(v in users) {
                var userId: Int = v[0];
                var username: String = v[1];
                var userlabel: String = v[2];
                if (ownername == username) {
                    continue;
                }

                userSelect.append(
                    Std.format('<option value="$userId">$username - $userlabel</option>'));
            }
            userSelect.unbind('change');
            userSelect.change(
                function(e: Dynamic) {
                    f(getSelected(e.target).val());
                });
            enable(userSelect);
        });
    }

    static private function setupBoardSelect(
        boardSelect: Dynamic, userId: Int, f: Int->Void) {
        
        JQuery._static.ajax({
            url: Std.format("/foo/ajax/v/boardlist?user=${userId}"),
            method: "get"
        }).done(function(data) {
            boardSelect.append('<option value="0">ボードを選択</option>');
                
            var boards: Array<Dynamic> = JQuery._static.parseJSON(data);
            for(v in boards) {
                var boardId: Int = v[0];
                var boardlabel: String = v[1];

                var disabled: String =
                    0 < new JQuery('[board-id="$boardId"]').length ?
                    ' disabled="disabled"' : '';

                boardSelect.append(
                    Std.format('<option value="$boardId"${disabled}>$boardlabel</option>'));
            }
            boardSelect.unbind('change');
            boardSelect.change(
                function(e: Dynamic) {
                    f(getSelected(e.target).val());
                });
            enable(boardSelect);
        });
    }

    static private function setupRibbonSelect(
        ribbonSelect: Dynamic, boardId: Int, f: Int->Void) {
        
        JQuery._static.ajax({
            url: Std.format("/foo/ajax/v/ribbonlist?board=$boardId"),
            method: "get"
        }).done(function(data) {
            ribbonSelect.append('<option value="0">リボンを選択</option>');
                
            var ribbons: Array<Dynamic> = JQuery._static.parseJSON(data);
            for(v in ribbons) {
                var ribbonId: Int = v[0];
                var ribbonLabel: String = v[1];

                ribbonSelect.append(
                    Std.format('<option value="$ribbonId">$ribbonLabel</option>'));
            }
            ribbonSelect.unbind('change');
            ribbonSelect.change(
                function(e: Dynamic) {
                    f(getSelected(e.target).val());
                });
            enable(ribbonSelect);
        });
    }

    static private function postStamp(
        ribbonId: Int, timelineId: Int, source: Dynamic, selected: Dynamic) {
        var form = source.closest('.comment-form').find('> form');
        var image = selected.attr('image');
        JQuery._static.ajax({
            url: "/foo/ajax/m/stamp",
            method: "post",
            data: {
                ribbon: ribbonId,
                timeline: timelineId,
                parent: form.find('[name="parent"]').val(),
                content: image
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
    
    static private function fetchTimeline(
        oldTimeline: Dynamic,
        newestScore: Dynamic,
        oldestScore: Dynamic,
        version: Int) {

        var ribbonId = Std.parseInt(oldTimeline.attr('ribbon-id'));
        var timelineId = Std.parseInt(oldTimeline.attr('timeline-id'));
        var level = Std.parseInt(oldTimeline.attr('level'));

        if (!startLoad(oldTimeline, version)) {
            return;
        }

        JQuery._static.ajax({ 
            url: "/foo/ajax/v/timeline",
            data: {
                ribbon: ribbonId,
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

        if (newTimeline.children().length == 0) {
            return;
        }

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

    static private function getForm(obj: Dynamic): JQuery {
        var e = new JQuery(obj);
        if (e.is('form')) {
            return e;
        } else {
            return e.closest("form");
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
        new JQuery(Std.format('[timeline-id="$timelineId"]')).each(
            function(i: Int, elem: Dynamic) {
                fillNewerTimeline(new JQuery(elem), version);
            });
    }

    static function updateDetail(postId: Int, version: Int) {
        var posts = new JQuery(Std.format('[post-id="$postId"]'));
        posts.each(
            function(i: Int, e: Dynamic) {
                var post = new JQuery(e);
                var ribbonId = post.closest('.ribbon').attr('ribbon-id');
                var level = Std.parseInt(post.parent().attr('level'));

                JQuery._static.ajax({
                    url: "/foo/ajax/v/detail",
                    data: {
                        ribbon: ribbonId,
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

    static private function redirect(url: String) {
        js.Lib.window.location.href = url;
    }

    static private function getThis(): Dynamic {
        return untyped __js__('$(this)');
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

    static private function getSelected(select: Dynamic) {
        return new JQuery(select).find(':selected');
    }

    static private function clearSelect(select: Dynamic) {
        disable(select);
        select.html('');
    }
}

