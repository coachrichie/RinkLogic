using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;

class StartMenuView extends WatchUi.View {
    private var mTarget;
    private var mSelection = :training;

    function initialize(target) { View.initialize(); mTarget = target; }
    function selection() as Lang.Symbol { return mSelection; }

    function cycleSelection() as Void {
        mSelection = mSelection == :training ? :calibration :
            (mSelection == :calibration ? :exit : :training);
        WatchUi.requestUpdate();
    }

    function confirmSelection() as Void {
        if (mSelection == :training) { mTarget.requestTraining(); }
        else if (mSelection == :calibration) { mTarget.requestCalibration(); }
        else { mTarget.exitApp(); }
    }

    function selectAt(y, height) as Lang.Boolean {
        if (height <= 0) { return false; }
        if (y >= height * 26 / 100 && y <= height * 42 / 100) {
            mSelection = :training;
        } else if (y >= height * 43 / 100 && y <= height * 59 / 100) {
            mSelection = :calibration;
        } else if (y >= height * 60 / 100 && y <= height * 76 / 100) {
            mSelection = :exit;
        } else {
            return false;
        }
        confirmSelection();
        return true;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var centerX = dc.getWidth() / 2;
        var height = dc.getHeight();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        drawItem(dc, centerX, height * 34 / 100, :training,
            WatchUi.loadResource(Rez.Strings.MenuTraining));
        drawItem(dc, centerX, height * 51 / 100, :calibration,
            WatchUi.loadResource(Rez.Strings.MenuCalibration));
        drawItem(dc, centerX, height * 68 / 100, :exit,
            WatchUi.loadResource(Rez.Strings.MenuExit));
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 84 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.MenuHint),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawItem(dc, centerX, y, item, label) as Void {
        dc.setColor(mSelection == item ? 0x20D49A : 0x8FA6C1,
            Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, Graphics.FONT_MEDIUM, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class StartMenuInputDelegate extends WatchUi.InputDelegate {
    private var mView;
    function initialize(view) { InputDelegate.initialize(); mView = view; }
    function onKey(event as WatchUi.KeyEvent) as Lang.Boolean {
        if (event.getKey() == WatchUi.KEY_ESC) { mView.cycleSelection(); return true; }
        if (event.getKey() == WatchUi.KEY_ENTER) { mView.confirmSelection(); return true; }
        return false;
    }
    function onTap(event as WatchUi.ClickEvent) as Lang.Boolean {
        var coordinates = event.getCoordinates();
        if (coordinates == null || coordinates.size() < 2) { return false; }
        return mView.selectAt(coordinates[1],
            System.getDeviceSettings().screenHeight);
    }
}
