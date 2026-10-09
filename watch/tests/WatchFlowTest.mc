using Toybox.Lang;
using Toybox.Test as Test;
using Toybox.WatchUi;

class FlowClockFake {
    var mNow = 1000;

    function now() as Lang.Number {
        return mNow;
    }
}

class FlowControllerFake {
    var mState = :idle;
    var mStartCalls = 0;
    var mStopCalls = 0;
    var mSaveCalls = 0;
    var mMarkerCalls = 0;
    var mLastMarkerState = null;
    var mLastMarkerTimestamp = null;
    var mSummaryMetrics = null;
    var mStartResult = true;
    var mSaveResult = true;
    var mDiscardResult = true;
    var mDiscardCalls = 0;
    var mEvents = [];

    function start(mode) as Lang.Boolean {
        mEvents.add(:activityStart);
        mStartCalls += 1;
        if (mStartResult) { mState = :recording; }
        return mStartResult;
    }

    function markShift(state, timestamp) as Lang.Boolean {
        mMarkerCalls += 1;
        mLastMarkerState = state;
        mLastMarkerTimestamp = timestamp;
        return true;
    }

    function setSummaryMetrics(metrics) as Lang.Boolean {
        mSummaryMetrics = metrics;
        return true;
    }

    function stop() as Lang.Boolean {
        mEvents.add(:activityStop);
        mStopCalls += 1;
        mState = :stopped;
        return true;
    }

    function save() as Lang.Boolean {
        mSaveCalls += 1;
        if (mSaveResult) { mState = :saved; }
        return mSaveResult;
    }

    function discard() as Lang.Boolean {
        mDiscardCalls += 1;
        if (mDiscardResult) { mState = :discarded; }
        return mDiscardResult;
    }
}

class FlowSensorFake {
    var mEvents = null;
    var mStarts = 0;
    var mStops = 0;
    function initialize(events) { mEvents = events; }
    function start(listener, profile) { mStarts += 1; mEvents.add(:sensorStart); return false; }
    function stop() { mStops += 1; mEvents.add(:sensorStop); }
}

class FlowKeyEventFake {
    var mKey = null;
    function initialize(key) { mKey = key; }
    function getKey() { return mKey; }
}

(:test)
function confirmedStartInvokesControllerAndEntersRecording(logger as Test.Logger) as Lang.Boolean {
    var controller = new FlowControllerFake();
    var live = new LiveView(controller, HockeyMode.ICE, new FlowClockFake(), null, null);
    return live.startConfirmed() && controller.mStartCalls == 1 &&
        controller.mState == :recording;
}

(:test)
function immediateMarkerTogglesShiftAndBenchThroughTheSessionController(logger as Test.Logger) as Lang.Boolean {
    var clock = new FlowClockFake();
    var controller = new FlowControllerFake();
    var live = new LiveView(controller, HockeyMode.ICE, clock, null, null);
    live.startConfirmed();
    clock.mNow = 5000;
    var first = live.markShiftNow();
    clock.mNow = 9000;
    var second = live.markShiftNow();
    return first && second && controller.mMarkerCalls == 2 &&
        controller.mLastMarkerState == :bench && controller.mLastMarkerTimestamp == 8000 &&
        live.getShiftCount() == 1 && live.getIceTimeMs() == 4000;
}

(:test)
function confirmedStopBuildsASummaryAndSavesTheStoppedSession(logger as Test.Logger) as Lang.Boolean {
    var clock = new FlowClockFake();
    var controller = new FlowControllerFake();
    var live = new LiveView(controller, HockeyMode.ICE, clock, null, null);
    live.startConfirmed();
    clock.mNow = 5000;
    live.markShiftNow();
    clock.mNow = 9000;
    var summary = live.stopConfirmed();
    return summary != null && controller.mStopCalls == 1 && controller.mSaveCalls == 1 &&
        summary.getDurationMs() == 8000 && summary.getShiftCount() == 1 &&
        summary.getIceTimeMs() == 4000 && summary.getAnalysisLabel().equals(UiText.get(Rez.Strings.AnalysisAfterSave));
}

(:test)
function physicalUpAndDownKeysChooseEveryHockeyMode(logger as Test.Logger) as Lang.Boolean {
    var view = new ModeView(new FlowControllerFake());
    var delegate = new ModeInputDelegate(view);
    delegate.onKey(new FlowKeyEventFake(WatchUi.KEY_DOWN));
    var indoor = view.getSelectedMode() == HockeyMode.INLINE_INDOOR;
    delegate.onKey(new FlowKeyEventFake(WatchUi.KEY_DOWN));
    var startSelectionKeepsInline = view.getSelectionIndex() == 2 &&
        view.getSelectedMode() == HockeyMode.INLINE_INDOOR;
    delegate.onKey(new FlowKeyEventFake(WatchUi.KEY_UP));
    return indoor && startSelectionKeepsInline && view.getSelectedMode() == HockeyMode.INLINE_INDOOR;
}

(:test)
function venu2plusPageEventsAdjustProfileAgeAndExposeTestedHrMaxEditing(logger as Test.Logger) as Lang.Boolean {
    var view = new ProfileView(PlayerProfile.forTest(30, null, 181), new FlowControllerFake());
    var delegate = new ProfileInputDelegate(view);
    delegate.onSelect();
    delegate.onNextPage();
    var ageChanged = view.getProfile().getAge() == 31;
    delegate.onMenu();
    delegate.onNextPage();
    return ageChanged && view.getProfile().resolveHrMax() == 182 &&
        view.getProfile().getTestedHrMax() == 182;
}

