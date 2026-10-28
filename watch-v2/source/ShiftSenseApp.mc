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
    private var mSportPreferenceStore = null;
    private var mPendingTrainingSport = null;
    private var mPendingCalibrationCandidate = null;
    private var mCalibrationActivationWorkflow = null;

    function initialize() {
        AppBase.initialize();
        mCalibrationStore = createCalibrationProfileStore();
        mSportPreferenceStore = createSportPreferenceStore();
    }

    function createCalibrationProfileStore() {
        return new CalibrationProfileStore(new ApplicationCalibrationStoragePort());
    }

    function createSportPreferenceStore() {
        return new SportPreferenceStore(new ApplicationCalibrationStoragePort());
    }

    function sportPreferenceStore() {
        if (mSportPreferenceStore == null) {
            mSportPreferenceStore = createSportPreferenceStore();
        }
        return mSportPreferenceStore;
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var ready = createReadyView();
        mReadyView = ready;
        return [ready, new ReadyInputDelegate(ready)];
    }

    function createReadyView() {
        var ready = new ReadyView(self, new GarminReadyStatusService(),
            new HeartRateService(), new AppClock());
        try { ready.setCalibrationStatuses(mCalibrationStore.statuses()); }
        catch (ex) { ready.setCalibrationStatuses({:ice=>false, :inline=>false}); }
        return ready;
    }

    function requestStart() as Void {
        if (mPendingStartTimer != null) { return; }
        var dialog = new WatchUi.Confirmation(
            WatchUi.loadResource(Rez.Strings.StartQuestion));
        WatchUi.pushView(dialog, new StartConfirmationDelegate(self), WatchUi.SLIDE_IMMEDIATE);
    }

    function requestCalibration() as Void {
        var selected = sportPreferenceStore().load();
        var selector = new SportSelectionView(self, :calibration, selected);
        WatchUi.switchToView(selector, new SportSelectionInputDelegate(selector),
            WatchUi.SLIDE_IMMEDIATE);
    }

    function requestTraining() as Void {
        var selected = sportPreferenceStore().load();
        var selector = new SportSelectionView(self, :training, selected);
        WatchUi.switchToView(selector, new SportSelectionInputDelegate(selector),
            WatchUi.SLIDE_IMMEDIATE);
    }

    function confirmSport(purpose, sport) as Void {
        if ((purpose != :training && purpose != :calibration) ||
            !CalibrationTypes.validSport(sport)) { return; }
        sportPreferenceStore().save(sport);
        if (purpose == :training) {
            mPendingTrainingSport = sport;
            requestStart();
            return;
        }
        showCalibrationIntro(sport);
    }

    function showCalibrationIntro(sport) as Void {
        var intro = new CalibrationIntroView(self, sport);
        WatchUi.switchToView(intro, new CalibrationIntroInputDelegate(intro),
            WatchUi.SLIDE_IMMEDIATE);
    }

    function pendingTrainingSport() { return mPendingTrainingSport; }

    function requestStartMenu() as Void {
        var menu = new StartMenuView(self);
        WatchUi.switchToView(menu, new StartMenuInputDelegate(menu),
            WatchUi.SLIDE_IMMEDIATE);
    }

    function requestContinue() as Void { requestStartMenu(); }

    function exitApp() as Void { System.exit(); }

    function startCalibration(sport) as Void {
        mCalibrationController = new CalibrationController();
        if (!mCalibrationController.configure(sport)) {
            requestCalibration();
            return;
        }
        var recorder = new SessionRecorder(new SystemSessionFactory());
        recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
        mCoordinator = new RecordingCoordinator(recorder, new AppClock());
        mCoordinator.setDataSources(new GarminProfileService(), new HeartRateService());
        mCoordinator.setMotionSource(new MotionSource(new SystemMotionPort()));
        if (!mCoordinator.startCalibration({:sport=>sport,
            :referenceDistanceCm=>2000, :targetRepetitions=>10})) {
            var errorView = new ErrorView(mCoordinator.getErrorCode(), mCoordinator);
            WatchUi.switchToView(errorView, new ErrorInputDelegate(errorView), WatchUi.SLIDE_IMMEDIATE);
            return;
        }
        mCalibrationActivationWorkflow = new CalibrationActivationWorkflow(
            mCoordinator, mCalibrationStore);
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
        mCalibrationActivationWorkflow = null;
        requestStartMenu();
    }

    function confirmCancelCalibration() as Void {
        var dialog = new WatchUi.Confirmation(
            WatchUi.loadResource(Rez.Strings.ConfirmCalibrationCancel));
        WatchUi.pushView(dialog, new CalibrationCancelConfirmationDelegate(self),
            WatchUi.SLIDE_IMMEDIATE);
    }

    function confirmDiscardCalibration() as Void {
        var dialog = new WatchUi.Confirmation(
            WatchUi.loadResource(Rez.Strings.ConfirmCalibrationDiscard));
        WatchUi.pushView(dialog, new CalibrationDiscardConfirmationDelegate(self),
            WatchUi.SLIDE_IMMEDIATE);
    }

    function reviewCalibration(candidate) as Void {
        if (candidate == null) { return; }
        mPendingCalibrationCandidate = candidate;
        var review = new CalibrationSummaryView(self, candidate);
        WatchUi.switchToView(review, new CalibrationSummaryInputDelegate(review),
            WatchUi.SLIDE_IMMEDIATE);
    }

    function activateAndSaveCalibration() as Void {
        if (mCalibrationActivationWorkflow == null) { return; }
        var result = mCalibrationActivationWorkflow.activate(
            mPendingCalibrationCandidate);
        if (result == :save_error || result == :storage_error ||
            result == :candidate_error) {
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
            if (mCalibrationActivationWorkflow != null) {
                mCalibrationActivationWorkflow.discard();
            }
        }
        finishCalibration();
    }

    function finishCalibration() as Void {
        mCalibrationController = null;
        mCoordinator = null;
        mPendingCalibrationCandidate = null;
        mCalibrationActivationWorkflow = null;
        requestStartMenu();
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
        var sport = mPendingTrainingSport;
        mPendingTrainingSport = null;
        if (!CalibrationTypes.validSport(sport)) {
            requestStartMenu();
            return;
        }
        var recorder = new SessionRecorder(new SystemSessionFactory());
        recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
        mCoordinator = new RecordingCoordinator(recorder, new AppClock());
        mCoordinator.setDataSources(new GarminProfileService(), new HeartRateService());
        mCoordinator.setMotionSource(new MotionSource(new SystemMotionPort()));
        var distanceConfig = new DistanceModelConfig();
        distanceConfig.selectSport(sport);
        mCoordinator.setDistanceModelConfig(distanceConfig);
        if (mCoordinator.start(sport)) {
            var live = new LiveView(mCoordinator);
            WatchUi.switchToView(live, new LiveInputDelegate(live), WatchUi.SLIDE_IMMEDIATE);
        } else {
            var errorView = new ErrorView(mCoordinator.getErrorCode(), mCoordinator);
            WatchUi.switchToView(errorView, new ErrorInputDelegate(errorView), WatchUi.SLIDE_IMMEDIATE);
        }
    }
}
