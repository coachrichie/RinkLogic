using Toybox.Lang;
using Toybox.Activity;
using Toybox.Test as Test;
using Toybox.WatchUi;

class ConfirmationTargetFake {
    var starts = 0;
    var declines = 0;
    var queued = 0;
    function confirmedStart() as Void { starts += 1; }
    function declinedStart() as Void { declines += 1; }
    function scheduleConfirmedStart() as Void { queued += 1; }
}

class StartSequenceAppFake extends ShiftSenseApp {
    var readyHeartRate = new HeartRateSourceFake();
    var startSawReleasedSensor = false;

    function createReadyView() {
        return new ReadyView(self, new ReadyStatusSourceFake(), readyHeartRate, new ClockFake());
    }

    function confirmedStart() as Void {
        startSawReleasedSensor = readyHeartRate.stopCalls == 2;
    }
}

class ReadyStartTargetFake {
    var requests = 0;
    var calibrationRequests = 0;
    function requestStart() as Void { requests += 1; }
    function requestCalibration() as Void { calibrationRequests += 1; }
}

class RecordingSessionFake {
    var starts = 0;
    var stops = 0;
    var saves = 0;
    var discards = 0;
    var startResult = true;
    var stopResult = true;
    var saveResult = true;
    var discardResult = true;
    function start() as Lang.Boolean { starts += 1; return startResult; }
    function stop() as Lang.Boolean { stops += 1; return stopResult; }
    function save() as Lang.Boolean { saves += 1; return saveResult; }
    function discard() as Lang.Boolean { discards += 1; return discardResult; }
}

class RecordingFactoryFake {
    var creates = 0;
    var session = new RecordingSessionFake();
    var lastOptions = null;
    function createSession(options) { creates += 1; lastOptions = options; return session; }
}

class ClockFake {
    var now = 1000;
    function nowMs() as Lang.Number { return now; }
}

class TapEventFake extends WatchUi.ClickEvent {
    function getCoordinates() {
        var settings = Toybox.System.getDeviceSettings();
        return [settings.screenWidth/2, settings.screenHeight*90/100];
    }
}

class OutsideReadyTapEventFake extends WatchUi.ClickEvent {
    function getCoordinates() {
        var settings = Toybox.System.getDeviceSettings();
        return [settings.screenWidth/2, settings.screenHeight*79/100];
    }
}

class OutsideReadySideTapEventFake extends WatchUi.ClickEvent {
    function getCoordinates() {
        var settings = Toybox.System.getDeviceSettings();
        return [settings.screenWidth*10/100, settings.screenHeight*90/100];
    }
}

class PhysicalKeyEventFake extends WatchUi.KeyEvent {
    private var mFakeKey;
    function initialize(key) { mFakeKey = key; }
    function getKey() { return mFakeKey; }
}

class SwipeEventFake extends WatchUi.SwipeEvent { }

class ProfileSourceFake {
    var maximum = 200;
    var zones = null;
    function read() { return {:hrMax=>maximum, :hrZones=>zones, :available=>{:hrMax=>maximum != null}}; }
}

class HeartRateSourceFake {
    var startCalls = 0;
    var stopCalls = 0;
    var startResult = true;
    function start(listener) as Lang.Boolean { startCalls += 1; return startResult; }
    function stop() as Void { stopCalls += 1; }
}

(:test)
function appOpensReadyScreenBeforeRecordingConfirmation(logger as Test.Logger) as Lang.Boolean {
    var initial = new ShiftSenseApp().getInitialView();
    return initial[0] instanceof WatchUi.View &&
        !(initial[0] instanceof WatchUi.Confirmation);
}

(:test)
function readyUpperKeyRequestsRecordingConfirmation(logger as Test.Logger) as Lang.Boolean {
    var target = new ReadyStartTargetFake();
    var delegate = new ReadyInputDelegate(new ReadyView(target,
        new ReadyStatusSourceFake(), new HeartRateSourceFake(), new ClockFake()));
    return delegate.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ENTER)) &&
        target.requests == 1;
}

