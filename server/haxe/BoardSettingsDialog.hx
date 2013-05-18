import Misc;
import FormUtil;

@:expose
class BoardSettingsDialog {
    static public function init() {
    }

    static public function doModal(f: Int->Void) {
        var dialog: Dynamic = new JQuery('#board-settings');

        FormUtil.setupRadio(dialog, "read_permission");
        FormUtil.setupRadio(dialog, "write_permission");
        FormUtil.setupRadio(dialog, "edit_permission");

        FormUtil.setupEditGroupButton(dialog.find('#edit-readable-group'));
        FormUtil.setupEditGroupButton(dialog.find('#edit-writable-group'));
        FormUtil.setupEditGroupButton(dialog.find('#edit-editable-group'));

        FormUtil.setSubmitAction(
            dialog,
            function(submit) {
                dialog.close();
                FormUtil.doBoardEditingAction(submit, f);
            });

        dialog.justModal();
    }
}
