using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class CalibrationSummaryView extends WatchUi.View {
    private var mTarget;
    private var mCandidate;
    function initialize(target, candidate) {
        View.initialize(); mTarget = target; mCandidate = candidate;
    }
    function selection() as Lang.Symbol { return :activate; }
    function requestSave() as Void { mTarget.activateAndSaveCalibration(); }
    function requestDiscard() as Void { mTarget.confirmDiscardCalibration(); }
    function confirmTouch(y, height) as Lang.Boolean {
        if (height <= 0 || y < height * 45 / 100 || y > height * 72 / 100) {
            return false;
        }
        if (y < height * 58 / 100) { requestSave(); }
        else { requestDiscard(); }
        return true;
    }
    function onUpdate(dc as Graphics.Dc) as Void {
        var centerX = dc.getWidth() / 2;
        var height = dc.getHeight();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK); dc.clear();
        dc.setColor(0x20D49A, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 13 / 100, Graphics.FONT_MEDIUM,
            WatchUi.loadResource(Rez.Strings.CalibrationReview),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 27 / 100, Graphics.FONT_SMALL,
            "10 / 10 · " + (mCandidate[:sport] == :inline ?
                WatchUi.loadResource(Rez.Strings.SportInline) :
                WatchUi.loadResource(Rez.Strings.SportIce)),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, height * 39 / 100, Graphics.FONT_SMALL,
            mCandidate[:factor].format("%.4f"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, height * 51 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.CalibrationWithoutStick) + " " +
                mCandidate[:conditionMedians][:skate_only].format("%.4f"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, height * 60 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.CalibrationWithStick) + " " +
                mCandidate[:conditionMedians][:puck_stickhandling].format("%.4f"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x20D49A, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 74 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.CalibrationSaveHint),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0xF6C246, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 84 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.CalibrationDiscardHint),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class CalibrationSummaryInputDelegate extends WatchUi.InputDelegate {
    private var mView;
    function initialize(view) { InputDelegate.initialize(); mView = view; }
    function onKey(event as WatchUi.KeyEvent) as Lang.Boolean {
        if (event.getKey() == WatchUi.KEY_ENTER) { mView.requestSave(); return true; }
        if (event.getKey() == WatchUi.KEY_ESC) { mView.requestDiscard(); return true; }
        return false;
    }
    function onTap(event) as Lang.Boolean {
        var coordinates = event.getCoordinates();
        if (coordinates == null || coordinates.size() < 2) { return false; }
        var settings = Toybox.System.getDeviceSettings();
        return mView.confirmTouch(coordinates[1], settings.screenHeight);
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

class CalibrationCancelConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    private var mTarget;
    private var mHandled = false;
    function initialize(target) {
        ConfirmationDelegate.initialize();
        mTarget = target;
    }
    function onResponse(response) as Lang.Boolean {
        if (mHandled) { return true; }
        mHandled = true;
        if (response == WatchUi.CONFIRM_YES) { mTarget.cancelCalibration(); }
        return true;
    }
}

class CalibrationDiscardConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    private var mTarget;
    private var mHandled = false;
    function initialize(target) {
        ConfirmationDelegate.initialize();
        mTarget = target;
    }
    function onResponse(response) as Lang.Boolean {
        if (mHandled) { return true; }
        mHandled = true;
        if (response == WatchUi.CONFIRM_YES) { mTarget.discardCalibration(); }
        return true;
    }
}
