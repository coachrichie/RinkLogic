using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;

class SportSelectionView extends WatchUi.View {
    private var mTarget;
    private var mPurpose = null;
    private var mSelection = null;

    function initialize(target, purpose, selectedSport) {
        View.initialize();
        mTarget = target;
        if ((purpose == :training || purpose == :calibration) &&
            CalibrationTypes.validSport(selectedSport)) {
            mPurpose = purpose;
            mSelection = selectedSport;
        }
    }

    function selection() { return mSelection; }

    function cycleSelection() as Void {
        if (mSelection == null) { return; }
        mSelection = mSelection == :ice ? :inline : :ice;
        WatchUi.requestUpdate();
    }

    function confirmSelection() as Void {
        if (mPurpose == null || !CalibrationTypes.validSport(mSelection)) { return; }
        mTarget.confirmSport(mPurpose, mSelection);
    }

    function selectAt(y, height) as Void {
        if (mPurpose == null) { return; }
        mSelection = y < height / 2 ? :ice : :inline;
        confirmSelection();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var centerX = dc.getWidth() / 2;
        var height = dc.getHeight();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var title = mPurpose == :calibration ?
            WatchUi.loadResource(Rez.Strings.SelectCalibrationSport) :
            WatchUi.loadResource(Rez.Strings.SelectTrainingSport);
        dc.drawText(centerX, height * 22 / 100, Graphics.FONT_SMALL, title,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        drawSport(dc, centerX, height * 43 / 100, :ice,
            WatchUi.loadResource(Rez.Strings.SportIce));
        drawSport(dc, centerX, height * 61 / 100, :inline,
            WatchUi.loadResource(Rez.Strings.SportInline));
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 82 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.MenuHint),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawSport(dc, centerX, y, sport, label) as Void {
        dc.setColor(mSelection == sport ? 0x20D49A : 0x8FA6C1,
            Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, Graphics.FONT_MEDIUM, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class SportSelectionInputDelegate extends WatchUi.InputDelegate {
    private var mView;
    function initialize(view) { InputDelegate.initialize(); mView = view; }
    function onKey(event as WatchUi.KeyEvent) as Lang.Boolean {
        if (event.getKey() == WatchUi.KEY_ESC) { mView.cycleSelection(); return true; }
        if (event.getKey() == WatchUi.KEY_ENTER) { mView.confirmSelection(); return true; }
        return false;
    }
    function onTap(event as WatchUi.ClickEvent) as Lang.Boolean {
        mView.selectAt(event.getCoordinates()[1],
            System.getDeviceSettings().screenHeight);
        return true;
    }
}
