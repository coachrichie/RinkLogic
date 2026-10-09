using Toybox.Lang;
using Toybox.Test as Test;
using Toybox.WatchUi;
using Toybox.System;

// This test intentionally uses Garmin ActivityRecording, not a fake factory.
(:test)
function realGarminSessionStartsMarksStopsAndSaves(logger as Test.Logger) as Lang.Boolean {
    var controller = new SessionController(new FitSessionFactory());
    var started = controller.start(HockeyMode.ICE);
    logger.debug("Real Garmin start=" + started);
    if (!started) { return false; }
    var marked = controller.markShift(:shift, 0);
    var stopped = controller.stop();
    var saved = stopped && controller.save();
    logger.debug("Real Garmin marker=" + marked + " stopped=" + stopped + " saved=" + saved);
    return marked && stopped && saved;
}

class AlphaClick {
    var mCoordinates;
    function initialize(x, y) { mCoordinates = alphaPoint(x, y); }
    function getCoordinates() { return mCoordinates; }
}

function alphaPoint(x, y) {
    var settings = System.getDeviceSettings();
    return [settings.screenWidth * x / 416, settings.screenHeight * y / 416];
}

class AlphaHrInfo {
    var heartRate;
    function initialize(value) { heartRate = value; }
}

class NullFitFactory { function createSession(options) { return null; } }

(:test)
function startFailuresIdentifyCreateCoreFieldInitialValueAndStartStages(logger as Test.Logger) as Lang.Boolean {
    var create = new SessionController(new NullFitFactory());
    var createFailed = !create.start(:ice) && create.getStartFailureCode().equals("CREATE");
    var fieldFake = new FakeFitSession();
    fieldFake.mFailId = 17;
    var field = new SessionController(fieldFake);
    var fieldFailed = !field.start(:ice) && field.getStartFailureCode().equals("FIELD:17");
    var initialFake = new FakeFitSession();
    initialFake.mFailSetDataId = 3;
    initialFake.mFailSetDataValue = 1;
    var initial = new SessionController(initialFake);
    var initialFailed = !initial.start(:ice) && initial.getStartFailureCode().equals("INIT");
    var startFake = new FakeFitSession();
    startFake.mStartResult = false;
    var start = new SessionController(startFake);
    return createFailed && fieldFailed && initialFailed && !start.start(:ice) && start.getStartFailureCode().equals("START");
}

(:test)
function optionalFitAllocationFailureDoesNotBlockCoreRecording(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    fake.mFailId = 4;
    var controller = new SessionController(fake);
    return controller.start(HockeyMode.ICE) && controller.markShift(:shift, 1000) && controller.stop() && controller.save();
}

(:test)
function eventCountsPersistWithNewIdsAndExistingSummarySemantics(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    var controller = new SessionController(fake);
    controller.start(HockeyMode.ICE);
    controller.setSummaryMetrics({:hits=>2, :passes=>11, :shots=>4, :iceTimeMs=>4000});
    controller.stop();
    var values = {};
    for (var i = 0; i < fake.mCreatedFields.size(); i += 1) {
        var field = fake.mCreatedFields[i];
        if (field != null) { values[field.mId] = field.mValue; }
    }
    return values[32] == 2 && values[33] == 11 && values[34] == 4 && values[27] == 4000 && values[24] == 3;
}

(:test)
function liveHrDashboardUsesRealSamplesAndProfileZones(logger as Test.Logger) as Lang.Boolean {
    var clock = new FlowClockFake();
    var controller = new FlowControllerFake();
    var live = new LiveView(controller, HockeyMode.ICE, clock, new FlowSensorFake(controller.mEvents), {});
    live.setPlayerProfile(new PlayerProfile(30, 200, 181));
    live.startConfirmed();
    var empty = live.getDashboard();
    if (empty[:hr] != null || empty[:avgHr] != null || empty[:zone] != null) { return false; }
    live.onSensorData(new AlphaHrInfo(120));
    clock.mNow = 2000;
    live.onSensorData(new AlphaHrInfo(180));
    var data = live.getDashboard();
    return data[:hr] == 180 && data[:avgHr] == 150 && data[:zone] == 5 &&
        data[:hrPercent] == 90 && data[:elapsedMs] == 1000;
}

