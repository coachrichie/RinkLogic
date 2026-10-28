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

class AppRoutingFake extends ShiftSenseApp {
    var startRequests = 0;
    var introRequests = 0;
    var introSport = null;
    function requestStart() as Void { startRequests += 1; }
    function showCalibrationIntro(sport) as Void {
        introRequests += 1;
        introSport = sport;
    }
}

(:test)
function appRoutesOnlyExplicitValidSportConfirmations(logger as Test.Logger) as Lang.Boolean {
    var app = new AppRoutingFake();
    app.confirmSport(:training, :inline);
    if (app.startRequests != 1 || app.pendingTrainingSport() != :inline) { return false; }
    app.confirmSport(:calibration, :ice);
    if (app.introRequests != 1 || app.introSport != :ice) { return false; }
    app.confirmSport(:training, :run);
    app.confirmSport(:unknown, :ice);
    return app.startRequests == 1 && app.introRequests == 1;
}

class ReadyStartTargetFake {
    var requests = 0;
    var calibrationRequests = 0;
    var menuRequests = 0;
    var continueRequests = 0;
    function requestStart() as Void { requests += 1; }
    function requestCalibration() as Void { calibrationRequests += 1; }
    function requestStartMenu() as Void { menuRequests += 1; }
    function requestContinue() as Void { continueRequests += 1; }
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

class SessionRecorderSportSpy {
    var normalSport = null;
    var calibrationOptions = null;
    function start(sport) as Lang.Boolean { normalSport = sport; return true; }
    function startCalibration(options) as Lang.Boolean {
        calibrationOptions = options;
        return true;
    }
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

class ReadyMenuTapEventFake extends WatchUi.ClickEvent {
    function getCoordinates() {
        var settings = Toybox.System.getDeviceSettings();
        return [settings.screenWidth/2 - 120, settings.screenHeight*90/100];
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
    var height = null;
    var weight = null;
    function read() {
        return {:hrMax=>maximum, :hrZones=>zones, :heightCm=>height,
            :weightKg=>weight, :available=>{:hrMax=>maximum != null,
                :heightCm=>height != null, :weightKg=>weight != null}};
    }
}

class DistanceModelConfigFake {
    var selectedMode = :profile_height;
    var selectedPersonalFactor = 1.0;
    var selectedCalibrationSource = :none;
    var throwOnMode = false;
    var throwOnPersonalFactor = false;
    var throwOnCalibrationSource = false;
    function mode() as Lang.Symbol {
        if (throwOnMode) { throw new Lang.Exception(); }
        return selectedMode;
    }
    function personalCalibrationFactor() as Lang.Float {
        if (throwOnPersonalFactor) { throw new Lang.Exception(); }
        return selectedPersonalFactor;
    }
    function calibrationSource() as Lang.Symbol {
        if (throwOnCalibrationSource) { throw new Lang.Exception(); }
        return selectedCalibrationSource;
    }
}

class DistanceEstimatorConfigSpy extends DistanceEstimator {
    var configureCalls = 0;
    var configuredMode = null;
    var configuredHeight = null;
    var configuredPersonalFactor = null;
    var configuredCalibrationSource = null;
    var calls = [];
    function configure(modelMode, heightCm, personalFactor,
        calibrationSource) as Void {
        configureCalls += 1;
        configuredMode = modelMode;
        configuredHeight = heightCm;
        configuredPersonalFactor = personalFactor;
        configuredCalibrationSource = calibrationSource;
        calls.add(:configure);
        DistanceEstimator.configure(modelMode, heightCm, personalFactor,
            calibrationSource);
    }
    function beginShift(atMs) as Void {
        calls.add(:beginShift);
        DistanceEstimator.beginShift(atMs);
    }
}

(:test)
function coordinatorPassesCalibratedDistanceConfigBeforeStart(logger as Test.Logger) as Lang.Boolean {
    var profile = new ProfileSourceFake();
    profile.height = 180;
    var config = new DistanceModelConfigFake();
    config.selectedMode = :calibrated_profile_test;
    config.selectedPersonalFactor = 220.0 / 292.5;
    config.selectedCalibrationSource = :local_known_distance;
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    var estimator = new DistanceEstimatorConfigSpy();
    coordinator.setDistanceEstimator(estimator);
    coordinator.setDataSources(profile, null);
    if (!coordinator.setDistanceModelConfig(config) || !coordinator.start(:ice)) {
        return false;
    }
    var data = coordinator.getDashboard();
    return estimator.configureCalls == 1 &&
        estimator.configuredMode == :calibrated_profile_test &&
        estimator.configuredHeight == 180 &&
        estimator.configuredPersonalFactor > 0.752 &&
        estimator.configuredPersonalFactor < 0.753 &&
        estimator.configuredCalibrationSource == :local_known_distance &&
        data[:distanceModelSource] == :profile_height &&
        data[:distanceCalibrationSource] == :local_known_distance;
}

(:test)
function coordinatorFallsBackWhenCalibrationConfigThrows(logger as Test.Logger) as Lang.Boolean {
    for (var caseIndex = 0; caseIndex < 2; caseIndex += 1) {
        var config = new DistanceModelConfigFake();
        config.selectedMode = :calibrated_profile_test;
        config.throwOnPersonalFactor = caseIndex == 0;
        config.throwOnCalibrationSource = caseIndex == 1;
        var coordinator = new RecordingCoordinator(
            new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
        var estimator = new DistanceEstimatorConfigSpy();
        coordinator.setDistanceEstimator(estimator);
        if (!coordinator.setDistanceModelConfig(config) || !coordinator.start(:ice)) {
            return false;
        }
        if (estimator.configureCalls != 1 ||
            estimator.configuredPersonalFactor != 1.0 ||
            estimator.configuredCalibrationSource != :none ||
            coordinator.getDashboard()[:distanceCalibrationSource] != :none) {
            return false;
        }
    }
    return true;
}

class UnavailableDistanceProfileFake {
    var throwOnRead = false;
    var profile = {};
    function read() {
        if (throwOnRead) { throw new Lang.Exception(); }
        return profile;
    }
}

class HeartRateSourceFake {
    var startCalls = 0;
    var stopCalls = 0;
    var startResult = true;
    function start(listener) as Lang.Boolean { startCalls += 1; return startResult; }
    function stop() as Void { stopCalls += 1; }
}

(:test)
function coordinatorConfiguresDistanceFromHeightBeforeFirstShift(logger as Test.Logger) as Lang.Boolean {
    var profile = new ProfileSourceFake();
    profile.height = 200;
    profile.weight = 95;
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    var estimator = new DistanceEstimatorConfigSpy();
    coordinator.setDistanceEstimator(estimator);
    coordinator.setDataSources(profile, null);
    if (!(coordinator has :setDistanceModelConfig)) { return false; }
    if (coordinator.setDistanceModelConfig(null) ||
        !coordinator.setDistanceModelConfig(new DistanceModelConfigFake()) ||
        !coordinator.start(:ice)) { return false; }
    var replacement = new DistanceModelConfigFake();
    replacement.selectedMode = :fixed;
    if (coordinator.setDistanceModelConfig(replacement) || coordinator.start(:ice) ||
        !coordinator.toggleShift()) { return false; }
    return estimator.configureCalls == 1 && estimator.configuredMode == :profile_height &&
        estimator.configuredHeight == 200 && estimator.calls.size() == 2 &&
        estimator.calls[0] == :configure && estimator.calls[1] == :beginShift &&
        estimator.getModelSource() == :profile_height;
}

(:test)
function coordinatorKeepsRecordingWhenDistanceProfileIsUnavailable(logger as Test.Logger) as Lang.Boolean {
    for (var caseIndex = 0; caseIndex < 4; caseIndex += 1) {
        var profile = new UnavailableDistanceProfileFake();
        profile.throwOnRead = caseIndex == 0;
        if (caseIndex == 2) { profile.profile = {:heightCm=>{:invalid=>200}}; }
        var config = new DistanceModelConfigFake();
        config.throwOnMode = caseIndex == 3;
        var factory = new RecordingFactoryFake();
        var clock = new ClockFake();
        var coordinator = new RecordingCoordinator(new SessionRecorder(factory), clock);
        var estimator = new DistanceEstimatorConfigSpy();
        coordinator.setDistanceEstimator(estimator);
        coordinator.setDataSources(profile, null);
        if (!(coordinator has :setDistanceModelConfig)) { return false; }
        if (!coordinator.setDistanceModelConfig(config) || !coordinator.start(:ice)) { return false; }
        if (caseIndex < 2 && (estimator.configureCalls != 1 ||
            estimator.configuredHeight != null)) { return false; }
        if (caseIndex == 3 && (estimator.configureCalls != 1 ||
            estimator.configuredMode != :fixed ||
            estimator.configuredPersonalFactor != 1.0 ||
            estimator.configuredCalibrationSource != :none)) { return false; }
        if (estimator.getModelSource() != :default || !coordinator.toggleShift()) { return false; }
        clock.now += 1;
        if (!coordinator.toggleShift() || coordinator.getState() != :recording ||
            factory.session.starts != 1 || !coordinator.stopAndSave()) { return false; }
    }
    return true;
}

(:test)
function coordinatorDashboardReportsDistanceModelSourceInMemory(logger as Test.Logger) as Lang.Boolean {
    var profile = new ProfileSourceFake();
    profile.height = 200;
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    coordinator.setDataSources(profile, null);
    if (!(coordinator has :setDistanceModelConfig)) { return false; }
    if (!coordinator.setDistanceModelConfig(new DistanceModelConfigFake()) ||
        !coordinator.start(:ice)) { return false; }
    var data = coordinator.getDashboard();
    return data.hasKey(:distanceModelSource) && data[:distanceModelSource] == :profile_height &&
        data.hasKey(:distanceCalibrationSource) && data[:distanceCalibrationSource] == :none &&
        data[:shiftPushes] == null && data[:lastShiftPushes] == null &&
        data[:shiftDistanceCm] == null && data[:lastShiftDistanceCm] == null &&
        data[:totalPushes] == 0 && data[:totalDistanceCm] == 0 &&
        data[:shortPushesTotal] == 0 && data[:cadencePerMin] == null &&
        data[:coveragePercent] == null && !data[:hasValidMotion] &&
        !data[:partial] && !data[:onIce] && data[:shiftCount] == 0;
}

(:test)
function appOpensReadyScreenBeforeRecordingConfirmation(logger as Test.Logger) as Lang.Boolean {
    var initial = new ShiftSenseApp().getInitialView();
    return initial[0] instanceof WatchUi.View &&
        !(initial[0] instanceof WatchUi.Confirmation);
}

(:test)
function readyLowerKeyDoesNotBypassTheStartMenu(logger as Test.Logger) as Lang.Boolean {
    var target = new ReadyStartTargetFake();
    var delegate = new ReadyInputDelegate(new ReadyView(target,
        new ReadyStatusSourceFake(), new HeartRateSourceFake(), new ClockFake()));
    return !delegate.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ESC)) &&
        target.continueRequests == 0 && target.requests == 0;
}

(:test)
function readyUpperKeyRequestsContinue(logger as Test.Logger) as Lang.Boolean {
    var target = new ReadyStartTargetFake();
    var delegate = new ReadyInputDelegate(new ReadyView(target,
        new ReadyStatusSourceFake(), new HeartRateSourceFake(), new ClockFake()));
    return delegate.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ENTER)) &&
        target.continueRequests == 1 && target.requests == 0;
}

