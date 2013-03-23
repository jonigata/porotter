var MyPage = (function() {

    var io = null;
    var connected = false;

    // 親方向最内の'entry'クラスつきjQueryオブジェクトを得る
    function getEntry(obj) {
        var e = $(obj);
        if (e.is('.entry')) {
            return e;
        } else {
            return $(e.parents(".entry")[0]);
        }
    }

    function saveOpenStates() {
        var a = $('.comments:visible').map(function(i, e) {
            return $(e).find('> .posts').attr('timeline-id') - 0;
        });
        $.cookie.json = true;
        $.cookie('opened', a.get(), { expires: 7 });
    }

    function loadOpenStates() {
        $.cookie.json = true;
        var rawOpened = $.cookie('opened');
        var opened = {};
        for(var i = 0; i < rawOpened.length ; i++) {
            opened[rawOpened[i]] = rawOpened[i];
        }
        $('.comments').each(function(i, e) {
            var timelineId = $(e).find('> .posts').attr('timeline-id') - 0;
            if (opened[timelineId] != null) {
                $(e).show();
            }
        });
        updateCommentDisplayText();
        subscribeTimelines();
    }

    function scrollToElement(e) {
        var bottomMargin = 32;
        $(document).scrollTop(
            e.offset().top - $(window).height() + e.height() + bottomMargin);
    }

    function subscribeTimelines() {
        if (connected) {
            var targets = $('[timeline-id]:visible').map(function(i, e) {
                return $(e).attr('timeline-id') - 0;
            });
            io.push("watch", {targets: targets.get()});
        }
    }

    function updateCommentDisplayText() {
        $('.comments').each(function(i, e) {
            var comments = $(e);
            var entry = getEntry(e);
            var showComment = entry.find('> .operation .show-comment');
            if (comments.is(':visible')) {
                showComment.html('コメントを隠す');
            } else {
                var count = comments.find('> .posts > .post').length;
                showComment.html('コメントを見る(' + count + ')');
            }
        });
    }

    function startLoad(posts, version) {
        if (posts.attr('loading')) {
            console.log("タイムライン取得中なので待機キューに入れる");
            posts.attr('waiting', version);
            return false;
        }

        if (version != null) {
            if (version <= posts.attr('version') - 0) {
                console.log('version older or equal');
                return false;
            }
        }

        posts.attr('loading', 'true');
        return true;
    }

    function finishLoad(posts, f) {
        var timelineId = posts.attr('timeline-id');

        posts.removeAttr('loading');
        var waitingVersion = posts.attr('waiting');
        posts.removeAttr('waiting');

        f();

        if (waitingVersion != null) {
            // loading中に更新リクエストが来ている場合は再試行
            console.log("waiting versionの取得を開始");
            fillPosts(timelineId, waitingVersion - 0);
        }
    }

    function fillPosts(timelineId, version) {
        var posts = $('[timeline-id="' +timelineId+ '"]');

        if (!startLoad(posts, version)) {
            return;
        }

        var isRoot = posts.parent().is('#root');

        $.ajax({
            url: "/foo/p/timeline",
            data: {
                timeline: timelineId,
                direction: (isRoot ? 'upward' : 'downward'),
                comment: (isRoot ? 'enabled' : 'disabled')
            }
        }).done(function(data) {
            finishLoad(posts, function() {
                posts.replaceWith(data);
                if (isRoot) {
                    loadOpenStates();
                } else {
                    updateCommentDisplayText();
                }
            });
        });
        
    }

    function updateTimeline(timelineId, version) {
        console.log("update timeline");
        fillPosts(timelineId, version);
    }

    function updatePost(postId, version) {
    }

    function startWatch() {
        io = new RocketIO().connect();
        io.on("connect", function(session) {
            connected = true;
            subscribeTimelines();
        });
        io.on("watch-timeline", function(data) {
            console.log("timeline update signal received");
            console.log(data);
            updateTimeline(data.timeline, data.version);
        });
    }

    var exports = {
        toggleComments: function(obj) {
            var entry = getEntry(obj);
            var comments = entry.find('> .comments');
            comments.toggle();
            updateCommentDisplayText();
            subscribeTimelines();
            saveOpenStates();
        },

        toggleCommentForm: function(obj) {
            var commentForm = getEntry(obj).find('> .comment-form');
            commentForm.toggle();
            if (commentForm.is(':visible')) {
                scrollToElement(commentForm);
            }
        },

        scrollToEntryTail: function(obj) {
            scrollToElement(getEntry(obj));
        },

        postArticle: function(timelineId, form) {
            var self = this;
            $.ajax({
                url: "/foo/m/newarticle",
                method: "post",
                data: {
                    content: $(form).find('[name="content"]').val(),
                    timeline: timelineId
                }
            }).done(function() {
                fillPosts(timelineId);
            });
            form.find('[name="content"]').val('');
        },

        postComment: function(timelineId, form) {
            var self = this;
            $.ajax({
                url: "/foo/m/newcomment",
                method: "post",
                data: {
                    parent: $(form).find('[name="parent"]').val(),
                    content: $(form).find('[name="content"]').val(),
                    timeline: timelineId
                }
            }).done(function() {
                fillPosts(timelineId);
            });
            form.find('[name="content"]').val('');
        },

        favor: function(postId) {
            $.ajax({
                url: "/foo/m/favor",
                data: {
                    target: postId
                }
            });
        },

        init: function(timelineId) {
            fillPosts(timelineId);
            startWatch();
        }
    };
    
    return exports;
})();