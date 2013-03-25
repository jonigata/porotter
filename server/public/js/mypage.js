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
        subscribePosts();
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
            io.push("watch-timeline", {targets: targets.get()});
        }
    }

    function subscribePosts() {
        if (connected) {
            var targets = $('[post-id]:visible').map(function(i, e) {
                return $(e).attr('post-id') - 0;
            });
            io.push("watch-post", {targets: targets.get()});
        }
    }

    function updateCommentDisplayText() {
        $('.comments').each(function(i, e) {
            var comments = $(e);
            var entry = getEntry(e);
            var showComment = entry.find('> .operation .show-comment-label');
            if (comments.is(':visible')) {
                showComment.html('隠す');
            } else {
                var count = entry.find('> .detail').attr('comment-count') - 0;
                showComment.html('×' + count + '');
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
        var level = posts.attr('level') - 0;

        if (!startLoad(posts, version)) {
            return;
        }

        $.ajax({
            url: "/foo/p/timeline",
            data: {
                timeline: timelineId,
                level: level
            }
        }).done(function(data) {
            finishLoad(posts, function() {
                var entry = getEntry(posts);
                var newPosts = $(data);
                posts.replaceWith(newPosts);
                if (level == 0) {
                    loadOpenStates();
                } else {
                    var count = newPosts.find('> .post').length;
                    entry.find('> .detail').attr('comment-count', count);
                    updateCommentDisplayText();
                    subscribePosts();
                }
            });
        });
        
    }

    function updateTimeline(timelineId, version) {
        console.log("update timeline");
        fillPosts(timelineId, version);
    }

    function updateDetail(postId, version) {
        var post = $('[post-id="' + postId + '"]');
        var level = post.parent().attr('level') - 0;

        $.ajax({
            url: "/foo/p/detail",
            data: {
                post: postId,
                level: level
            }
        }).done(function(data) {
            console.log('updateDetail data incomming');
            post.find('> .entry > .detail').replaceWith(data);
            updateCommentDisplayText();
        });
    }

    function startWatch() {
        io = new RocketIO().connect();
        io.on("connect", function(session) {
            connected = true;
            subscribeTimelines();
            subscribePosts();
        });
        io.on("watch-timeline", function(data) {
            console.log("timeline update signal received");
            console.log(data);
            updateTimeline(data.timeline, data.version);
        });
        io.on("watch-post", function(data) {
            console.log("post update signal received");
            console.log(data);
            updateDetail(data.post, data.version);
        });
    }

    var exports = {
        toggleComments: function(obj) {
            var entry = getEntry(obj);
            var comments = entry.find('> .comments');
            comments.toggle();
            if (comments.is(':visible')) {
                var idealVersion = entry.find('> .detail').attr(
                    'comments-version');
                if (idealVersion != null) {
                    idealVersion -= 0;
                    var posts = comments.find('> .posts');
                    var actualVersion = posts.attr('version') - 0;
                    if (actualVersion < idealVersion) {
                        var timelineId = posts.attr('timeline-id') - 0;
                        fillPosts(timelineId, idealVersion);
                    }
                }
            }
            updateCommentDisplayText();
            subscribeTimelines();
            subscribePosts();
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
            form.find('textarea').focus();
        },

        postComment: function(timelineId, form) {
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
                var entry = getEntry(form);
                var comments = entry.find('> .comments');
                if (!comments.is(':visible')) {
                    this.toggleComments(entry);
                }
            });
            form.find('[name="content"]').val('');
            form.find('textarea').focus();
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