(:test)
function readyContinueAreaOpensStartMenu(logger as Test.Logger) as Lang.Boolean {
    var target = new ReadyStartTargetFake();
    var delegate = new ReadyInputDelegate(new ReadyView(target,
        new ReadyStatusSourceFake(), new HeartRateSourceFake(), new ClockFake()));
    return delegate.onTap(new TapEventFake()) && target.continueRequests == 1;
}

(:test)
function readySideOfContinueAreaDoesNothing(logger as Test.Logger) as Lang.Boolean {
    var target = new ReadyStartTargetFake();
    var delegate = new ReadyInputDelegate(new ReadyView(target,
        new ReadyStatusSourceFake(), new HeartRateSourceFake(), new ClockFake()));
    return !delegate.onTap(new ReadyMenuTapEventFake()) &&
        target.continueRequests == 0;
}

(:test)
function readyStatusAreaTapDoesNotStartRecording(logger as Test.Logger) as Lang.Boolean {
    var target = new ReadyStartTargetFake();
    var delegate = new ReadyInputDelegate(new ReadyView(target,
        new ReadyStatusSourceFake(), new HeartRateSourceFake(), new ClockFake()));
    delegate.onTap(new OutsideReadyTapEventFake());
    return target.requests == 0 && target.calibrationRequests == 0;
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
    return recorder.start(:ice) && !recorder.start(:ice) && factory.creates == 1 && factory.session.starts == 1;
}

