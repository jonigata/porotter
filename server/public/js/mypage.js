function getEntry(obj) {
    return $($(obj).parents(".entry")[0]);
}

function openComments(obj) {
    var comments = getEntry(obj).find('> .comments');
    comments.toggle();
    var posts = comments.find('> .posts');
    if (0 < posts.length) {
        if (comments.is(':visible')) {
            watchTimeline(comments.find('> .posts').attr('timeline-id') - 0);
        } else {
            unwatchTimeline(comments.find('> .posts').attr('timeline-id') - 0);
        }
    }
}

function openCommentForm(obj) {
    getEntry(obj).find('> .comment-form').toggle();
}

function scrollToLastComment(obj) {
    $(document).scrollTop(getEntry(obj).find('> .operation').offset().top);
}

function fillRoot(timelineId) {
    $.ajax({
        url: "/foo/p/timeline",
        data: {
            timeline: timelineId
        }
    }).done(function(data) {
        $('#root').html(data);
        clearWatchees();
        watchTimeline(timelineId);
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
    }).done(function(data) {
        $('#root').html(data);
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
    }).done(function(data) {
        getEntry(form).find('> .comments').html(data);
    });
    form.find('[name="content"]').val('');
}