(:test)
function readyStartAreaRequestsRecordingConfirmation(logger as Test.Logger) as Lang.Boolean {
    var target = new ReadyStartTargetFake();
    var delegate = new ReadyInputDelegate(new ReadyView(target,
        new ReadyStatusSourceFake(), new HeartRateSourceFake(), new ClockFake()));
    return delegate.onTap(new TapEventFake()) && target.requests == 1;
}

(:test)
function readyStatusAreaTapDoesNotStartRecording(logger as Test.Logger) as Lang.Boolean {
    var target = new ReadyStartTargetFake();
    var delegate = new ReadyInputDelegate(new ReadyView(target,
        new ReadyStatusSourceFake(), new HeartRateSourceFake(), new ClockFake()));
    delegate.onTap(new OutsideReadyTapEventFake());
    return target.requests == 0;
}

(:test)
function readySideTapDoesNotStartRecording(logger as Test.Logger) as Lang.Boolean {
    var target = new ReadyStartTargetFake();
    var delegate = new ReadyInputDelegate(new ReadyView(target,
        new ReadyStatusSourceFake(), new HeartRateSourceFake(), new ClockFake()));
    delegate.onTap(new OutsideReadySideTapEventFake());
    return target.requests == 0;
}

(:test)
function confirmationYesDefersRecordingUntilDialogCloses(logger as Test.Logger) as Lang.Boolean {
    var target = new ConfirmationTargetFake();
    var delegate = new StartConfirmationDelegate(target);
    return delegate.onResponse(WatchUi.CONFIRM_YES) &&
        delegate.onResponse(WatchUi.CONFIRM_YES) &&
        target.queued == 1 && target.starts == 0 && target.declines == 0;
}

(:test)
function confirmationNoDeclinesWithoutStarting(logger as Test.Logger) as Lang.Boolean {
    var target = new ConfirmationTargetFake();
    var delegate = new StartConfirmationDelegate(target);
    return delegate.onResponse(WatchUi.CONFIRM_NO) && target.starts == 0 &&
        target.queued == 0 && target.declines == 0;
}

(:test)
function confirmationReturnReleasesReadySensorBeforeLiveStart(logger as Test.Logger) as Lang.Boolean {
    var app = new StartSequenceAppFake();
    var ready = app.getInitialView()[0];
    ready.onShow();
    ready.onHide();
    ready.onShow();
    app.finishConfirmedStart();
    return app.startSawReleasedSensor;
}

(:test)
function standardRecordingStartsOnlyOnce(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    return recorder.start() && !recorder.start() && factory.creates == 1 && factory.session.starts == 1;
}

(:test)
function calibrationRecordingUsesSeparateSessionName(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    if (!recorder.startCalibration({:sport=>:inline, :condition=>:skate_only,
        :referenceDistanceCm=>2500})) { return false; }
    return factory.lastOptions[:name].equals("ShiftSense Hockey Calibration") &&
        factory.lastOptions[:sport] == Activity.SPORT_HOCKEY;
}

(:test)
function coordinatorCalibrationStartsASeparateRecording(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    var coordinator = new RecordingCoordinator(new SessionRecorder(factory), new ClockFake());
    if (!coordinator.startCalibration({:sport=>:inline, :condition=>:skate_only,
        :referenceDistanceCm=>2500})) { return false; }
    return factory.lastOptions[:name].equals("ShiftSense Hockey Calibration");
}

(:test)
function recordingIsSavedAsHockeyInsteadOfOther(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    return recorder.start() && factory.lastOptions != null &&
        factory.lastOptions[:sport] == Toybox.Activity.SPORT_HOCKEY;
}

(:test)
function liveElapsedTimeStartsAtZeroAndAdvances(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(new SessionRecorder(factory), clock);
    if (!coordinator.start()) { return false; }
    var initial = coordinator.getElapsedMs() == 0;
    clock.now = 6500;
    return initial && coordinator.getElapsedMs() == 5500;
}