(:test)
function sportRecordingUsesDistinctNamesAndRejectsInvalidBeforeCreate(logger as Test.Logger) as Lang.Boolean {
    var invalidFactory = new RecordingFactoryFake();
    var invalidRecorder = new SessionRecorder(invalidFactory);
    if (invalidRecorder.start(:run) || invalidFactory.creates != 0) { return false; }
    var iceFactory = new RecordingFactoryFake();
    var iceRecorder = new SessionRecorder(iceFactory);
    if (!iceRecorder.start(:ice) ||
        !iceFactory.lastOptions[:name].equals("RinkLogic Ice Hockey")) { return false; }
    var inlineFactory = new RecordingFactoryFake();
    var inlineRecorder = new SessionRecorder(inlineFactory);
    return inlineRecorder.start(:inline) &&
        inlineFactory.lastOptions[:name].equals("RinkLogic Inline Hockey") &&
        inlineFactory.lastOptions[:sport] == Activity.SPORT_HOCKEY;
}

(:test)
function coordinatorValidatesSportBeforeCreatingSession(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    var coordinator = new RecordingCoordinator(new SessionRecorder(factory), new ClockFake());
    return !coordinator.start(:run) && factory.creates == 0 &&
        coordinator.start(:inline) && factory.creates == 1 &&
        factory.lastOptions[:name].equals("RinkLogic Inline Hockey");
}

