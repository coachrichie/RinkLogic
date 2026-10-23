using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class CalibrationSummaryView extends WatchUi.View {
    private var mTarget;
    private var mCandidate;
    private var mSelection = :activate;
    function initialize(target, candidate) {
        View.initialize(); mTarget = target; mCandidate = candidate;
    }
    function selection() as Lang.Symbol { return mSelection; }
    function cycleSelection() as Void {
        mSelection = mSelection == :activate ? :discard : :activate;
        WatchUi.requestUpdate();
    }
    function confirmSelection() as Void {
        if (mSelection == :activate) { mTarget.activateAndSaveCalibration(); }
        else { mTarget.discardCalibration(); }
    }
    function confirmTouch(y) as Lang.Boolean {
        if (y < 190 || y > 292) { return false; }
        mSelection = y < 243 ? :activate : :discard;
        confirmSelection();
        return true;
    }
    function onUpdate(dc as Graphics.Dc) as Void {
        var centerX = dc.getWidth() / 2;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK); dc.clear();
        dc.setColor(0x20D49A, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 75, Graphics.FONT_MEDIUM,
            WatchUi.loadResource(Rez.Strings.CalibrationReview),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 135, Graphics.FONT_SMALL,
            mCandidate[:factor].format("%.4f"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(mSelection == :activate ? 0x20D49A : 0x8FA6C1,
            Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 220, Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.CalibrationActivate),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(mSelection == :discard ? 0xF6C246 : 0x8FA6C1,
            Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 265, Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.CalibrationDiscard),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class CalibrationSummaryInputDelegate extends WatchUi.InputDelegate {
    private var mView;
    function initialize(view) { InputDelegate.initialize(); mView = view; }
    function onKey(event as WatchUi.KeyEvent) as Lang.Boolean {
        if (event.getKey() == WatchUi.KEY_ENTER) { mView.cycleSelection(); return true; }
        if (event.getKey() == WatchUi.KEY_ESC) { mView.confirmSelection(); return true; }
        return false;
    }
    function onTap(event) as Lang.Boolean {
        var coordinates = event.getCoordinates();
        if (coordinates == null || coordinates.size() < 2) { return false; }
        return mView.confirmTouch(coordinates[1]);
    }
}

class CalibrationOutcomeView extends WatchUi.View {
    private var mOutcome;
    function initialize(outcome) { View.initialize(); mOutcome = outcome; }
    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK); dc.clear();
        dc.setColor(mOutcome == :activated ? Graphics.COLOR_GREEN : Graphics.COLOR_RED,
            Graphics.COLOR_TRANSPARENT);
        var message = mOutcome == :activated ? Rez.Strings.CalibrationActivated :
            Rez.Strings.CalibrationStorageError;
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Graphics.FONT_SMALL,
            WatchUi.loadResource(message),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class CalibrationSummaryOutcomeDelegate extends WatchUi.BehaviorDelegate {
    private var mTarget;
    function initialize(target) { BehaviorDelegate.initialize(); mTarget = target; }
    function onBack() as Lang.Boolean { mTarget.finishCalibration(); return true; }
    function onSelect() as Lang.Boolean { mTarget.finishCalibration(); return true; }
}