(:test)
function liveEventsHaveSeparateTapRegionsAndPersistIntoSummary(logger as Test.Logger) as Lang.Boolean {
    var controller = new FlowControllerFake();
    var live = new LiveView(controller, HockeyMode.ICE, new FlowClockFake(), new FlowSensorFake(controller.mEvents), {});
    live.startConfirmed();
    var ignored = live.handleTap([5, 5]) == false;
    live.handleTap(alphaPoint(208, 96)); // page button
    live.handleTap(alphaPoint(208, 137)); // hit
    live.handleTap(alphaPoint(208, 187)); // pass
    live.handleTap(alphaPoint(208, 237)); // shot
    live.handleTap(alphaPoint(208, 237)); // second shot
    var data = live.getDashboard();
    live.stopConfirmed();
    return ignored && data[:page] == 1 && data[:hits] == 1 && data[:passes] == 1 && data[:shots] == 2 &&
        controller.mMarkerCalls == 0 && controller.mSummaryMetrics[:hits] == 1 &&
        controller.mSummaryMetrics[:passes] == 1 && controller.mSummaryMetrics[:shots] == 2;
}

// The old handler advances on every tap instead of selecting the HRmax row.
(:test)
function profileTapChoosesHrFieldWithoutAdvancing(logger as Test.Logger) as Lang.Boolean {
    var view = new ProfileView(new PlayerProfile(30, null, 181), new FlowControllerFake());
    var delegate = new ProfileInputDelegate(view);
    delegate.onTap(new AlphaClick(208, 191));
    delegate.onSelect();
    delegate.onNextPage();
    return view.getProfile().getAge() == 30 && view.getProfile().getTestedHrMax() == 182;
}

(:test)
function modeTapSelectsIndoorWithoutRequestingStart(logger as Test.Logger) as Lang.Boolean {
    var view = new ModeView(new FlowControllerFake());
    var delegate = new ModeInputDelegate(view);
    delegate.onTap(new AlphaClick(208, 179));
    return view.getSelectedMode() == HockeyMode.INLINE_INDOOR &&
        delegate.onTap(new AlphaClick(5, 5)) == false;
}

(:test)
function profileTouchMinusPlusAndAutoRestoreGarminHrMax(logger as Test.Logger) as Lang.Boolean {
    var view = new ProfileView(new PlayerProfile(30, null, 181), new FlowControllerFake());
    view.handleTap(alphaPoint(208, 191));
    view.handleTap(alphaPoint(300, 250));
    var changed = view.getProfile().getTestedHrMax() == 182;
    view.handleTap(alphaPoint(100, 250));
    var decreased = view.getProfile().getTestedHrMax() == 181;
    view.handleTap(alphaPoint(208, 250));
    return changed && decreased && view.getProfile().getTestedHrMax() == null &&
        view.getProfile().getHrMaxSource() == :garmin && view.getProfile().resolveHrMax() == 181;
}

(:test)
function hrZonesHandleExactBoundariesMissingAndStaleSamples(logger as Test.Logger) as Lang.Boolean {
    var clock = new FlowClockFake();
    var controller = new FlowControllerFake();
    var live = new LiveView(controller, HockeyMode.ICE, clock, new FlowSensorFake(controller.mEvents), {});
    live.setPlayerProfile(new PlayerProfile(30, 200, null));
    live.startConfirmed();
    var values = [99, 100, 119, 120, 139, 140, 159, 160, 179, 180, 220];
    var zones = [0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5];
    for (var i = 0; i < values.size(); i += 1) {
        live.onSensorData(new AlphaHrInfo(values[i]));
        if (live.getDashboard()[:zone] != zones[i]) { return false; }
    }
    var average = live.getDashboard()[:avgHr];
    live.onSensorData(new AlphaHrInfo(null));
    var missing = live.getDashboard()[:hr] == null && live.getDashboard()[:zone] == null;
    live.onSensorData(new AlphaHrInfo(0));
    if (live.getDashboard()[:avgHr] != average) { return false; }
    live.onSensorData(new AlphaHrInfo(150));
    live.onSensorData({:accelerometer=>null});
    var batchIgnored = live.getDashboard()[:hr] == 150;
    clock.mNow = 7001;
    return missing && batchIgnored && live.getDashboard()[:hr] == null && live.getDashboard()[:zone] == null;
}