(:test)
function calibrationStartRetainsSportAndFixedTwentyMetreReference(logger as Test.Logger) as Lang.Boolean {
    var recorder = new SessionRecorderSportSpy();
    var coordinator = new RecordingCoordinator(recorder, new ClockFake());
    if (coordinator.startCalibration({:sport=>:inline, :referenceDistanceCm=>2500})) {
        return false;
    }
    if (!coordinator.startCalibration({:sport=>:inline, :referenceDistanceCm=>2000})) {
        return false;
    }
    return recorder.calibrationOptions[:sport] == :inline &&
        recorder.calibrationOptions[:referenceDistanceCm] == 2000;
}

(:test)
function calibrationRecordingUsesSeparateSessionName(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    if (!recorder.startCalibration({:sport=>:inline, :condition=>:skate_only,
        :referenceDistanceCm=>2000})) { return false; }
    return factory.lastOptions[:name].equals("RinkLogic Hockey Calibration") &&
        factory.lastOptions[:sport] == Activity.SPORT_HOCKEY;
}

(:test)
function coordinatorCalibrationStartsASeparateRecording(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    var coordinator = new RecordingCoordinator(new SessionRecorder(factory), new ClockFake());
    if (!coordinator.startCalibration({:sport=>:inline, :condition=>:skate_only,
        :referenceDistanceCm=>2000})) { return false; }
    return factory.lastOptions[:name].equals("RinkLogic Hockey Calibration");
}

