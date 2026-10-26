using Toybox.Application;
using Toybox.Lang;
using Toybox.System;
using Toybox.Timer;
using Toybox.WatchUi;

class ShiftSenseApp extends Application.AppBase {
    private var mCoordinator = null;
    private var mPendingStartTimer = null;
    private var mReadyView = null;
    private var mCalibrationController = null;
    private var mCalibrationStore = null;
    private var mPendingCalibrationCandidate = null;

    function initialize() {
        AppBase.initialize();
        mCalibrationStore = createCalibrationProfileStore();
    }

    function createCalibrationProfileStore() {
        return new CalibrationProfileStore(new ApplicationCalibrationStoragePort());
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var ready = createReadyView();
        mReadyView = ready;
        return [ready, new ReadyInputDelegate(ready)];
    }

    function createReadyView() {
        var ready = new ReadyView(self, new GarminReadyStatusService(),
            new HeartRateService(), new AppClock());
        try { ready.setCalibrationProfile(mCalibrationStore.loadActive()); }
        catch (ex) { ready.setCalibrationProfile(null); }
        return ready;
    }

    function requestStart() as Void {
        if (mPendingStartTimer != null) { return; }
        var dialog = new WatchUi.Confirmation(
            WatchUi.loadResource(Rez.Strings.StartQuestion));
        WatchUi.pushView(dialog, new StartConfirmationDelegate(self), WatchUi.SLIDE_IMMEDIATE);
    }

    function requestCalibration() as Void {
        var setup = new CalibrationSetupView(self);
        WatchUi.switchToView(setup, new CalibrationSetupInputDelegate(setup),
            WatchUi.SLIDE_IMMEDIATE);
    }

    function requestStartMenu() as Void {
        var menu = new StartMenuView(self);
        WatchUi.switchToView(menu, new StartMenuInputDelegate(menu),
            WatchUi.SLIDE_IMMEDIATE);
    }

    function requestContinue() as Void { requestStartMenu(); }

    function exitApp() as Void { System.exit(); }

    function startCalibration(sport, distanceCm) as Void {
        mCalibrationController = new CalibrationController();
        if (!mCalibrationController.configure(sport, distanceCm)) {
            requestCalibration();
            return;
        }
        var recorder = new SessionRecorder(new SystemSessionFactory());
        recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
        mCoordinator = new RecordingCoordinator(recorder, new AppClock());
        mCoordinator.setDataSources(new GarminProfileService(), new HeartRateService());
        mCoordinator.setMotionSource(new MotionSource(new SystemMotionPort()));
        if (!mCoordinator.startCalibration({:sport=>sport,
            :referenceDistanceCm=>distanceCm, :targetRepetitions=>10})) {
            var errorView = new ErrorView(mCoordinator.getErrorCode(), mCoordinator);
            WatchUi.switchToView(errorView, new ErrorInputDelegate(errorView), WatchUi.SLIDE_IMMEDIATE);
            return;
        }
        var run = new CalibrationRunView(self, mCalibrationController);
        run.setCoordinator(mCoordinator);
        WatchUi.switchToView(run, new CalibrationRunInputDelegate(run, new AppClock()),
            WatchUi.SLIDE_IMMEDIATE);
    }

    function cancelCalibration() as Void {
        if (mCoordinator != null && mCoordinator.hasPendingSession()) {
            mCoordinator.discardSession();
        }
        mCalibrationController = null;
        mPendingCalibrationCandidate = null;
        var ready = createReadyView();
        mReadyView = ready;
        WatchUi.switchToView(ready, new ReadyInputDelegate(ready), WatchUi.SLIDE_IMMEDIATE);
    }

    function reviewCalibration(candidate) as Void {
        if (candidate == null) { return; }
        mPendingCalibrationCandidate = candidate;
        var review = new CalibrationSummaryView(self, candidate);
        WatchUi.switchToView(review, new CalibrationSummaryInputDelegate(review),
            WatchUi.SLIDE_IMMEDIATE);
    }

    function activateAndSaveCalibration() as Void {
        var result = new CalibrationActivationWorkflow(mCoordinator,
            mCalibrationStore).activate(mPendingCalibrationCandidate);
        if (result == :save_error || result == :candidate_error) {
            var errorView = new ErrorView(mCoordinator == null ? "CALIBRATION" :
                mCoordinator.getErrorCode(), mCoordinator);
            WatchUi.switchToView(errorView, new ErrorInputDelegate(errorView),
                WatchUi.SLIDE_IMMEDIATE);
            return;
        }
        mPendingCalibrationCandidate = null;
        var outcome = new CalibrationOutcomeView(result);
        WatchUi.switchToView(outcome, new CalibrationSummaryOutcomeDelegate(self),
            WatchUi.SLIDE_IMMEDIATE);
    }

    function discardCalibration() as Void {
        if (mCoordinator != null) {
            new CalibrationActivationWorkflow(mCoordinator,
                mCalibrationStore).discard();
        }
        finishCalibration();
    }

    function finishCalibration() as Void {
        mCalibrationController = null;
        mCoordinator = null;
        mPendingCalibrationCandidate = null;
        var ready = createReadyView();
        mReadyView = ready;
        WatchUi.switchToView(ready, new ReadyInputDelegate(ready), WatchUi.SLIDE_IMMEDIATE);
    }

    function scheduleConfirmedStart() as Void {
        if (mPendingStartTimer != null) { return; }
        mPendingStartTimer = new Timer.Timer();
        mPendingStartTimer.start(method(:finishConfirmedStart), 100, false);
    }

    function finishConfirmedStart() as Void {
        mPendingStartTimer = null;
        if (mReadyView != null) { mReadyView.onHide(); }
        confirmedStart();
    }

    function confirmedStart() as Void {
        var recorder = new SessionRecorder(new SystemSessionFactory());
        recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
        mCoordinator = new RecordingCoordinator(recorder, new AppClock());
        mCoordinator.setDataSources(new GarminProfileService(), new HeartRateService());
        mCoordinator.setMotionSource(new MotionSource(new SystemMotionPort()));
        if (mCoordinator.start(:ice)) {
            var live = new LiveView(mCoordinator);
            WatchUi.switchToView(live, new LiveInputDelegate(live), WatchUi.SLIDE_IMMEDIATE);
        } else {
            var errorView = new ErrorView(mCoordinator.getErrorCode(), mCoordinator);
            WatchUi.switchToView(errorView, new ErrorInputDelegate(errorView), WatchUi.SLIDE_IMMEDIATE);
        }
    }
}