(:test)
function stopAndSaveClosesSessionOnce(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    var coordinator = new RecordingCoordinator(new SessionRecorder(factory), new ClockFake());
    if (!coordinator.start()) { return false; }
    return coordinator.stopAndSave() && !coordinator.stopAndSave() &&
        factory.session.stops == 1 && factory.session.saves == 1 &&
        coordinator.getState() == :saved;
}

(:test)
function failedSaveCanRetryWithoutStoppingAgain(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    factory.session.saveResult = false;
    var coordinator = new RecordingCoordinator(new SessionRecorder(factory), new ClockFake());
    if (!coordinator.start() || coordinator.stopAndSave()) { return false; }
    factory.session.saveResult = true;
    return coordinator.getState() == :stopped && coordinator.retrySave() &&
        factory.session.stops == 1 && factory.session.saves == 2;
}

(:test)
function coordinatorPreservesFrozenSessionSummaryAfterSave(logger as Test.Logger) as Lang.Boolean {
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), clock);
    coordinator.setDataSources(new ProfileSourceFake(), new HeartRateSourceFake());
    if (!coordinator.start() || !coordinator.toggleShift()) { return false; }
    for (var second = 0; second < 10; second += 1) {
        clock.now = 1100 + second * 1000;
        coordinator.onHeartRate({:heartRate=>150});
    }
    clock.now = 11000;
    if (!coordinator.toggleShift()) { return false; }
    clock.now = 20000;
    if (!coordinator.stopAndSave()) { return false; }
    var summary = coordinator.getSessionSummary();
    return summary != null && summary[:durationMs] == 19000 &&
        summary[:averageHeartRate] == 150 && summary[:maximumHeartRate] == 150 &&
        summary[:shiftCount] == 1 && summary[:timeOnIceMs] == 10000;
}

(:test)
function coordinatorClosesOpenSummaryShiftExactlyOnce(logger as Test.Logger) as Lang.Boolean {
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), clock);
    if (!coordinator.start() || !coordinator.toggleShift()) { return false; }
    clock.now = 11000;
    if (!coordinator.stopAndSave()) { return false; }
    var summary = coordinator.getSessionSummary();
    return summary[:shiftCount] == 1 && summary[:timeOnIceMs] == 10000 &&
        !coordinator.stopAndSave() && coordinator.getSessionSummary() == summary;
}

(:test)
function saveRetryReusesIdenticalFrozenSummary(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    factory.session.saveResult = false;
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(new SessionRecorder(factory), clock);
    if (!coordinator.start() || !coordinator.toggleShift()) { return false; }
    clock.now = 11000;
    if (coordinator.stopAndSave()) { return false; }
    var before = coordinator.getSessionSummary();
    factory.session.saveResult = true;
    return before != null && coordinator.retrySave() &&
        coordinator.getSessionSummary() == before && factory.session.stops == 1;
}

(:test)
function lowerButtonStartsShiftWithoutStoppingRecording(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(new SessionRecorder(factory), clock);
    coordinator.start();
    var view = new LiveView(coordinator);
    var delegate = new LiveInputDelegate(view);
    if (!delegate.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ESC))) { return false; }
    clock.now = 46000;
    var data = coordinator.getDashboard();
    return factory.session.stops == 0 && coordinator.getState() == :recording &&
        data[:shiftCount] == 1 && data[:onIce] == true && data[:timeOnIceMs] == 45000;
}

(:test)
function completedShiftsTrackLastAverageAndIceTime(logger as Test.Logger) as Lang.Boolean {
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(new SessionRecorder(new RecordingFactoryFake()), clock);
    if (!coordinator.start()) { return false; }
    var button = new LiveInputDelegate(new LiveView(coordinator));
    if (!button.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ESC))) { return false; }
    clock.now = 31000;
    if (!button.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ESC))) { return false; }
    clock.now = 36000;
    if (!button.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ESC))) { return false; }
    clock.now = 76000;
    if (!button.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ESC))) { return false; }
    var data = coordinator.getDashboard();
    return data[:shiftCount] == 2 && data[:onIce] == false &&
        data[:lastShiftMs] == 40000 && data[:averageShiftMs] == 35000 &&
        data[:timeOnIceMs] == 70000 && data[:elapsedMs] == 75000;
}

