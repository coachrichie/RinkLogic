using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class CalibrationRunView extends WatchUi.View {
    private var mTarget;
    private var mController;
    private var mCoordinator = null;
    private var mStarted = false;
    private var mEnded = false;
    private var mRepetition = 1;

    function initialize(target, controller) {
        View.initialize();
        mTarget = target;
        mController = controller;
    }

    function getState() as Lang.Symbol {
        if (mEnded) { return :end; }
        return mStarted ? :run : :ready;
    }

    function setCoordinator(coordinator) as Void { mCoordinator = coordinator; }

    function toggleMarker(atMs) as Lang.Boolean {
        if (mEnded) {
            nextRepetition();
            return true;
        }
        if (!mStarted) {
            if (mCoordinator != null && !mCoordinator.toggleShift()) { return false; }
            mStarted = mController.startRepetition(atMs);
            return mStarted;
        }
        var metrics = {:distanceCm=>null, :pushes=>null,
            :coveragePercent=>null};
        if (mCoordinator != null) {
            if (!mCoordinator.toggleShift()) { return false; }
            var dashboard = mCoordinator.getDashboard();
            metrics = {:distanceCm=>dashboard[:lastShiftDistanceCm],
                :pushes=>dashboard[:lastShiftPushes],
                :coveragePercent=>dashboard[:coveragePercent]};
        }
        mController.endRepetition(atMs, metrics);
        mEnded = true;
        return true;
    }

    function nextRepetition() as Void {
        mStarted = false;
        mEnded = false;
        mRepetition += 1;
        WatchUi.requestUpdate();
    }

    function requestCancel() as Void { mController.abort(); mTarget.cancelCalibration(); }

    function requestSave() as Void { mTarget.saveCalibration(); }

    function onUpdate(dc as Graphics.Dc) as Void {
        var centerX = dc.getWidth() / 2;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(0xC8E5F4, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 60, Graphics.FONT_LARGE,
            WatchUi.loadResource(Rez.Strings.CalibrationTitle),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(mEnded ? 0xF6C246 : (mStarted ? 0x20D49A : 0x8FA6C1),
            Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 170, Graphics.FONT_MEDIUM,
            mEnded ? WatchUi.loadResource(Rez.Strings.CalibrationEnd) :
                (mStarted ? "RUN · LOWER: END" :
                    WatchUi.loadResource(Rez.Strings.CalibrationReady)),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x8FA6C1, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 230, Graphics.FONT_SMALL,
            "REPETITION " + mRepetition.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, 310, Graphics.FONT_XTINY,
            "LOWER: MARK · UPPER: SAVE",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class CalibrationRunInputDelegate extends WatchUi.InputDelegate {
    private var mView;
    private var mClock;
    function initialize(view, clock) { InputDelegate.initialize(); mView = view; mClock = clock; }
    function onKey(event as WatchUi.KeyEvent) as Lang.Boolean {
        var key = event.getKey();
        if (key == WatchUi.KEY_ESC) { return mView.toggleMarker(mClock.nowMs()); }
        if (key == WatchUi.KEY_ENTER) { mView.requestSave(); return true; }
        return false;
    }
    function onTap(event) as Lang.Boolean { return mView.toggleMarker(mClock.nowMs()); }
}
