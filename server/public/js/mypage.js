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
    saveOpenStates();
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
        loadOpenStates();
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


