function openComments(obj) {
    $(obj).parents(".entry").find('> .comments').toggle();
}

function openCommentForm(obj) {
    $(obj).parents(".entry").find('> .comment-form').toggle();
}

function fillRoot(timelineId) {
    $.ajax({
        url: "/foo/p/timeline",
        data: {
            timeline: timelineId
        }
    }).done(function(data) {
        $('#root').html(data);
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
        $($(form).parents(".entry")[0]).find('> .comments').html(data);
    });
    form.find('[name="content"]').val('');
}
