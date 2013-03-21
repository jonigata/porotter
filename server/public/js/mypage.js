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
    var raw_opened = $.cookie('opened');
    var opened = {};
    for(var i = 0; i < raw_opened.length ; i++) {
        opened[raw_opened[i]] = raw_opened[i];
    }
    
    $('.comments').each(function(i, e) {
        var timeline_id = $(e).find('> .posts').attr('timeline-id') - 0;
        if (opened[timeline_id] != null) {
            $(e).show();
        }
    });
}

function toggleComments(obj) {
    var entry = getEntry(obj);
    var comments = entry.find('> .comments');
    comments.toggle();
    var posts = comments.find('> .posts');
    if (0 < posts.length) {
        var show_comment = entry.find('> .operation .show-comment');
        if (comments.is(':visible')) {
            watchTimeline(comments.find('> .posts').attr('timeline-id') - 0);
            show_comment.html('コメントを隠す');
        } else {
            unwatchTimeline(comments.find('> .posts').attr('timeline-id') - 0);
            var commentCount = comments.find('.posts .post').length;
            show_comment.html('コメントを見る(' + commentCount + ')');
        }
    }
    saveOpenStates();
}

function toggleCommentForm(obj) {
    getEntry(obj).find('> .comment-form').toggle();
}

function scrollToLastComment(obj) {
    $(document).scrollTop(getEntry(obj).find('> .operation').offset().top);
}

function fillRoot(timelineId) {
    console.log("fillRoot " + timelineId);
    $.ajax({
        url: "/foo/p/timeline",
        data: {
            timeline: timelineId,
            direction: 'upward',
            comment: 'enabled'
        }
    }).done(function(data) {
        saveOpenStates();
        $('#root').html(data);
        clearWatchees();
        watchTimeline(timelineId);
        loadOpenStates();
    });
}

function fillComment(e, timelineId) {
    console.log("fillComment " + timelineId);
    $.ajax({
        url: "/foo/p/timeline",
        data: {
            timeline: timelineId,
            direction: 'downward',
            comment: 'disabled'
        }
    }).done(function(data) {
        console.log(data);
        var entry = getEntry(e);
        e.replaceWith(data);
        var commentCount = entry.find('.comments .posts .post').length;
        entry.find('> .operation .show-comment').html('コメントを見る(' + commentCount + ')');
        scrollToLastComment(e);
    });
}

function postArticle(timelineId, form) {
    $.ajax({
        url: "/foo/m/newarticle",
        method: "post",
        data: {
            content: $(form).find('[name="content"]').val(),
            timeline: timelineId
        }
    });
    form.find('[name="content"]').val('');
}

function postComment(timelineId, form) {
    $.ajax({
        url: "/foo/m/newcomment",
        method: "post",
        data: {
            parent: $(form).find('[name="parent"]').val(),
            content: $(form).find('[name="content"]').val(),
            timeline: timelineId
        }
    });
    form.find('[name="content"]').val('');
}

function updateTimeline(timelineId) {
    if (timelineId == $('#root > .posts').attr('timeline-id') - 0) {
        fillRoot(timelineId);
    } else {
        fillComment($('.posts[timeline-id="'+timelineId+'"]'), timelineId);
    }
}