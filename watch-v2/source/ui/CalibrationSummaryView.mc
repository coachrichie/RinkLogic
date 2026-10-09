using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class CalibrationSummaryView extends WatchUi.View {
    private var mSummary;
    function initialize(summary) { View.initialize(); mSummary = summary; }
    function onUpdate(dc as Graphics.Dc) as Void {
        var centerX = dc.getWidth() / 2;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(0x20D49A, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 100, Graphics.FONT_LARGE,
            WatchUi.loadResource(Rez.Strings.CalibrationSaved),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0xC8E5F4, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 180, Graphics.FONT_SMALL,
            mSummary[:validRepetitions].toString() + " VALID",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, 220, Graphics.FONT_SMALL,
            mSummary[:invalidRepetitions].toString() + " INVALID",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class CalibrationSummaryInputDelegate extends WatchUi.BehaviorDelegate {
    private var mTarget;
    function initialize(target) { BehaviorDelegate.initialize(); mTarget = target; }
    function onBack() as Lang.Boolean { mTarget.finishCalibration(); return true; }
    function onSelect() as Lang.Boolean { mTarget.finishCalibration(); return true; }
}