(:test)
function saveClosesRunningShiftAndFreezesDurations(logger as Test.Logger) as Lang.Boolean {
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(new SessionRecorder(new RecordingFactoryFake()), clock);
    if (!coordinator.start()) { return false; }
    var live = new LiveView(coordinator);
    if (!new LiveInputDelegate(live).onKey(new PhysicalKeyEventFake(WatchUi.KEY_ESC))) { return false; }
    clock.now = 21000;
    if (!coordinator.stopAndSave()) { return false; }
    clock.now = 31000;
    var data = coordinator.getDashboard();
    return data[:shiftCount] == 1 && data[:onIce] == false &&
        data[:lastShiftMs] == 20000 && data[:averageShiftMs] == 20000 &&
        data[:timeOnIceMs] == 20000 && data[:elapsedMs] == 20000;
}

(:test)
function liveDashboardTouchCannotStopRecording(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    var coordinator = new RecordingCoordinator(new SessionRecorder(factory), new ClockFake());
    if (!coordinator.start()) { return false; }
    var delegate = new LiveInputDelegate(new LiveView(coordinator));
    return delegate.onTap(new TapEventFake()) && coordinator.getState() == :recording &&
        factory.session.stops == 0;
}

(:test)
function rawLowerPhysicalKeyStartsShift(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    if (!coordinator.start()) { return false; }
    var delegate = new LiveInputDelegate(new LiveView(coordinator));
    return delegate.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ESC)) &&
        coordinator.getDashboard()[:shiftCount] == 1 && coordinator.getState() == :recording;
}

(:test)
function rawUpperPhysicalKeySavesRecording(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    var coordinator = new RecordingCoordinator(new SessionRecorder(factory), new ClockFake());
    if (!coordinator.start()) { return false; }
    var delegate = new LiveInputDelegate(new LiveView(coordinator));
    return delegate.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ENTER)) &&
        coordinator.getState() == :saved && factory.session.stops == 1;
}

(:test)
function liveInputHasNoTouchMappedBehaviorDelegate(logger as Test.Logger) as Lang.Boolean {
    var delegate = new LiveInputDelegate(new LiveView(null));
    return (delegate instanceof WatchUi.InputDelegate) &&
        !(delegate instanceof WatchUi.BehaviorDelegate) && delegate.onTap(new TapEventFake());
}

(:test)
function liveSwipeCannotChangeShiftOrRecording(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    if (!coordinator.start()) { return false; }
    var delegate = new LiveInputDelegate(new LiveView(coordinator));
    return delegate.onSwipe(new SwipeEventFake()) && coordinator.getDashboard()[:shiftCount] == 0 &&
        coordinator.getState() == :recording;
}

(:test)
function realGarminSessionStartsStopsAndSaves(logger as Test.Logger) as Lang.Boolean {
    var recorder = new SessionRecorder(new SystemSessionFactory());
    return recorder.start() && recorder.stopAndSave() && recorder.getState() == :saved;
}

(:test)
function liveDashboardUsesValidHrSamplesAndProfileMaximum(logger as Test.Logger) as Lang.Boolean {
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(new SessionRecorder(new RecordingFactoryFake()), clock);
    coordinator.setDataSources(new ProfileSourceFake(), new HeartRateSourceFake());
    if (!coordinator.start()) { return false; }
    coordinator.onHeartRate({:heartRate=>100, :quality=>:active});
    coordinator.onHeartRate({:heartRate=>null, :quality=>:missing});
    coordinator.onHeartRate({:heartRate=>180, :quality=>:active});
    var data = coordinator.getDashboard();
    return data[:heartRate] == 180 && data[:averageHeartRate] == 140 && data[:hrZone] == 5;
}

