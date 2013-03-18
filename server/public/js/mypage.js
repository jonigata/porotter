function openComments(obj) {
    $(obj).parent().parent().find('> .comments').toggle();
}

function openCommentForm(obj) {
    $(obj).parent().parent().find('> .comment-form').toggle();
}

function fillRoot(timelineId) {
    console.log(timelineId);
    $.ajax({
        url: "/foo/p/timeline",
        data: {
            timeline: timelineId
        }
    }).done(function(data) {
        console.log(data);
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
        console.log(timelineId);
        $('#root').html(data);
    });
    form.find('[name="content"]').val('');
}
