import Misc;
import jQuery.JQuery;

class FormUtil {
    static public function clearSelect(select: Dynamic) {
        Misc.disable(select);
        select.html('');
    }

    static public function getSelected(select: Dynamic) {
        return new JQuery(select).find(':selected');
    }

    static public function setSubmitAction(dialog: Dynamic, f: Dynamic->Void) {
        var submit: Dynamic = dialog.find(':submit');
        submit.unbind('click');
        submit.click(
            function(e) {
                f(e.target);
                return false;
            });
    }

    static public function setupRadio(root: Dynamic, name: String) {
        var radios: Dynamic = root.find('[name="${name}"]');

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

    static public function setupEditGroupButton(button: Dynamic) {
        updateStatus(button, ['active', 'loaded'], 'loaded', false);

        var groupId = Std.parseInt(button.attr('group-id'));
        var storeName = button.attr('store');
        var displayId = button.attr('display');
        var form: Dynamic = button.closest('form');
        var store: Dynamic = form.find('[name="${storeName}"]');
        var display: Dynamic = form.find('#${displayId}');
        
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

    static public function setupUserSelect(
        userSelect: Dynamic,
        onLoad: Void->Void,
        onChange: Int->Void) {

        Misc.disable(userSelect);
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
                    '<option value="${userId}" user-id="${userId}" username="${username}" label="${userLabel}" icon="${userIcon}">${username} - ${userLabel}</option>');
            }
            userSelect.unbind('change');
            userSelect.change(
                function(e: Dynamic) {
                    onChange(cast getSelected(e.target).val());
                });
            Misc.enable(userSelect);

            onLoad();
        });
    }

    static public function setupBoardSelect(
        boardSelect: Dynamic,
        userId: Int,
        filter: Int->Bool,
        onChange: Int->Void) {
        
        JQuery._static.ajax({
            url: "/foo/ajax/v/boardlist?user=${userId}",
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
                    '<option value="${boardId}"${disabled}>${boardlabel}</option>');
            }
            boardSelect.unbind('change');
            boardSelect.change(
                function(e: Dynamic) {
                    onChange(cast getSelected(e.target).val());
                });
            Misc.enable(boardSelect);
        });
    }

    static public function setupRibbonSelect(
        ribbonSelect: Dynamic, boardId: Int, disableDup: Bool, f: Int->Void) {
        
        JQuery._static.ajax({
            url: '/foo/ajax/v/ribbonlist?board=${boardId}',
            method: "get"
        }).done(function(data) {
            ribbonSelect.append('<option value="0">リボンを選択</option>');
                
            var ribbons: Array<Dynamic> = JQuery._static.parseJSON(data);
            for(v in ribbons) {
                var ribbonId: Int = v.ribbonId;
                var ribbonLabel: String = v.label;

                var disabled: String = '';
                if (disableDup && 
                    0 < new JQuery('[ribbon-id="${ribbonId}"]').length) {
                    disabled = ' disabled="disabled"';
                }

                ribbonSelect.append(
                    '<option value="${ribbonId}"${disabled}>${ribbonLabel}</option>');
            }
            ribbonSelect.unbind('change');
            ribbonSelect.change(
                function(e: Dynamic) {
                    f(cast getSelected(e.target).val());
                });
            Misc.enable(ribbonSelect);
        });
    }

    static public function setupRemovedRibbonSelect(
        ribbonSelect: Dynamic, boardId: Int, disableDup: Bool, f: Int->Void) {
        
        JQuery._static.ajax({
            url: '/foo/ajax/v/removedribbonlist?board=${boardId}',
            method: "get"
        }).done(function(data) {
            ribbonSelect.append('<option value="0">リボンを選択</option>');
                
            var ribbons: Array<Dynamic> = JQuery._static.parseJSON(data);
            for(v in ribbons) {
                var ribbonId: Int = v[0];
                var ribbonLabel: String = v[1];

                ribbonSelect.append(
                    '<option value="${ribbonId}">${ribbonLabel}</option>');
            }
            ribbonSelect.unbind('change');
            ribbonSelect.change(
                function(e: Dynamic) {
                    f(cast getSelected(e.target).val());
                });
            Misc.enable(ribbonSelect);
        });
    }

    static public function doBoardEditingAction(obj: Dynamic, f: Int->Void) {
        postForm(getForm(obj), function(s: Dynamic) {
                f(s.version);
            });
        return false;
    }

    static public function doPost(obj: Dynamic) {
        postForm(getForm(obj), function(s: Dynamic) {
                Misc.redirect(Misc.makeBoardUrl(s[0], s[1]));
            });
        return false;
    }

    ////////////////////////////////////////////////////////////////
    // private
    static private function getForm(obj: Dynamic): JQuery {
        var e = new JQuery(obj);
        if (e.is('form')) {
            return e;
        } else {
            return e.closest("form");
        }
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
                        Misc.disable(e);
                        return;
                    }
                }
                Misc.enable(e);
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
        memberSet.sort(function(a: Int, b: Int) { return a - b; });

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
                    Misc.gravatar(
                        v.gravatar, 16, v.userId, v.username, v.label));
            }
        }
        display.find('img').tooltip();
        display.find('img').draggable({revert: "invalid"});

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

    static private function editGroup(data: Dynamic, cb: Dynamic->Void) {
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
        Misc.setEnabled(groupName, data.nameEditable);

        // 追加ユーザセレクト
        var userSelect: Dynamic = dialog.find('[name="user"]');
        var updateUI = function() {
            userSelect.val(0);
            userSelect.find('option').each(
                function(i: Int,elem: Dynamic) {
                    var e = new JQuery(elem);
                    var userId = e.attr('user-id');
                    var filter = '[user-id="${userId}"]';
                    Misc.setEnabled(e, display.find(filter).length == 0);
                });
            Misc.setEnabled(
                submit, oldMemberSet != display.attr('member-set'));
        };

        // ゴミ箱
        var trash: Dynamic = dialog.find(".group-member-trash");
        trash.droppable({
            accept: '[user-id]',
            drop: function(e, ui) {
                var e: Dynamic = new JQuery(ui.draggable);
                e.tooltip('hide');
                data.members = data.members.filter(
                    function(n) {
                        return n.userId != Std.parseInt(e.attr('user-id'));
                    });
                updateGroupDisplay(display, data);
                trace(display.attr('member-set'));
                updateUI();
            }
        });

        // 追加ユーザボタン
        var addButton: Dynamic = dialog.find('#add-member');
        Misc.disable(addButton);
        setupUserSelect(
            userSelect,
            function() {
                updateUI();
            },
            function(userId: Int) {
                Misc.setEnabled(addButton, userId != 0);
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
            });

        updateUI();

        dialog.justModal({overlayZIndex: 20050, modalZIndex: 20100});
    }

    
}