(:test)
function shiftAverageUsesOnlyValidSamplesInsideManualShift(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    if (!coordinator.start()) { return false; }
    coordinator.onHeartRate({:heartRate=>80});
    if (coordinator.getDashboard()[:shiftAverageHeartRate] != null ||
        !coordinator.toggleShift()) { return false; }
    coordinator.onHeartRate({:heartRate=>100});
    coordinator.onHeartRate({:heartRate=>null});
    coordinator.onHeartRate({:heartRate=>140});
    if (coordinator.getDashboard()[:shiftAverageHeartRate] != 120 ||
        !coordinator.toggleShift()) { return false; }
    coordinator.onHeartRate({:heartRate=>90});
    return coordinator.getDashboard()[:shiftAverageHeartRate] == 120;
}

(:test)
function newShiftClearsOldAverageAndSaveFreezesOpenShiftAverage(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    if (!coordinator.start() || !coordinator.toggleShift()) { return false; }
    coordinator.onHeartRate({:heartRate=>120});
    if (!coordinator.toggleShift() || !coordinator.toggleShift()) { return false; }
    if (coordinator.getDashboard()[:shiftAverageHeartRate] != null) { return false; }
    coordinator.onHeartRate({:heartRate=>160});
    return coordinator.stopAndSave() &&
        coordinator.getDashboard()[:shiftAverageHeartRate] == 160;
}