(:test)
function buttonEventsCycleAndConfirmWithoutAccidentalShiftMarkers(logger as Test.Logger) as Lang.Boolean {
    var controller = new FlowControllerFake();
    var live = new LiveView(controller, HockeyMode.ICE, new FlowClockFake(), new FlowSensorFake(controller.mEvents), {});
    live.startConfirmed();
    var delegate = new HockeyInputDelegate(live);
    delegate.onNextPage(); // events, hits selected
    delegate.onSelect();
    delegate.onNextPage(); // passes
    delegate.onSelect();
    delegate.onNextPage(); // shots
    delegate.onSelect();
    var data = live.getDashboard();
    if (data[:hits] != 1 || data[:passes] != 1 || data[:shots] != 1 || controller.mMarkerCalls != 0) { return false; }
    delegate.onNextPage(); // marker
    delegate.onSelect();
    delegate.onNextPage(); // performance page
    delegate.onSelect();
    return live.getDashboard()[:page] == 0 && live.getDashboard()[:shifts] == 1 && controller.mMarkerCalls == 1;
}

(:test)
function realLiveFlowStartsSensorsRecordsAndSaves(logger as Test.Logger) as Lang.Boolean {
    var controller = new SessionController(new FitSessionFactory());
    var live = new LiveView(controller, HockeyMode.ICE, new FlowClockFake(), null, null);
    if (!live.startConfirmed()) { logger.debug(live.getStartFailureMessage()); return false; }
    live.onShow();
    live.togglePage();
    live.activateSelection(); // one manual hit
    live.onHide();
    var summary = live.stopConfirmed();
    return summary != null && controller.getState() == :saved && live.getDashboard()[:hits] == 1;
}

class ProfileNavigationProbe extends ProfileView {
    var advances = 0;
    function initialize(profile) { ProfileView.initialize(profile, new FlowControllerFake()); }
    function continueToMode() as Void { advances += 1; }
}

class ModeNavigationProbe extends ModeView {
    var requests = 0;
    function initialize() { ModeView.initialize(new FlowControllerFake()); }
    function requestStartConfirmation() as Void { requests += 1; }
}

(:test)
function modeStartRegionIsSeparateFromSelection(logger as Test.Logger) as Lang.Boolean {
    var view = new ModeNavigationProbe();
    view.handleTap(alphaPoint(208, 210));
    var selectionOnly = view.requests == 0 && view.getSelectedMode() == HockeyMode.INLINE_INDOOR;
    view.handleTap(alphaPoint(208, 270));
    return selectionOnly && view.requests == 1;
}

class LiveStopProbe extends LiveView {
    var stopRequests = 0;
    function initialize(controller, clock) {
        LiveView.initialize(controller, HockeyMode.ICE, clock, new FlowSensorFake(controller.mEvents), {});
    }
    function requestStopConfirmation() as Void { stopRequests += 1; }
}

(:test)
function liveStopAndMarkerRegionsDoNotCrossTrigger(logger as Test.Logger) as Lang.Boolean {
    var controller = new FlowControllerFake();
    var clock = new FlowClockFake();
    var live = new LiveStopProbe(controller, clock);
    live.startConfirmed();
    live.handleTap(alphaPoint(208, 350));
    var stoppedOnly = live.stopRequests == 1 && controller.mMarkerCalls == 0;
    live.handleTap(alphaPoint(208, 305));
    clock.mNow = 5000;
    var data = live.getDashboard();
    return stoppedOnly && live.stopRequests == 1 && controller.mMarkerCalls == 1 &&
        data[:iceTimeMs] == 4000 && data[:elapsedMs] == 4000 && data[:shifts] == 1 && data[:onIce];
}