(:test)
function calibrationRecordingBypassesStoredPersonalFactor(logger as Test.Logger) as Lang.Boolean {
    var store = new StoredProfileStoreFake();
    store.iceProfile = {:schemaVersion=>1, :sport=>:ice, :factor=>0.8,
        :source=>:local_known_distance, :referenceDistanceCm=>2500,
        :conditionMedians=>{:skate_only=>0.8, :puck_stickhandling=>0.8}};
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    var estimator = new DistanceEstimatorConfigSpy();
    coordinator.setDistanceEstimator(estimator);
    coordinator.setDistanceModelConfig(new StoredDistanceModelConfig(
        new DistanceModelConfigFake(), store));
    if (!coordinator.startCalibration({:sport=>:ice, :referenceDistanceCm=>2000})) {
        return false;
    }
    return estimator.configuredMode == :profile_height &&
        estimator.configuredPersonalFactor == 1.0 &&
        estimator.configuredCalibrationSource == :none;
}

(:test)
function normalRecordingFreezesStoredFactorInSummary(logger as Test.Logger) as Lang.Boolean {
    var store = new StoredProfileStoreFake();
    store.iceProfile = {:schemaVersion=>1, :sport=>:ice, :factor=>0.875,
        :source=>:local_known_distance, :referenceDistanceCm=>2500,
        :conditionMedians=>{:skate_only=>0.875, :puck_stickhandling=>0.875}};
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    coordinator.setDistanceModelConfig(new StoredDistanceModelConfig(
        new DistanceModelConfigFake(), store));
    if (!coordinator.start(:ice)) { return false; }
    store.iceProfile[:factor] = 1.25;
    if (!coordinator.stopAndSave()) { return false; }
    return coordinator.getSessionSummary()[:personalCalibrationFactor] == 0.875;
}

(:test)
function calibrationSessionAcceptsOnlyValidExplicitFactor(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    if (coordinator.setSessionCalibrationFactor(1.0) ||
        !coordinator.startCalibration({:sport=>:inline, :referenceDistanceCm=>2000}) ||
        coordinator.setSessionCalibrationFactor(0.49) ||
        coordinator.setSessionCalibrationFactor(1.51) ||
        !coordinator.setSessionCalibrationFactor(1.125) ||
        !coordinator.stopAndSave()) { return false; }
    return coordinator.getSessionSummary()[:personalCalibrationFactor] == 1.125;
}

(:test)
function normalSessionRejectsExplicitCalibrationFactor(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    return coordinator.setDistanceModelConfig(new DistanceModelConfigFake()) &&
        coordinator.start(:ice) && !coordinator.setSessionCalibrationFactor(1.0) &&
        coordinator.stopAndSave() &&
        !coordinator.getSessionSummary().hasKey(:personalCalibrationFactor);
}

(:test)
function recordingIsSavedAsHockeyInsteadOfOther(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    return recorder.start(:ice) && factory.lastOptions != null &&
        factory.lastOptions[:sport] == Toybox.Activity.SPORT_HOCKEY;
}

(:test)
function liveElapsedTimeStartsAtZeroAndAdvances(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(new SessionRecorder(factory), clock);
    if (!coordinator.start(:ice)) { return false; }
    var initial = coordinator.getElapsedMs() == 0;
    clock.now = 6500;
    return initial && coordinator.getElapsedMs() == 5500;
}

(:test)
function stopAndSaveClosesSessionOnce(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    var coordinator = new RecordingCoordinator(new SessionRecorder(factory), new ClockFake());
    if (!coordinator.start(:ice)) { return false; }
    return coordinator.stopAndSave() && !coordinator.stopAndSave() &&
        factory.session.stops == 1 && factory.session.saves == 1 &&
        coordinator.getState() == :saved;
}

(:test)
function failedSaveCanRetryWithoutStoppingAgain(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    factory.session.saveResult = false;
    var coordinator = new RecordingCoordinator(new SessionRecorder(factory), new ClockFake());
    if (!coordinator.start(:ice) || coordinator.stopAndSave()) { return false; }
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
    if (!coordinator.start(:ice) || !coordinator.toggleShift()) { return false; }
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
    if (!coordinator.start(:ice) || !coordinator.toggleShift()) { return false; }
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
    if (!coordinator.start(:ice) || !coordinator.toggleShift()) { return false; }
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
    coordinator.start(:ice);
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
    if (!coordinator.start(:ice)) { return false; }
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
    if (!coordinator.start(:ice)) { return false; }
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
    if (!coordinator.start(:ice)) { return false; }
    var delegate = new LiveInputDelegate(new LiveView(coordinator));
    return delegate.onTap(new TapEventFake()) && coordinator.getState() == :recording &&
        factory.session.stops == 0;
}

