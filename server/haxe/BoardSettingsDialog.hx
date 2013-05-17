import Misc;
import FormUtil;

@:expose
class BoardSettingsDialog {
    static public function init() {
    }

    static public function doModal() {
        var dialog: Dynamic = new JQuery('#board-settings');

        FormUtil.setupRadio(dialog, "read_permission");
        FormUtil.setupRadio(dialog, "write_permission");
        FormUtil.setupRadio(dialog, "edit_permission");

        FormUtil.setupEditGroupButton(dialog.find('#edit-readable-group'));
        FormUtil.setupEditGroupButton(dialog.find('#edit-writable-group'));
        FormUtil.setupEditGroupButton(dialog.find('#edit-editable-group'));

        dialog.justModal();
    }
}
