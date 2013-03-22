var MyPage = (function() {

    // 親方向最内の'entry'クラスつきjQueryオブジェクトを得る
    function getEntry(obj) {
        return $($(obj).parents(".entry")[0]);
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
                var showComment =
                        getEntry(e).find('> .operation .show-comment');
                showComment.html('コメントを隠す');
            }
        });
    }

    function scrollToElement(e) {
        var bottomMargin = 32;
        $(document).scrollTop(
            e.offset().top - $(window).height() + e.height() + bottomMargin);
    }

    var exports = {
        toggleComments: function(obj) {
            var entry = getEntry(obj);
            var comments = entry.find('> .comments');
            comments.toggle();
            var posts = comments.find('> .posts');
            if (0 < posts.length) {
                var showComment = entry.find('> .operation .show-comment');
                if (comments.is(':visible')) {
                    updateWatchingTimelines();
                    showComment.html('コメントを隠す');
                    this.scrollToEntryTail(entry);
                } else {
                    updateWatchingTimelines();
                    var commentCount = comments.find('.posts .post').length;
                    showComment.html('コメントを見る(' + commentCount + ')');
                }
            }
            saveOpenStates();
        },

        toggleCommentForm: function(obj) {
            var commentForm = getEntry(obj).find('> .comment-form');
            commentForm.toggle();
            if (commentForm.is(':visible')) {
                scrollToElement(commentForm);
            }
        },

        fillPosts: function(posts, version) {
            if (posts.attr('loading')) {
                console.log("タイムライン取得中なので待機キューに入れる");
                posts.attr('waiting', version);
                return;
            }

            if (version != null) {
                if (version <= posts.attr('version') - 0) {
                    return;
                }
            }

            posts.attr('loading', 'true');

            var timelineId = posts.attr('timeline-id');

            var isRoot =
                    timelineId == $('#root > .posts').attr('timeline-id') - 0;

            var self = this;

            $.ajax({
                url: "/foo/p/timeline",
                data: {
                    timeline: timelineId,
                    direction: (isRoot ? 'upward' : 'downward'),
                    comment: (isRoot ? 'enabled' : 'disabled')
                }
            }).done(function(data) {
                posts.removeAttr('loading');
                var waitingVersion = posts.attr('waiting');
                var entry = getEntry(posts);
                if (isRoot) {
                    posts.replaceWith(data);
                    loadOpenStates();
                } else {
                    posts.replaceWith(data);
                    var commentCount =
                            entry.find('> .comments > .posts > .post').length;
                    entry.find('> .operation .show-comment').html('コメントを見る(' + commentCount + ')');
                }

                if (waitingVersion != null) {
                    // loading中に更新リクエストが来ている場合は再試行
                    console.log("waiting versionの取得を開始");
                    var newPosts = entry.find('> .comments > .posts');
                    self.fillPosts(newPosts, waitingVersion - 0);
                }
                
            });
            
        },

        scrollToEntryTail: function(obj) {
            if ($(obj).is('.entry')) {
                scrollToElement($(obj));
            } else {
                scrollToElement(getEntry(obj));
            }
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
                self.fillPosts($('[timeline-id="' +timelineId+ '"]'));
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
                self.fillPosts($('[timeline-id="' +timelineId+ '"]'));
            });
            form.find('[name="content"]').val('');
        },

        updateTimeline: function(timelineId, version) {
            this.fillPosts($('[timeline-id="' +timelineId+ '"]'), version);
        }
    }
    
    return exports;
})();