(:test)
function rawLowerPhysicalKeyStartsShift(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    if (!coordinator.start(:ice)) { return false; }
    var delegate = new LiveInputDelegate(new LiveView(coordinator));
    return delegate.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ESC)) &&
        coordinator.getDashboard()[:shiftCount] == 1 && coordinator.getState() == :recording;
}

(:test)
function rawUpperPhysicalKeySavesRecording(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    var coordinator = new RecordingCoordinator(new SessionRecorder(factory), new ClockFake());
    if (!coordinator.start(:ice)) { return false; }
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
    if (!coordinator.start(:ice)) { return false; }
    var delegate = new LiveInputDelegate(new LiveView(coordinator));
    return delegate.onSwipe(new SwipeEventFake()) && coordinator.getDashboard()[:shiftCount] == 0 &&
        coordinator.getState() == :recording;
}

(:test)
function realGarminSessionStartsStopsAndSaves(logger as Test.Logger) as Lang.Boolean {
    var recorder = new SessionRecorder(new SystemSessionFactory());
    return recorder.start(:ice) && recorder.stopAndSave() && recorder.getState() == :saved;
}

(:test)
function liveDashboardUsesValidHrSamplesAndProfileMaximum(logger as Test.Logger) as Lang.Boolean {
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(new SessionRecorder(new RecordingFactoryFake()), clock);
    coordinator.setDataSources(new ProfileSourceFake(), new HeartRateSourceFake());
    if (!coordinator.start(:ice)) { return false; }
    coordinator.onHeartRate({:heartRate=>100, :quality=>:active});
    coordinator.onHeartRate({:heartRate=>null, :quality=>:missing});
    coordinator.onHeartRate({:heartRate=>180, :quality=>:active});
    var data = coordinator.getDashboard();
    return data[:heartRate] == 180 && data[:averageHeartRate] == 140 && data[:hrZone] == 5;
}

(:test)
function shiftAverageUsesOnlyValidSamplesInsideManualShift(logger as Test.Logger) as Lang.Boolean {
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), clock);
    if (!coordinator.start(:ice)) { return false; }
    coordinator.onHeartRate({:heartRate=>80});
    if (coordinator.getDashboard()[:shiftAverageHeartRate] != null ||
        !coordinator.toggleShift()) { return false; }
    coordinator.onHeartRate({:heartRate=>100});
    coordinator.onHeartRate({:heartRate=>null});
    coordinator.onHeartRate({:heartRate=>140});
    if (coordinator.getDashboard()[:shiftAverageHeartRate] != 120) { return false; }
    clock.now += 1;
    if (!coordinator.toggleShift()) { return false; }
    coordinator.onHeartRate({:heartRate=>90});
    return coordinator.getDashboard()[:shiftAverageHeartRate] == 120;
}

(:test)
function newShiftClearsOldAverageAndSaveFreezesOpenShiftAverage(logger as Test.Logger) as Lang.Boolean {
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), clock);
    if (!coordinator.start(:ice) || !coordinator.toggleShift()) { return false; }
    coordinator.onHeartRate({:heartRate=>120});
    clock.now += 1;
    if (!coordinator.toggleShift()) { return false; }
    clock.now += 1;
    if (!coordinator.toggleShift()) { return false; }
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
    if (!coordinator.start(:ice)) { return false; }
    coordinator.onHeartRate({:heartRate=>150, :quality=>:active});
    return coordinator.getDashboard()[:hrZone] == null;
}

