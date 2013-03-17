function openComments(obj) {
    $(obj).parent().parent().find('> .comments').toggle();
}

function openCommentForm(obj) {
    $(obj).parent().parent().find('> .comment-form').toggle();
}

function fillRoot() {
    $.ajax({
        url: "/foo/p/user_timeline"
    }).done(function(data) {
        console.log(data);
        $('#root').html(data);
    });
}

function postArticle(form) {
    $.ajax({
        url: "/foo/p/newarticle",
        method: "post",
        data: {
            content: $(form).find('[name="content"]').val()
        }
    }).done(function(data) {
        $('#root').html(data);
    });
}

function postComment(form) {
    $.ajax({
        url: "/foo/p/newcomment",
        method: "post",
        data: {
            parent: $(form).find('[name="parent"]').val(),
            content: $(form).find('[name="content"]').val()
        }
    }).done(function(data) {
        $('#root').html(data);
    });
}
