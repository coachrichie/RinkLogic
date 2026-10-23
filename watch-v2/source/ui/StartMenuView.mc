using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;

class StartMenuView extends WatchUi.View {
    private var mTarget;
    private var mSelection = :calibration;
    function initialize(target) { View.initialize(); mTarget = target; }
    function selection() as Lang.Symbol { return mSelection; }
    function cycleSelection() as Void {
        mSelection = mSelection == :calibration ? :exit : :calibration;
        WatchUi.requestUpdate();
    }
    function confirmSelection() as Void {
        if (mSelection == :calibration) { mTarget.requestCalibration(); }
        else { mTarget.exitApp(); }
    }
    function selectAt(y, height) as Void {
        mSelection = y < height / 2 ? :calibration : :exit;
        confirmSelection();
    }
    function onUpdate(dc as Graphics.Dc) as Void {
        var centerX = dc.getWidth() / 2;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK); dc.clear();
        dc.setColor(mSelection == :calibration ? 0x20D49A : 0x8FA6C1,
            Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, dc.getHeight() * 40 / 100, Graphics.FONT_MEDIUM,
            WatchUi.loadResource(Rez.Strings.MenuCalibration),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(mSelection == :exit ? 0x20D49A : 0x8FA6C1,
            Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, dc.getHeight() * 60 / 100, Graphics.FONT_MEDIUM,
            WatchUi.loadResource(Rez.Strings.MenuExit),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, dc.getHeight() * 80 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.MenuHint),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class StartMenuInputDelegate extends WatchUi.InputDelegate {
    private var mView;
    function initialize(view) { InputDelegate.initialize(); mView = view; }
    function onKey(event as WatchUi.KeyEvent) as Lang.Boolean {
        if (event.getKey() == WatchUi.KEY_ENTER) { mView.cycleSelection(); return true; }
        if (event.getKey() == WatchUi.KEY_ESC) { mView.confirmSelection(); return true; }
        return false;
    }
    function onTap(event as WatchUi.ClickEvent) as Lang.Boolean {
        mView.selectAt(event.getCoordinates()[1],
            System.getDeviceSettings().screenHeight);
        return true;
    }
}