(:test)
function stopReleasesHeartRateSource(logger as Test.Logger) as Lang.Boolean {
    var hr = new HeartRateSourceFake();
    var coordinator = new RecordingCoordinator(new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    coordinator.setDataSources(new ProfileSourceFake(), hr);
    return coordinator.start(:ice) && coordinator.stopAndSave() && hr.startCalls == 1 && hr.stopCalls == 1;
}

(:test)
function liveScreenDisplaysMissingAndMeasuredHeartRate(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    coordinator.setDataSources(new ProfileSourceFake(), new HeartRateSourceFake());
    coordinator.start(:ice);
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
    if (!coordinator.start(:ice)) { return false; }
    coordinator.onHeartRate({:heartRate=>180, :quality=>:active});
    var zoneText = new LiveView(coordinator).getDisplayValues()[:zoneText];
    return zoneText != null && zoneText.equals("ZONE 5");
}

(:test)
function liveScreenFormatsAllSevenRequestedMetrics(logger as Test.Logger) as Lang.Boolean {
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(new SessionRecorder(new RecordingFactoryFake()), clock);
    coordinator.setDataSources(new ProfileSourceFake(), new HeartRateSourceFake());
    if (!coordinator.start(:ice)) { return false; }
    var live = new LiveView(coordinator);
    var initial = live.getDisplayValues();
    if (initial[:lastShift] == null || initial[:averageShift] == null ||
        initial[:timeOnIce] == null || initial[:elapsed] == null) { return false; }
    if (!initial[:lastShift].equals("--") || !initial[:averageShift].equals("--") ||
        !initial[:timeOnIce].equals("0.0 min") || !initial[:elapsed].equals("0.0 min")) { return false; }
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
        values[:shiftCount].equals("1") && values[:lastShift].equals("0.50 min") &&
        values[:averageShift].equals("0.50 min") && values[:timeOnIce].equals("0.5 min") &&
        values[:elapsed].equals("1.0 min");
}

(:test)
function failedStopCanRetryFromErrorView(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    factory.session.stopResult = false;
    var coordinator = new RecordingCoordinator(new SessionRecorder(factory), new ClockFake());
    if (!coordinator.start(:ice) || coordinator.stopAndSave()) { return false; }
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
    if (!coordinator.start(:ice) || coordinator.stopAndSave()) { return false; }
    var errorView = new ErrorView(coordinator.getErrorCode(), coordinator);
    return new ErrorInputDelegate(errorView).onBack() && coordinator.getState() == :stopped &&
        factory.session.discards == 0;
}

(:test)
function failedStartDiscardsCreatedSession(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    factory.session.startResult = false;
    var recorder = new SessionRecorder(factory);
    return !recorder.start(:ice) && factory.session.discards == 1 &&
        recorder.getState() == :failed;
}

(:test)
function customGarminZoneThresholdsTakePriority(logger as Test.Logger) as Lang.Boolean {
    var profile = new ProfileSourceFake();
    profile.zones = [90, 120, 150, 170, 185, 200];
    var coordinator = new RecordingCoordinator(new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    coordinator.setDataSources(profile, new HeartRateSourceFake());
    if (!coordinator.start(:ice)) { return false; }
    coordinator.onHeartRate({:heartRate=>150, :quality=>:active});
    return coordinator.getDashboard()[:hrZone] == 2;
}

(:test)
function sensorStartFailureIsVisibleWithoutStoppingRecording(logger as Test.Logger) as Lang.Boolean {
    var hr = new HeartRateSourceFake(); hr.startResult = false;
    var coordinator = new RecordingCoordinator(new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    coordinator.setDataSources(new ProfileSourceFake(), hr);
    return coordinator.start(:ice) && coordinator.getDashboard()[:sensorAvailable] == false &&
        coordinator.getDashboard()[:heartRate] == null && coordinator.stopAndSave();
}

(:test)
function realGarminSessionCanDiscardActiveRecording(logger as Test.Logger) as Lang.Boolean {
    var recorder = new SessionRecorder(new SystemSessionFactory());
    return recorder.start(:ice) && recorder.discardSession() && recorder.getState() == :discarded;
}

(:test)
function failedStartRetainsCleanupRetryWhenDiscardInitiallyFails(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    factory.session.startResult = false;
    factory.session.discardResult = false;
    var recorder = new SessionRecorder(factory);
    if (recorder.start(:ice) || !recorder.hasPendingSession()) { return false; }
    factory.session.discardResult = true;
    return recorder.discardSession() && !recorder.hasPendingSession() &&
        factory.session.discards == 2;
}
