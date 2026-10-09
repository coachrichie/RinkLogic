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

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var ready = createReadyView();
        mReadyView = ready;
        return [ready, new ReadyInputDelegate(ready)];
    }

    function createReadyView() {
        return new ReadyView(self, new GarminReadyStatusService(),
            new HeartRateService(), new AppClock());
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

    function startCalibration(sport, condition, distanceCm, repetitions) as Void {
        mCalibrationController = new CalibrationController();
        if (!mCalibrationController.configure(sport, condition, distanceCm, repetitions)) {
            requestCalibration();
            return;
        }
        var recorder = new SessionRecorder(new SystemSessionFactory());
        recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
        mCoordinator = new RecordingCoordinator(recorder, new AppClock());
        mCoordinator.setDataSources(new GarminProfileService(), new HeartRateService());
        mCoordinator.setMotionSource(new MotionSource(new SystemMotionPort()));
        if (!mCoordinator.startCalibration({:sport=>sport, :condition=>condition,
            :referenceDistanceCm=>distanceCm, :targetRepetitions=>repetitions})) {
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
        var ready = createReadyView();
        mReadyView = ready;
        WatchUi.switchToView(ready, new ReadyInputDelegate(ready), WatchUi.SLIDE_IMMEDIATE);
    }

    function saveCalibration() as Void {
        if (mCoordinator == null || !mCoordinator.stopAndSave()) {
            var errorView = new ErrorView(mCoordinator == null ? "CALIBRATION" :
                mCoordinator.getErrorCode(), mCoordinator);
            WatchUi.switchToView(errorView, new ErrorInputDelegate(errorView), WatchUi.SLIDE_IMMEDIATE);
            return;
        }
        var summary = mCalibrationController == null ?
            {:validRepetitions=>0, :invalidRepetitions=>0} :
            mCalibrationController.summary();
        WatchUi.switchToView(new CalibrationSummaryView(summary),
            new CalibrationSummaryInputDelegate(self), WatchUi.SLIDE_IMMEDIATE);
    }

    function finishCalibration() as Void {
        mCalibrationController = null;
        mCoordinator = null;
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
        if (mCoordinator.start()) {
            var live = new LiveView(mCoordinator);
            WatchUi.switchToView(live, new LiveInputDelegate(live), WatchUi.SLIDE_IMMEDIATE);
        } else {
            var errorView = new ErrorView(mCoordinator.getErrorCode(), mCoordinator);
            WatchUi.switchToView(errorView, new ErrorInputDelegate(errorView), WatchUi.SLIDE_IMMEDIATE);
        }
    }
}
