using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class CalibrationRunView extends WatchUi.View {
    private var mTarget;
    private var mController;
    private var mCoordinator = null;
    private var mState = :ready;
    private var mLastDurationMinutes = null;
    private var mRunStartedAt = null;
    private var mPromptCondition;
    private var mPromptPace;
    private var mPromptWithinConditionIndex;

    function initialize(target, controller) {
        View.initialize();
        mTarget = target;
        mController = controller;
        refreshPrompt();
    }

    function getState() as Lang.Symbol { return mState; }
    function setCoordinator(coordinator) as Void { mCoordinator = coordinator; }

    function prompt() as Lang.Dictionary {
        var progress = mController.progress();
        return {:condition=>mPromptCondition, :pace=>mPromptPace,
            :withinConditionIndex=>mPromptWithinConditionIndex,
            :repetition=>progress[:acceptedCount] + 1,
            :acceptedCount=>progress[:acceptedCount],
            :durationMinutes=>mLastDurationMinutes,
            :reason=>progress[:lastRejectionReason]};
    }

    function toggleMarker(atMs) as Lang.Boolean {
        if (mState == :accepted || mState == :retry) { return nextRepetition(); }
        if (mState == :complete) { return false; }
        if (mState == :ready) {
            if (mCoordinator != null && !mCoordinator.toggleShift()) { return false; }
            if (!mController.startRepetition(atMs)) { return false; }
            mRunStartedAt = atMs;
            mState = :running;
            WatchUi.requestUpdate();
            return true;
        }
        var metrics = {:distanceCm=>null, :pushes=>null,
            :coveragePercent=>null, :timebase=>null};
        if (mCoordinator != null) {
            if (!mCoordinator.toggleShift()) { return false; }
            var dashboard = mCoordinator.getDashboard();
            metrics = {:distanceCm=>dashboard[:lastShiftDistanceCm],
                :pushes=>dashboard[:lastShiftPushes],
                :coveragePercent=>dashboard[:coveragePercent],
                :timebase=>dashboard[:timebase]};
        }
        var accepted = mController.endRepetition(atMs, metrics);
        mLastDurationMinutes = mRunStartedAt == null ? null :
            (atMs - mRunStartedAt).toFloat() / 60000.0;
        if (mController.progress()[:status] == :complete) { mState = :complete; }
        else { mState = accepted ? :accepted : :retry; }
        WatchUi.requestUpdate();
        return true;
    }

    function nextRepetition() as Lang.Boolean {
        if (!mController.acknowledgeResult()) { return false; }
        mState = :ready;
        mLastDurationMinutes = null;
        mRunStartedAt = null;
        refreshPrompt();
        WatchUi.requestUpdate();
        return true;
    }

    function requestUpperAction() as Void {
        if (mState == :complete && mController.isEligible()) {
            mTarget.reviewCalibration(mController.candidateProfile());
            return;
        }
        mTarget.confirmCancelCalibration();
    }

    function requestCancel() as Void { requestUpperAction(); }

    function conditionLabel(condition) as Lang.String {
        return WatchUi.loadResource(condition == :puck_stickhandling ?
            Rez.Strings.CalibrationWithStick : Rez.Strings.CalibrationWithoutStick);
    }

    function paceLabel(pace) as Lang.String {
        if (pace == :fast) { return WatchUi.loadResource(Rez.Strings.CalibrationPaceFast); }
        if (pace == :normal) { return WatchUi.loadResource(Rez.Strings.CalibrationPaceNormal); }
        return WatchUi.loadResource(Rez.Strings.CalibrationPaceSlow);
    }

    function durationLabel() as Lang.String {
        return mLastDurationMinutes == null ? "-- MIN" :
            mLastDurationMinutes.format("%.2f") + " MIN";
    }

    function stateLabel() as Lang.String {
        if (mState == :running) { return WatchUi.loadResource(Rez.Strings.CalibrationRunning); }
        if (mState == :accepted) { return WatchUi.loadResource(Rez.Strings.CalibrationAccepted); }
        if (mState == :retry) { return rejectionLabel(prompt()[:reason]); }
        if (mState == :complete) { return WatchUi.loadResource(Rez.Strings.CalibrationComplete); }
        return WatchUi.loadResource(Rez.Strings.CalibrationReady);
    }

    function lowerActionLabel() as Lang.String {
        if (mState == :running) { return WatchUi.loadResource(Rez.Strings.CalibrationLowerEnd); }
        if (mState == :accepted) { return WatchUi.loadResource(Rez.Strings.CalibrationLowerNext); }
        if (mState == :retry) { return WatchUi.loadResource(Rez.Strings.CalibrationLowerRetry); }
        return WatchUi.loadResource(Rez.Strings.CalibrationLowerStart);
    }

    function rejectionLabel(reason) as Lang.String {
        if (reason == :too_short) { return WatchUi.loadResource(Rez.Strings.CalibrationTooShort); }
        if (reason == :too_long) { return WatchUi.loadResource(Rez.Strings.CalibrationTooLong); }
        if (reason == :missing_motion) { return WatchUi.loadResource(Rez.Strings.CalibrationMissingMotion); }
        if (reason == :low_coverage) { return WatchUi.loadResource(Rez.Strings.CalibrationLowCoverage); }
        if (reason == :invalid_distance || reason == :invalid_ratio) {
            return WatchUi.loadResource(Rez.Strings.CalibrationDeviation);
        }
        return WatchUi.loadResource(Rez.Strings.CalibrationInvalidMarker);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var centerX = dc.getWidth() / 2;
        var height = dc.getHeight();
        var progress = mController.progress();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(0xC8E5F4, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 18 / 100, Graphics.FONT_SMALL,
            conditionLabel(mPromptCondition),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 31 / 100, Graphics.FONT_LARGE,
            mPromptWithinConditionIndex.toString() + " / 5",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, height * 43 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.CalibrationRun) + " " +
                progress[:acceptedCount].toString() + " / 10",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, height * 52 / 100, Graphics.FONT_SMALL,
            paceLabel(mPromptPace),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(mState == :retry ? 0xF6C246 : 0x20D49A,
            Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 62 / 100, Graphics.FONT_SMALL, stateLabel(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x8FA6C1, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 70 / 100, Graphics.FONT_XTINY, durationLabel(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        if (mState != :complete) {
            dc.drawText(centerX, height * 78 / 100, Graphics.FONT_XTINY,
                lowerActionLabel(),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        dc.drawText(centerX, height * 88 / 100, Graphics.FONT_XTINY,
            mState == :complete ? WatchUi.loadResource(Rez.Strings.CalibrationUpperSave) :
                WatchUi.loadResource(Rez.Strings.CalibrationUpperCancel),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function refreshPrompt() as Void {
        var progress = mController.progress();
        mPromptCondition = progress[:condition];
        mPromptPace = progress[:pace];
        mPromptWithinConditionIndex = progress[:withinConditionIndex];
    }
}

class CalibrationRunInputDelegate extends WatchUi.InputDelegate {
    private var mView;
    private var mClock;
    function initialize(view, clock) { InputDelegate.initialize(); mView = view; mClock = clock; }
    function onKey(event as WatchUi.KeyEvent) as Lang.Boolean {
        if (event.getKey() == WatchUi.KEY_ESC) { return mView.toggleMarker(mClock.nowMs()); }
        if (event.getKey() == WatchUi.KEY_ENTER) { mView.requestUpperAction(); return true; }
        return false;
    }
    function onTap(event) as Lang.Boolean {
        var coordinates = event.getCoordinates();
        if (coordinates == null || coordinates.size() < 2) { return false; }
        var height = Toybox.System.getDeviceSettings().screenHeight;
        if (coordinates[1] >= height * 80 / 100) {
            mView.requestUpperAction();
            return true;
        }
        if (coordinates[1] >= height * 55 / 100) {
            return mView.toggleMarker(mClock.nowMs());
        }
        return false;
    }
}
