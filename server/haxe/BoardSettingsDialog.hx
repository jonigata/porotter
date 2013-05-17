import Misc;
import FormUtil;

@:expose
class BoardSettingsDialog {
    static public function init() {
    }

    static public function doModal() {
        var dialog: Dynamic = new JQuery('#board-settings');

        Misc.setupRadio(dialog, "read_permission");
        Misc.setupRadio(dialog, "write_permission");
        Misc.setupRadio(dialog, "edit_permission");

        Misc.setupEditGroupButton(dialog.find('#edit-readable-group'));
        Misc.setupEditGroupButton(dialog.find('#edit-writable-group'));
        Misc.setupEditGroupButton(dialog.find('#edit-editable-group'));

        dialog.justModal();
    }
}