(:test)
function missingProfileMaximumLeavesZoneUnavailable(logger as Test.Logger) as Lang.Boolean {
    var profile = new ProfileSourceFake(); profile.maximum = null;
    var coordinator = new RecordingCoordinator(new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    coordinator.setDataSources(profile, new HeartRateSourceFake());
    if (!coordinator.start()) { return false; }
    coordinator.onHeartRate({:heartRate=>150, :quality=>:active});
    return coordinator.getDashboard()[:hrZone] == null;
}

(:test)
function stopReleasesHeartRateSource(logger as Test.Logger) as Lang.Boolean {
    var hr = new HeartRateSourceFake();
    var coordinator = new RecordingCoordinator(new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    coordinator.setDataSources(new ProfileSourceFake(), hr);
    return coordinator.start() && coordinator.stopAndSave() && hr.startCalls == 1 && hr.stopCalls == 1;
}

(:test)
function liveScreenDisplaysMissingAndMeasuredHeartRate(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    coordinator.setDataSources(new ProfileSourceFake(), new HeartRateSourceFake());
    coordinator.start();
    var live = new LiveView(coordinator);
    var empty = live.getDisplayValues();
    if (!empty[:heartRate].equals("--") || !empty[:averageHeartRate].equals("--") ||
        !empty[:hrZone].equals("--")) { return false; }
    coordinator.onHeartRate({:heartRate=>180, :quality=>:active});
    var measured = live.getDisplayValues();
    return measured[:heartRate].equals("180") &&
        measured[:averageHeartRate].equals("180") && measured[:hrZone].equals("5");
}

(:test)
function liveHeaderKeepsHeartRateZoneVisible(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    coordinator.setDataSources(new ProfileSourceFake(), new HeartRateSourceFake());
    if (!coordinator.start()) { return false; }
    coordinator.onHeartRate({:heartRate=>180, :quality=>:active});
    var zoneText = new LiveView(coordinator).getDisplayValues()[:zoneText];
    return zoneText != null && zoneText.equals("ZONE 5");
}

(:test)
function liveScreenFormatsAllSevenRequestedMetrics(logger as Test.Logger) as Lang.Boolean {
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(new SessionRecorder(new RecordingFactoryFake()), clock);
    coordinator.setDataSources(new ProfileSourceFake(), new HeartRateSourceFake());
    if (!coordinator.start()) { return false; }
    var live = new LiveView(coordinator);
    var initial = live.getDisplayValues();
    if (initial[:lastShift] == null || initial[:averageShift] == null ||
        initial[:timeOnIce] == null || initial[:elapsed] == null) { return false; }
    if (!initial[:lastShift].equals("--") || !initial[:averageShift].equals("--") ||
        !initial[:timeOnIce].equals("00:00") || !initial[:elapsed].equals("00:00")) { return false; }
    coordinator.onHeartRate({:heartRate=>150, :quality=>:active});
    if (!new LiveInputDelegate(live).onKey(new PhysicalKeyEventFake(WatchUi.KEY_ESC))) { return false; }
    clock.now = 31000;
    if (!new LiveInputDelegate(live).onKey(new PhysicalKeyEventFake(WatchUi.KEY_ESC))) { return false; }
    clock.now = 61000;
    var values = live.getDisplayValues();
    if (values[:shiftCount] == null || values[:lastShift] == null ||
        values[:averageShift] == null || values[:timeOnIce] == null ||
        values[:elapsed] == null) { return false; }
    return values[:heartRate].equals("--") && values[:averageHeartRate].equals("150") &&
        values[:shiftCount].equals("1") && values[:lastShift].equals("00:30") &&
        values[:averageShift].equals("00:30") && values[:timeOnIce].equals("00:30") &&
        values[:elapsed].equals("01:00");
}

(:test)
function failedStopCanRetryFromErrorView(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    factory.session.stopResult = false;
    var coordinator = new RecordingCoordinator(new SessionRecorder(factory), new ClockFake());
    if (!coordinator.start() || coordinator.stopAndSave()) { return false; }
    var errorView = new ErrorView(coordinator.getErrorCode(), coordinator);
    factory.session.stopResult = true;
    return errorView.retryFinish() && factory.session.stops == 2 &&
        factory.session.saves == 1 && coordinator.getState() == :saved;
}

(:test)
function failedSaveCannotLeaveUnsavedSessionViaBack(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    factory.session.saveResult = false;
    var coordinator = new RecordingCoordinator(new SessionRecorder(factory), new ClockFake());
    if (!coordinator.start() || coordinator.stopAndSave()) { return false; }
    var errorView = new ErrorView(coordinator.getErrorCode(), coordinator);
    return new ErrorInputDelegate(errorView).onBack() && coordinator.getState() == :stopped &&
        factory.session.discards == 0;
}

(:test)
function failedStartDiscardsCreatedSession(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    factory.session.startResult = false;
    var recorder = new SessionRecorder(factory);
    return !recorder.start() && factory.session.discards == 1 &&
        recorder.getState() == :failed;
}

(:test)
function customGarminZoneThresholdsTakePriority(logger as Test.Logger) as Lang.Boolean {
    var profile = new ProfileSourceFake();
    profile.zones = [90, 120, 150, 170, 185, 200];
    var coordinator = new RecordingCoordinator(new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    coordinator.setDataSources(profile, new HeartRateSourceFake());
    if (!coordinator.start()) { return false; }
    coordinator.onHeartRate({:heartRate=>150, :quality=>:active});
    return coordinator.getDashboard()[:hrZone] == 2;
}

(:test)
function sensorStartFailureIsVisibleWithoutStoppingRecording(logger as Test.Logger) as Lang.Boolean {
    var hr = new HeartRateSourceFake(); hr.startResult = false;
    var coordinator = new RecordingCoordinator(new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    coordinator.setDataSources(new ProfileSourceFake(), hr);
    return coordinator.start() && coordinator.getDashboard()[:sensorAvailable] == false &&
        coordinator.getDashboard()[:heartRate] == null && coordinator.stopAndSave();
}

(:test)
function realGarminSessionCanDiscardActiveRecording(logger as Test.Logger) as Lang.Boolean {
    var recorder = new SessionRecorder(new SystemSessionFactory());
    return recorder.start() && recorder.discardSession() && recorder.getState() == :discarded;
}

(:test)
function failedStartRetainsCleanupRetryWhenDiscardInitiallyFails(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    factory.session.startResult = false;
    factory.session.discardResult = false;
    var recorder = new SessionRecorder(factory);
    if (recorder.start() || !recorder.hasPendingSession()) { return false; }
    factory.session.discardResult = true;
    return recorder.discardSession() && !recorder.hasPendingSession() &&
        factory.session.discards == 2;
}