(:test)
function failureCodeSurvivesThroughLiveViewForTheUser(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    fake.mFailId = 18;
    var controller = new SessionController(fake);
    var live = new LiveView(controller, HockeyMode.ICE, new FlowClockFake(), null, null);
    return live.startConfirmed() && live.getStartFailureMessage().equals(UiText.get(Rez.Strings.StartFailed) + " [FIELD:18]");
}

(:test)
function liveViewTracksNormalisedHrRrAndQuality(logger as Test.Logger) as Lang.Boolean {
    var live = new LiveView(new FlowControllerFake(), HockeyMode.ICE, new FlowClockFake(), null, null);
    live.startConfirmed();
    live.onSensorData({:heartRate=>150, :rrMs=>800, :timestampMs=>1000, :quality=>:external});
    var dashboard = live.getDashboard();
    return dashboard[:hr] == 150 && dashboard[:hrSampleCount] == 1 &&
        dashboard[:rrMs] == 800 && dashboard[:hrQuality] == :external;
}

(:test)
function liveViewAcceptsRrOnlySensorBatches(logger as Test.Logger) as Lang.Boolean {
    var live = new LiveView(new FlowControllerFake(), HockeyMode.ICE, new FlowClockFake(), null, null);
    live.startConfirmed();
    live.onSensorData({:rrMs=>790, :quality=>:rrOnly});
    var dashboard = live.getDashboard();
    return dashboard[:hr] == null && dashboard[:rrMs] == 790 &&
        dashboard[:hrQuality] == :rrOnly && dashboard[:hrSampleCount] == 0;
}

(:test)
function liveViewAccumulatesHrZonesAndRecovery(logger as Test.Logger) as Lang.Boolean {
    var clock = new FlowClockFake();
    var live = new LiveView(new FlowControllerFake(), HockeyMode.ICE, clock, null, {});
    live.setPlayerProfile(new PlayerProfile(30, 200, 200));
    live.startConfirmed();
    live.onSensorData({:heartRate=>180, :timestampMs=>0, :quality=>:active});
    clock.mNow = 10000;
    live.onSensorData({:heartRate=>110, :timestampMs=>10000, :quality=>:active});
    var dashboard = live.getDashboard();
    return dashboard[:zoneSeconds][5] >= 9 && dashboard[:recoveryMs] == 9000;
}

(:test)
function liveStopPassesHrSummariesToRecording(logger as Test.Logger) as Lang.Boolean {
    var clock = new FlowClockFake();
    var controller = new FlowControllerFake();
    var live = new LiveView(controller, HockeyMode.ICE, clock, new FlowSensorFake(controller.mEvents), {});
    live.setPlayerProfile(new PlayerProfile(30, 200, 200));
    live.startConfirmed();
    live.onSensorData({:heartRate=>180, :timestampMs=>1000, :quality=>:active});
    clock.mNow = 10000;
    live.onSensorData({:heartRate=>110, :timestampMs=>10000, :quality=>:active});
    live.stopConfirmed();
    return controller.mSummaryMetrics[:hrSampleCount] == 2 &&
        controller.mSummaryMetrics[:recoveryMs] > 0 &&
        controller.mSummaryMetrics[:hrZone5Seconds] > 0;
}

(:test)
function onlyExplicitProfileContinueAdvancesAndButtonBackClearsOverride(logger as Test.Logger) as Lang.Boolean {
    var view = new ProfileNavigationProbe(new PlayerProfile(30, 190, 181));
    var delegate = new ProfileInputDelegate(view);
    view.handleTap(alphaPoint(208, 191));
    var stayed = view.advances == 0;
    delegate.onBack();
    var cleared = view.getProfile().getTestedHrMax() == null;
    view.handleTap(alphaPoint(208, 325));
    return stayed && cleared && view.advances == 1;
}
