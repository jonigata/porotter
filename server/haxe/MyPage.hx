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
                var timeline: Dynamic = new JQuery(elem);
                fillTimeline(timeline, null);

                if (!timeline.is('[editable="true"]')) {
                    return;
                }
                timeline.sortable({
                      handle: '.drag-handle',  
                      connectWith: '[timeline-id][editable="true"]',
                            update: function(event: Dynamic, ui: Dynamic) {
                            if (ui.sender == null) {
                                if (ui.item.parent()[0] == timeline[0]) {
                                    trace("same timeline move");
                                    moveArticle(ui.item);
                                } else {
                                    // discard
                                    trace("discard");
                                }
                            } else {
                                trace("different timeline move");
                                transferArticle(ui.item, ui.sender);
                            }
                        }
                    });
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

    static function joinBoard() {
        var dialog: Dynamic = new JQuery('#join-board');
        var userSelect: Dynamic = dialog.find('[name="user"]');
        var boardSelect: Dynamic = dialog.find('[name="board"]');
        var submit: Dynamic = dialog.find('[type="submit"]');

        var username = getUserName();

        var boardMenu = new JQuery('#board-menu');
        var boardExists = function(boardId: Int): Bool {
            var options = boardMenu.find(Std.format('[board-id="$boardId"]'));
            return 0 < options.length;
        };

        boardSelect.val(0);
        disable(boardSelect);
        setupUserSelect(
            userSelect,
            function() {
                userSelect.find('option').each(
                    function(i: Int,elem: Dynamic) {
                        var e = new JQuery(elem);
                        setEnabled(e, e.attr('username') != getUserName());
                    });
            },
            function(userId: Int) {
                disable(submit);
                clearSelect(boardSelect);
                if (userId == 0) { return; }
                        
                setupBoardSelect(
                    boardSelect,
                    userId,
                    function(boardId: Int) {
                        return !boardExists(boardId);
                    },
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

        var currentBoardId = getBoardId();

        boardSelect.val(0);
        disable(boardSelect);
        ribbonSelect.val(0);
        disable(ribbonSelect);
        setupUserSelect(
            userSelect,
            function() {
            },
            function(userId: Int) {
                disable(submit);
                clearSelect(boardSelect);
                clearSelect(ribbonSelect);
                if (userId == 0) { return; }
                        
                setupBoardSelect(
                    boardSelect,
                    userId,
                    function(boardId: Int) {
                        return boardId != currentBoardId;
                    },
                    function(boardId: Int) {
                        disable(submit);
                        clearSelect(ribbonSelect);
                        if (boardId == 0) { return; }

                        setupRibbonSelect(
                            ribbonSelect,
                            boardId,
                            true,
                            function(ribbonId: Int) {
                                setEnabled(submit, ribbonId != 0);
                            });
                    });
            });
        dialog.justModal();
    }

    static function restoreRibbon(boardId: Int) {
        var dialog: Dynamic = new JQuery('#restore-ribbon');
        var ribbonSelect: Dynamic = dialog.find('[name="ribbon"]');
        var submit: Dynamic = dialog.find('[type="submit"]');

        clearSelect(ribbonSelect);
        setupRemovedRibbonSelect(
            ribbonSelect,
            boardId,
            true,
            function(ribbonId: Int) {
                setEnabled(submit, ribbonId != 0);
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

    static function editRibbonSettings(
        dialog: Dynamic, boardId: Int, ribbonId: Int) {
        setupRadio(dialog, "read_permission");
        setupRadio(dialog, "write_permission");
        setupRadio(dialog, "edit_permission");

        setupEditGroupButton(dialog.find('#edit-readable-group'));
        setupEditGroupButton(dialog.find('#edit-writable-group'));
        setupEditGroupButton(dialog.find('#edit-editable-group'));

        dialog.justModal();
    }

    static function moveArticle(dragging: Dynamic) {
        var ribbonId: Int = Std.parseInt(dragging.parent().attr('ribbon-id'));

        var postId: Int = Std.parseInt(dragging.attr('post-id'));
        var target: Dynamic = dragging.next();
        trace(target);
        var targetId = 0;
        if (0 < target.length && target.is('article')) {
            targetId = target.attr('post-id');
        }

        JQuery._static.ajax({
            url: "/foo/ajax/m/movearticle",
            method: "post",
            data: {
                ribbon: ribbonId,
                source: postId,
                target: targetId
            }
        }).done(function(data) {
            trace("movearticle done");
        });
    }

    static function transferArticle(dragging: Dynamic, sourceRibbon: Dynamic) {
        var sourceRibbonId: Int = Std.parseInt(sourceRibbon.attr('ribbon-id'));
        var targetRibbon: Dynamic = dragging.parent();
        var targetRibbonId: Int = Std.parseInt(targetRibbon.attr('ribbon-id'));

        var postId: Int = Std.parseInt(dragging.attr('post-id'));
        var target: Dynamic = dragging.next();
        trace(target);
        var targetId = 0;
        if (0 < target.length && target.is('article')) {
            targetId = target.attr('post-id');
        }

        JQuery._static.ajax({
            url: "/foo/ajax/m/transferarticle",
            method: "post",
            data: {
                source_ribbon: sourceRibbonId,
                target_ribbon: targetRibbonId,
                source: postId,
                target: targetId
            }
        }).done(function(data) {
            trace("movearticle done");
        });
    }

    static function doPost(obj: Dynamic) {
        postForm(getForm(obj), function(s: Dynamic) {
                redirect(makeBoardUrl(s[0], s[1]));
            });
        return false;
    }

    static function doRibbonTest(ribbonId: Int) {
        JQuery._static.ajax({
            url: "/foo/ajax/m/ribbontest",
            method: "post",
            data: {
                ribbon: ribbonId,
            }
        }).done(function(data) {
            trace("ribbontest done");
        });
    }

    static function editBoardSettings() {
        var dialog: Dynamic = new JQuery('#board-settings');

        setupRadio(dialog, "read_permission");
        setupRadio(dialog, "write_permission");
        setupRadio(dialog, "edit_permission");

        setupEditGroupButton(dialog.find('#edit-readable-group'));
        setupEditGroupButton(dialog.find('#edit-writable-group'));
        setupEditGroupButton(dialog.find('#edit-editable-group'));

        dialog.justModal();
    }

    static function setupEditGroupButton(button: Dynamic) {
        updateStatus(button, ['active', 'loaded'], 'loaded', false);

        var groupId = Std.parseInt(button.attr('group-id'));
        var storeName = button.attr('store');
        var displayId = button.attr('display');
        var form: Dynamic = button.closest('form');
        var store: Dynamic = form.find(Std.format('[name="$storeName"]'));
        var display: Dynamic = form.find(Std.format('#$displayId'));
        
        JQuery._static.ajax({
            url: "/foo/ajax/v/group",
            method: "get",
            data: {
                group: groupId,
            },
            dataType: 'jsonp'
        }).done(function(data) {
            updateStatus(button, ['active', 'loaded'], 'loaded', true);

            updateGroupStore(store, data);
            updateGroupDisplay(display, data);

            button.unbind('click');
            button.click(
                function(e: Dynamic) {
                    editGroup(
                        data,
                        function(data: Dynamic) {
                            updateGroupStore(store, data);
                            updateGroupDisplay(display, data);
                        });
                    return false;
                });
         });
    }

    static private function updateGroupStore(store: Dynamic, data: Dynamic) {
        // <input type="hidden" name="readable_store">の修正
        // ex: store.val("[1,7,9,36]")
        var memberSet: Array<Int> = [];
        var members: Array<Dynamic> = data.members;
        for(v in members) {
            memberSet.push(v.userId);
        }
        trace(memberSet);
        memberSet.sort(function(a: Int, b: Int) { return a - b; });
        trace(memberSet);

        store.val(JSON.stringify(memberSet));
    }

    static private function updateGroupDisplay(
        display: Dynamic, data: Dynamic) {

        var members: Array<Dynamic> = data.members;

        display.html('');
        if (members.length == 0) {
            display.html('<p>ユーザが含まれていません</p>');
        } else {
            for(v in members) {
                display.append(
                    gravatar(v.gravatar, 16, v.userId, v.username, v.label));
            }
        }
        display.find('img').tooltip();
        display.find('img').draggable({revert: "invalid"});

        // ゴミ箱
        var trash: Dynamic = new JQuery(".group-member-trash");
        trash.droppable({
            accept: '[user-id]',
            drop: function(e, ui) {
                trace('deleted');
                trace(ui.draggable);
                var e: Dynamic = new JQuery(ui.draggable);
                e.tooltip('hide');
                e.remove();
                updateMemberSet(display, data);
            }
        });

        updateMemberSet(display);
    }

    static private function updateMemberSet(display: Dynamic) {
        // member-setを作成
        var memberSet: Array<Int> = [];
        display.find('img').each(
            function(i: Int, elem: Dynamic) {
                var e = new JQuery(elem);
                memberSet.push(Std.parseInt(e.attr('user-id')));
            });
        memberSet.sort(function(a: Int, b: Int) { return a - b; });

        display.attr('member-set', JSON.stringify(memberSet));
    }

    static function editGroup(data: Dynamic, cb: Dynamic->Void) {
        var dialog: Dynamic = new JQuery('#edit-group');
        var display: Dynamic = dialog.find('.group-members');

        // 完了ボタン
        var submit: Dynamic = dialog.find('input:submit');
        submit.unbind('click');
        submit.click(
            function() {
                cb(data);
                dialog.close();
                return false;
            });

        // メンバー一覧
        updateGroupDisplay(display, data);
        var oldMemberSet = display.attr('member-set');

        // グループ名
        var groupName: Dynamic = dialog.find('[name="group_name"]');
        groupName.val(data.name);
        setEnabled(groupName, data.nameEditable);

        // 追加ユーザセレクト
        var userSelect: Dynamic = dialog.find('[name="user"]');
        var updateUI = function() {
            userSelect.val(0);
            userSelect.find('option').each(
                function(i: Int,elem: Dynamic) {
                    var e = new JQuery(elem);
                    var userId = e.attr('user-id');
                    var filter = Std.format('[user-id="$userId"]');
                    setEnabled(e, display.find(filter).length == 0);
                });
        };

        // 追加ユーザボタン
        var addButton: Dynamic = dialog.find('#add-member');
        disable(addButton);
        setupUserSelect(
            userSelect,
            function() {
                updateUI();
            },
            function(userId: Int) {
                setEnabled(addButton, userId != 0);
            });

        addButton.unbind('click');
        addButton.click(function() {
                display.find('p').remove('');
                var s = userSelect.find(':selected');
                var member = {
                  userId : Std.parseInt(s.attr('user-id')),
                  username : s.attr('username'),
                  label : s.attr('label'),
                  gravatar : s.attr('icon')
                };
                data.members.push(member);

                updateGroupDisplay(display, data);
                updateUI();

                setEnabled(submit, oldMemberSet != display.attr('member-set'));
            });

        updateUI();

        dialog.justModal({overlayZIndex: 20050, modalZIndex: 20100});
    }

    ////////////////////////////////////////////////////////////////
    // private functions
    static private function makeBoardUrl(username, boardname): String {
        var urlinfo: Dynamic = new JQuery('#basic-data');
        var base_url = urlinfo.attr('base-url');
        return Std.format("$base_url/$username/$boardname");
    }

    static private function getUserName(): String {
        return getBasicDataAttr('username');
    }

    static private function getUserId(): String {
        return getBasicDataAttr('user-id');
    }

    static private function getOwnerName(): String {
        return getBasicDataAttr('owner-name');
    }

    static private function getReferedName(): String {
        return getBasicDataAttr('refered-name');
    }

    static private function getBoardId(): Int {
        return Std.parseInt(getBasicDataAttr('board-id'));
    }

    static private function getBasicDataAttr(a): String {
        var data: Dynamic = new JQuery('#basic-data');
        return data.attr(a);
    }

    static private function postForm(form: Dynamic, f: String->Void) {
        JQuery._static.ajax({
            url: form.attr('action'),
            method: form.attr('method'),
            data: form.serialize(),
            dataType: 'jsonp'
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
    
    static private function setupUserSelect(
        userSelect: Dynamic,
        onLoad: Void->Void,
        onChange: Int->Void) {

        disable(userSelect);
        clearSelect(userSelect);
        JQuery._static.ajax({
            url: "/foo/ajax/v/userlist",
            method: "get"
        }).done(function(data) {
            userSelect.append('<option value="0">所有者を選択</option>');
                
            var users: Array<Dynamic> = JQuery._static.parseJSON(data);
            for(v in users) {
                var userId: Int = v[0];
                var username: String = v[1];
                var userLabel: String = v[2];
                var userIcon: String = v[3];

                userSelect.append(
                    Std.format('<option value="$userId" user-id="$userId" username="$username" label="$userLabel" icon="$userIcon">$username - $userLabel</option>'));
            }
            userSelect.unbind('change');
            userSelect.change(
                function(e: Dynamic) {
                    onChange(getSelected(e.target).val());
                });
            enable(userSelect);

            onLoad();
        });
    }

    static private function setupBoardSelect(
        boardSelect: Dynamic,
        userId: Int,
        filter: Int->Bool,
        onChange: Int->Void) {
        
        JQuery._static.ajax({
            url: Std.format("/foo/ajax/v/boardlist?user=${userId}"),
            method: "get"
        }).done(function(data) {
            boardSelect.append('<option value="0">ボードを選択</option>');
                
            var boards: Array<Dynamic> = JQuery._static.parseJSON(data);
            for(v in boards) {
                var boardId: Int = v.boardId;
                var boardlabel: String = v.label;

                var disabled: String =
                    filter(boardId) ? '' : ' disabled="disabled"';

                boardSelect.append(
                    Std.format('<option value="$boardId"$disabled>$boardlabel</option>'));
            }
            boardSelect.unbind('change');
            boardSelect.change(
                function(e: Dynamic) {
                    onChange(getSelected(e.target).val());
                });
            enable(boardSelect);
        });
    }

    static private function setupRibbonSelect(
        ribbonSelect: Dynamic, boardId: Int, disableDup: Bool, f: Int->Void) {
        
        JQuery._static.ajax({
            url: Std.format("/foo/ajax/v/ribbonlist?board=$boardId"),
            method: "get"
        }).done(function(data) {
            ribbonSelect.append('<option value="0">リボンを選択</option>');
                
            var ribbons: Array<Dynamic> = JQuery._static.parseJSON(data);
            for(v in ribbons) {
                var ribbonId: Int = v.ribbonId;
                var ribbonLabel: String = v.label;

                var disabled: String = '';
                if (disableDup && 
                    0 < new JQuery(Std.format('[ribbon-id="$ribbonId"]')).length) {
                    disabled = ' disabled="disabled"';
                }

                ribbonSelect.append(
                    Std.format('<option value="$ribbonId"$disabled>$ribbonLabel</option>'));
            }
            ribbonSelect.unbind('change');
            ribbonSelect.change(
                function(e: Dynamic) {
                    f(getSelected(e.target).val());
                });
            enable(ribbonSelect);
        });
    }

    static private function setupRemovedRibbonSelect(
        ribbonSelect: Dynamic, boardId: Int, disableDup: Bool, f: Int->Void) {
        
        JQuery._static.ajax({
            url: Std.format("/foo/ajax/v/removedribbonlist?board=$boardId"),
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
        var newestScore = 0;
        timeline.children().each(
            function(i: Int, elem: Dynamic) {
                var e: Dynamic = new JQuery(elem);
                var score: Int = Std.parseInt(e.attr('score'));
                if (newestScore < score) {
                    newestScore = score;
                }
            });
        fetchTimeline(timeline, null, newestScore, version);
    }
    
    static private function fetchTimeline(
        oldTimeline: Dynamic,
        newestScore: Dynamic,
        oldestScore: Dynamic,
        version: Int) {

        var ribbonId = Std.parseInt(oldTimeline.attr('ribbon-id'));
        var timelineId = Std.parseInt(oldTimeline.attr('timeline-id'));
        var level = Std.parseInt(oldTimeline.attr('level'));
        var writable = oldTimeline.attr('writable') == 'true';

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
                post.detail = formatDetail(post.detail, writable);
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

    static private function traceTimeline(timeline: Dynamic) {
        timeline.find('> article').each(
            function(i: Int, elem: Dynamic) {
                trace(elem);
            });
    }

    static private function mergeTimeline(
        oldTimeline: Dynamic, newTimeline: Dynamic) {

        if (newTimeline.children().length == 0) {
            setupNoArticle(oldTimeline);
            return;
        }

        oldTimeline.find('> .continue-reading').remove();

        // trace('new');
        // traceTimeline(newTimeline);

        var remover = newTimeline.find('> article[removed="true"]');
        // trace('remover');
        remover.each(
            function(i: Int, elem: Dynamic) {
                trace(elem);
            });

        // trace('old(before applying remover)');
        // traceTimeline(oldTimeline);

        remover.each(
            function(i: Int, elem: Dynamic) {
                var e: Dynamic = new JQuery(elem);
                var postId = e.attr('post-id');
                var filter = Std.format('[post-id="$postId"]');
                trace(filter);
                newTimeline.find(filter).addClass('removing');
                oldTimeline.find(filter).addClass('removing');
            });
        newTimeline.find('.removing').remove();
        oldTimeline.find('.removing').remove();

        // trace('old(before)');
        // traceTimeline(oldTimeline);

        // post-idの同じ物を削除
        newTimeline.children().each(
            function(i: Int, elem: Dynamic) {
                var e: Dynamic = new JQuery(elem);
                var postId = e.attr('post-id');
                oldTimeline.find(Std.format('[post-id=$postId]')).addClass("removing");
            });
        oldTimeline.find('.removing').remove();

        var oe: Dynamic = oldTimeline.children().eq(0);
        var ne: Dynamic = newTimeline.children().eq(0);
        while(0 < oe.length && 0 < ne.length) {
            var oldScore = Std.parseInt(oe.attr('score'));
            var newScore: Null<Int> = null;
            while(
                0 < ne.length &&
                oldScore <= (newScore = Std.parseInt(ne.attr('score')))) {
                var newPostId = Std.parseInt(ne.attr('post-id'));
                var oldPostId = Std.parseInt(oe.attr('post-id'));
                trace(Std.format("judge newPost: $newPostId"));
                var next_ne = ne.next();

                ne.insertBefore(oe);

                ne = next_ne;
            }
            oe = oe.next();
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

        // trace('newTimeline intervals');
        // trace(newTimeline.attr('intervals'));
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

        // trace('old(after)');
        // traceTimeline(oldTimeline);

        setupDragHandles(oldTimeline);
        setupNoArticle(oldTimeline);
    }

    static private function setupDragHandles(timeline: Dynamic) {
        if (!timeline.is('[editable="true"]')) {
            return;
        }
        var articles = timeline.find('> .post');
        articles.find('> .avatar').addClass('drag-handle');
        articles.find('> .entry > .detail').addClass('drag-handle');
    }
    
    static private function setupNoArticle(timeline: Dynamic) {
        timeline.find('> .no-article').remove();
        if (timeline.find('> article').length == 0) {
            timeline.append('<div class="no-article">ポストがありません</div>');
        }
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

    static private function describeSelf() {
        if (connected) {
            io.push("describe", {user: getUserId(), board: getBoardId()});
        }
    }

    static private function subscribeBoard() {
        if (connected) {
            io.push("watch-board",
                    {user: getUserId(), targets: [getBoardId()]});
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

    static private function loadTimeline(timelineId: Int, version: Int) {
        new JQuery(Std.format('[timeline-id="$timelineId"]')).each(
            function(i: Int, elem: Dynamic) {
                fillNewerTimeline(new JQuery(elem), version);
            });
    }

    static function loadDetail(postId: Int, version: Int) {
        var posts = new JQuery(Std.format('[post-id="$postId"]'));
        posts.each(
            function(i: Int, e: Dynamic) {
                var post = new JQuery(e);
                var ribbonId = post.closest('.ribbon').attr('ribbon-id');
                var writable =
                    post.closest('.timeline').attr('writable') == 'true';
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
                    var output = formatDetail(data, writable);
                    var entry = post.find('> .entry');
                    entry.find('> .detail').replaceWith(output);
                    updateCommentDisplayText(entry);
                });
            });
    }

    static function formatDetail(detail: Dynamic, writable: Bool) {
        var favoredBy = "";
        var srcFavoredBy: Array<Dynamic> = detail.favoredBy;
        for(vv in srcFavoredBy) {
            var label: String = vv.label;
            var icon: String = vv.gravatar;
            favoredBy += tooltip(gravatar(icon, 16), label);
        }
        detail.favoredBy = favoredBy;
        detail.elapsed = elapsedInWords(detail.elapsed);
        detail.writable = writable;
        return applyTemplate("Detail", detail);
    }

    static private function applyTemplate(codename: String, data: Dynamic)
        : String {
        var templateCode = haxe.Resource.getString(codename);
        var template = new haxe.Template(templateCode);
        return template.execute(data);
    }

    static private function updateBoardWatcher(
        boardId: Int, observers: Array<Dynamic>) {
        var observersView: Dynamic = new JQuery('#observers');
        observersView.html('');
        for(v in observers) {
            var userId = v.userId;
            var label = v.label;
            var icon = tooltip(gravatar(v.gravatar, 16), label);
            observersView.append(Std.format('<span class="observer" user-id="$userId">$icon</span>'));
        }
    }

    static private function startWatch() {
        io = new RocketIO().connect();
        io.on("connect", function(session) {
            connected = true;
            subscribeBoard();
            subscribeTimelines();
            subscribePosts();
            describeSelf();
        });
        io.on("watch-board", function(data: Dynamic) {
            updateBoardWatcher(data.board, data.observers);
        });
        io.on("watch-timeline", function(data: Dynamic<Int>) {
            loadTimeline(data.timeline, data.version);
        });
        io.on("watch-post", function(data: Dynamic<Int>) {
            loadDetail(data.post, data.version);
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
        return untyped __js__('this');
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

    static private function setupRadio(root: Dynamic, name: String) {
        var radios: Dynamic = root.find(Std.format('[name="$name"]'));

        var onChange = function() {
            radios.each(
                function(i: Int, elem: Dynamic) {
                    var radio: Dynamic = new JQuery(elem);
                    var label: Dynamic = radio.closest('label.radio');
                    var inputs: Dynamic = label.find(
                        'input:not(:radio),select');
                    var checked = radio.is(':checked');
                    updateStatus(
                        inputs, ['active', 'loaded'], 'active', checked);
                });
            return true;
        };

        onChange();
        radios.unbind('change');
        radios.change(onChange);
    }

    static private function updateStatus(
        all: Dynamic, statuses: Array<String>, s: String, f: Bool) {
        if(f) {
            all.addClass(s);
        } else {
            all.removeClass(s);
        }

        // statusがすべてonならenable, さもなければdisable
        all.each(
            function(i: Int, elem: Dynamic) {
                var e: Dynamic = new JQuery(elem);
                for(s in statuses) {
                    if (!e.hasClass(s)) {
                        disable(e);
                        return;
                    }
                }
                enable(e);
            });
    }

    static private function elapsedInWords(elapsedInSeconds: Int): String {
        if (elapsedInSeconds <=  10) {
            return "今";
        } else if(elapsedInSeconds <  60) {
            return Std.format("${elapsedInSeconds}秒前");
        }

        var elapsedInMinutes = Math.round(elapsedInSeconds / 60);
        if (elapsedInMinutes < 60) {
            return Std.format("${elapsedInMinutes}分前");
        }

        var elapsedInHours = Math.round(elapsedInMinutes / 60);
        if (elapsedInHours < 24) {
            return Std.format("${elapsedInHours}時間前");
        }

        var elapsedInDays = Math.round(elapsedInHours / 24);
        if (elapsedInDays < 30) {
            return Std.format("${elapsedInDays}日前");
        }

        var elapsedInMonths = Math.round(elapsedInDays / 30);
        if (elapsedInMonths < 12) {
            return Std.format("${elapsedInMonths}ヶ月前");
        }

        var elapsedInYears = Math.round(elapsedInMonths / 12);
        return Std.format("${elapsedInYears}年前");
    }

    static private function gravatar(
        hash: String,
        size: Int,
        userId: Int=0,
        username: String="",
        label: String=""): String {
        return Std.format('<img src="http://www.gravatar.com/avatar/${hash}?s=${size}&d=mm" alt="gravatar" user-id="$userId" username="$username" title="$label" data-toggle="tooltip"/>');
    }

    static private function tooltip(s: String, desc: String) {
        return Std.format('<a href="#" data-toggle="tooltip" title="$desc" onmouseover="$(this).tooltip(\'show\');" onmouseout="$(this).tooltip(\'hide\');">$s</a>');
        
    }
}