(:test)
function venu2plusPageEventsReachEveryMode(logger as Test.Logger) as Lang.Boolean {
    var view = new ModeView(new FlowControllerFake());
    var delegate = new ModeInputDelegate(view);
    delegate.onNextPage();
    var indoor = view.getSelectedMode() == HockeyMode.INLINE_INDOOR;
    delegate.onNextPage();
    var startSelectionKeepsInline = view.getSelectionIndex() == 2 &&
        view.getSelectedMode() == HockeyMode.INLINE_INDOOR;
    delegate.onPreviousPage();
    return indoor && startSelectionKeepsInline && view.getSelectedMode() == HockeyMode.INLINE_INDOOR;
}

(:test)
function productionFlowStartsSensorBeforeActivityAndStopsItAfterStop(logger as Test.Logger) as Lang.Boolean {
    var controller = new FlowControllerFake();
    var sensor = new FlowSensorFake(controller.mEvents);
    var live = new LiveView(controller, HockeyMode.ICE, new FlowClockFake(), sensor, {});
    live.startConfirmed();
    live.stopConfirmed();
    return controller.mEvents[0] == :sensorStart && controller.mEvents[1] == :activityStart &&
        controller.mEvents[2] == :activityStop && controller.mEvents[3] == :sensorStop;
}

(:test)
function rejectedStopConfirmationDoesNotStopTheLiveRecording(logger as Test.Logger) as Lang.Boolean {
    var controller = new FlowControllerFake();
    var live = new LiveView(controller, HockeyMode.ICE, new FlowClockFake(), null, null);
    live.startConfirmed();
    return new StopConfirmationDelegate(live).onResponse(WatchUi.CONFIRM_NO) &&
        controller.mState == :recording && controller.mStopCalls == 0;
}

(:test)
function rejectedDiscardConfirmationKeepsTheRecoverySession(logger as Test.Logger) as Lang.Boolean {
    var controller = new FlowControllerFake();
    controller.mSaveResult = false;
    var live = new LiveView(controller, HockeyMode.ICE, new FlowClockFake(), null, null);
    live.startConfirmed();
    var recovery = live.stopConfirmed();
    return new DiscardConfirmationDelegate(recovery).onResponse(WatchUi.CONFIRM_NO) &&
        controller.mState == :stopped && controller.mDiscardCalls == 0;
}

(:test)
function failedStartHasALocalisedVisibleState(logger as Test.Logger) as Lang.Boolean {
    var controller = new FlowControllerFake();
    controller.mStartResult = false;
    var live = new LiveView(controller, HockeyMode.ICE, new FlowClockFake(), null, null);
    return live.startConfirmed() &&
        live.getStartFailureMessage().equals(UiText.get(Rez.Strings.StartFailed));
}

(:test)
function failedSaveKeepsTheStoppedSessionForRetryThenSavesIt(logger as Test.Logger) as Lang.Boolean {
    var clock = new FlowClockFake();
    var controller = new FlowControllerFake();
    controller.mSaveResult = false;
    var live = new LiveView(controller, HockeyMode.ICE, clock, null, null);
    live.startConfirmed();
    var recovery = live.stopConfirmed();
    controller.mSaveResult = true;
    var summary = recovery.retrySave();
    return recovery.getMessage().equals(UiText.get(Rez.Strings.SaveFailed)) &&
        controller.mStopCalls == 1 && controller.mSaveCalls == 2 &&
        controller.mState == :saved && summary != null;
}

(:test)
function failedSaveCanDiscardTheSameStoppedSessionUnderControl(logger as Test.Logger) as Lang.Boolean {
    var controller = new FlowControllerFake();
    controller.mSaveResult = false;
    var live = new LiveView(controller, HockeyMode.ICE, new FlowClockFake(), null, null);
    live.startConfirmed();
    var recovery = live.stopConfirmed();
    return recovery.discardSession() && controller.mStopCalls == 1 &&
        controller.mDiscardCalls == 1 && controller.mState == :discarded;
}

(:test)
function buttonNavigationSelectsBeforeEditingAndContinue(logger as Test.Logger) as Lang.Boolean {
    var view = new ProfileView(PlayerProfile.forTest(30, null, 181), new FlowControllerFake());
    var delegate = new ProfileInputDelegate(view);
    delegate.onNextPage();
    var selectedHr = view.getProfile().getAge() == 30;
    delegate.onSelect();
    delegate.onNextPage();
    var hrEdited = view.getProfile().getTestedHrMax() == 182;
    delegate.onSelect();
    return selectedHr && hrEdited;
}

(:test)
function modeButtonNavigationRequiresExplicitStart(logger as Test.Logger) as Lang.Boolean {
    var view = new ModeView(new FlowControllerFake());
    var delegate = new ModeInputDelegate(view);
    delegate.onNextPage();
    var selectedIndoor = view.getSelectedMode() == HockeyMode.INLINE_INDOOR;
    delegate.onSelect();
    var notStartedYet = view.getStartRequestCount() == 0;
    delegate.onNextPage();
    delegate.onSelect();
    return selectedIndoor && notStartedYet && view.getStartRequestCount() == 1;
}
