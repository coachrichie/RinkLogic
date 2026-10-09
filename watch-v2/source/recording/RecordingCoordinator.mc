using Toybox.Lang;

class RecordingCoordinator {
    private var mRecorder;
    private var mClock;
    private var mStartedAt = null;
    private var mStoppedAt = null;
    private var mProfileSource = null;
    private var mHeartRateSource = null;
    private var mHeartRateSourceStarted = false;
    private var mProfile = null;
    private var mHeartRate = null;
    private var mHeartRateAt = null;
    private var mHrTotal = 0;
    private var mHrCount = 0;
    private var mShiftHrTotal = 0;
    private var mShiftHrCount = 0;
    private var mLastShiftHrAverage = null;
    private var mCompletedShiftHrAverageTotal = 0;
    private var mCompletedShiftHrAverageCount = 0;
    private var mShiftLedger;
    private var mMotionSource = null;
    private var mMotionSourceStarted = false;
    private var mShiftInference;
    private var mSampleSeq = 0;
    private var mPushDetector;
    private var mDistanceEstimator;
    private var mLastCompletedPushSummary = null;
    private var mOpenShiftFinalized = false;
    private var mCalibrationOptions = null;
    private var mAnalytics;
    private var mSessionSummary = null;
    private var mPendingPushSummaries;

    function initialize(recorder, clock) {
        mRecorder = recorder;
        mClock = clock;
        mShiftLedger = new ShiftEventLedger();
        mShiftInference = new ShiftInference();
        mPushDetector = new PushDetector();
        mDistanceEstimator = new DistanceEstimator();
        mAnalytics = new SessionAnalytics();
        mPendingPushSummaries = {};
    }

    function setDataSources(profileSource, heartRateSource) as Void {
        mProfileSource = profileSource;
        mHeartRateSource = heartRateSource;
    }

    function setMotionSource(source) as Void { mMotionSource = source; }
    function setPushDetector(detector) as Void { mPushDetector = detector; }
    function setDistanceEstimator(estimator) as Void { mDistanceEstimator = estimator; }

    function start() as Lang.Boolean {
        mCalibrationOptions = null;
        return startInternal();
    }

    function startCalibration(options) as Lang.Boolean {
        mCalibrationOptions = options;
        return startInternal();
    }

    private function startInternal() as Lang.Boolean {
        if (mStartedAt != null) { return false; }
        if (mProfileSource != null) {
            try { mProfile = mProfileSource.read(); } catch (ex) { mProfile = null; }
        }
        if (mHeartRateSource != null) {
            try { mHeartRateSourceStarted = mHeartRateSource.start(method(:onHeartRate)); }
            catch (ex) { mHeartRateSourceStarted = false; }
        }
        var started = mCalibrationOptions == null ? mRecorder.start() :
            mRecorder.startCalibration(mCalibrationOptions);
        if (!started) {
            releaseHeartRateSource();
            return false;
        }
        mStartedAt = mClock.nowMs();
        mAnalytics.start(mStartedAt, mProfile);
        try { mPushDetector.reset(); } catch (ex) { }
        if (mMotionSource != null) {
            try { mMotionSourceStarted = mMotionSource.start(method(:onMotionFeature)); }
            catch (ex) { mMotionSourceStarted = false; }
        }
        return true;
    }

    function getElapsedMs() as Lang.Number {
        if (mStartedAt == null) { return 0; }
        return (mStoppedAt == null ? mClock.nowMs() : mStoppedAt) - mStartedAt;
    }

    function onHeartRate(sample) as Void {
        if (mStartedAt == null || mStoppedAt != null || sample == null ||
            !sample.hasKey(:heartRate)) { return; }
        var value = sample[:heartRate];
        if (value == null || value < 1 || value > 255) { return; }
        mHeartRate = value;
        mHeartRateAt = mClock.nowMs();
        mAnalytics.onHeartRate(mHeartRateAt, value);
        mHrTotal += value;
        mHrCount += 1;
        if (mShiftLedger.snapshot(mHeartRateAt)[:onIce]) {
            mShiftHrTotal += value;
            mShiftHrCount += 1;
        }
        drainReadyShiftLaps(mHeartRateAt);
    }

    function onMotionFeature(feature) as Void {
        if (mStartedAt == null || mStoppedAt != null ||
            mRecorder.getState() != :recording || feature == null) { return; }
        var atMs = getElapsedMs();
        try {
            var batch = feature.hasKey(:pushBatch) ? feature[:pushBatch] : null;
            var pushResult = mPushDetector.push(batch, atMs);
            mDistanceEstimator.observe(pushResult);
        } catch (pushEx) {
            try {
                mDistanceEstimator.observe({:atMs=>atMs, :events=>[],
                    :validMs=>0, :observedIntervals=>[],
                    :sensorValid=>false, :gap=>true,
                    :profile=>:unconfirmed});
            } catch (estimateEx) { }
        }
        try {
            var proposal = mShiftInference.push(feature, getElapsedMs());
            if (proposal != null) {
                mShiftLedger.noteProposal(proposal);
                mRecorder.writeAutoBoundary(proposal[:atMs], proposal[:state]);
            }
            var snapshot = mShiftLedger.snapshot(mClock.nowMs());
            var manualState = snapshot[:onIce] ? :on_ice :
                (snapshot[:shiftCount] == 0 ? :no_shift : :bench);
            var status = proposal == null ?
                {:state=>mShiftInference.state(), :confidence=>0} : proposal;
            mSampleSeq += 1;
            var pushSnapshot = null;
            try { pushSnapshot = mDistanceEstimator.snapshot(getElapsedMs()); }
            catch (pushSnapshotEx) { }
            mRecorder.writeShadowSecond(feature, status, manualState,
                0, mSampleSeq, getElapsedMs(), pushSnapshot);
            drainReadyShiftLaps(mClock.nowMs());
        } catch (ex) { }
    }

    function getDashboard() as Lang.Dictionary {
        var current = mHeartRate;
        if (mHeartRateAt == null || mClock.nowMs() - mHeartRateAt > 5000) { current = null; }
        var average = mHrCount == 0 ? null : mHrTotal / mHrCount;
        var maximum = mProfile == null ? null : mProfile[:hrMax];
        var boundaries = mProfile == null || !mProfile.hasKey(:hrZones) ? null : mProfile[:hrZones];
        var zone = null;
        if (current != null && validBoundaries(boundaries)) {
            if (current < boundaries[0]) { zone = 0; }
            else {
                zone = 5;
                for (var i = 1; i <= 5; i += 1) {
                    if (current <= boundaries[i]) { zone = i; break; }
                }
            }
        } else if (current != null && maximum != null && maximum >= 80 && maximum <= 240) {
            var percent = current * 100 / maximum;
            if (percent >= 90) { zone = 5; }
            else if (percent >= 80) { zone = 4; }
            else if (percent >= 70) { zone = 3; }
            else if (percent >= 60) { zone = 2; }
            else if (percent >= 50) { zone = 1; }
            else { zone = 0; }
        }
        var shifts = mShiftLedger.snapshot(mStoppedAt == null ? mClock.nowMs() : mStoppedAt);
        var shiftAverage = shifts[:onIce] ?
            (mShiftHrCount == 0 ? null : mShiftHrTotal / mShiftHrCount) :
            mLastShiftHrAverage;
        var dashboard = {:heartRate=>current, :averageHeartRate=>average, :hrZone=>zone,
            :shiftAverageHeartRate=>shiftAverage,
            :elapsedMs=>getElapsedMs(), :state=>mRecorder.getState(),
            :sensorAvailable=>mHeartRateSource == null || mHeartRateSourceStarted,
            :shiftCount=>shifts[:shiftCount], :onIce=>shifts[:onIce],
            :lastShiftMs=>shifts[:lastShiftMs],
            :averageShiftMs=>shifts[:averageShiftMs],
            :timeOnIceMs=>shifts[:timeOnIceMs]};
        try {
            var push = mDistanceEstimator.snapshot(getElapsedMs());
            dashboard[:shiftPushes] = push[:shiftPushes];
            dashboard[:lastShiftPushes] = push[:lastShiftPushes];
            dashboard[:shiftDistanceCm] = push[:shiftDistanceCm];
            dashboard[:lastShiftDistanceCm] = push[:lastShiftDistanceCm];
            dashboard[:totalPushes] = push[:totalPushes];
            dashboard[:totalDistanceCm] = push[:totalDistanceCm];
            dashboard[:cadencePerMin] = push[:cadencePerMin];
            dashboard[:shortPushesTotal] = push[:shortPushesTotal];
            dashboard[:coveragePercent] = push[:coveragePercent];
            dashboard[:partial] = push[:partial];
            dashboard[:hasValidMotion] = push[:hasValidMotion];
            dashboard[:motionProfile] = push[:motionProfile];
            dashboard[:timebase] = push[:timebase];
            dashboard[:totalTimebase] = push[:totalTimebase];
        } catch (ex) { }
        return dashboard;
    }

    function toggleShift() as Lang.Boolean {
        if (mRecorder.getState() != :recording) { return false; }
        var now = mClock.nowMs();
        var event = mShiftLedger.manualToggle(now);
        if (event == null) { return false; }
        if (event[:state] == :on_ice) {
            mAnalytics.onShiftStarted(now);
            try { mDistanceEstimator.beginShift(now - mStartedAt); } catch (ex) { }
            mShiftHrTotal = 0;
            mShiftHrCount = 0;
        } else {
            mLastCompletedPushSummary = null;
            try { mLastCompletedPushSummary =
                mDistanceEstimator.endShift(now - mStartedAt); } catch (ex) { }
            mLastShiftHrAverage = mShiftHrCount == 0 ? null :
                mShiftHrTotal / mShiftHrCount;
            if (mLastShiftHrAverage != null) {
                mCompletedShiftHrAverageTotal += mLastShiftHrAverage;
                mCompletedShiftHrAverageCount += 1;
            }
            mAnalytics.onShiftEnded(now);
            mPendingPushSummaries[mShiftLedger.snapshot(now)[:shiftCount]] =
                mLastCompletedPushSummary;
        }
        drainReadyShiftLaps(now);
        return true;
    }

    private function validBoundaries(boundaries) as Lang.Boolean {
        if (boundaries == null || boundaries.size() < 6) { return false; }
        try {
            if (boundaries[0] < 25 || boundaries[5] > 240) { return false; }
            for (var i = 1; i <= 5; i += 1) {
                if (boundaries[i] <= boundaries[i - 1]) { return false; }
            }
            return true;
        } catch (ex) { return false; }
    }

    function getErrorCode() { return mRecorder.getErrorCode(); }
    function getState() as Lang.Symbol { return mRecorder.getState(); }
    function getSessionSummary() { return mSessionSummary; }
    function hasPendingSession() as Lang.Boolean { return mRecorder.hasPendingSession(); }
    function stopAndSave() as Lang.Boolean {
        if (mStartedAt == null || mRecorder.getState() != :recording) { return false; }
        var stopAt = mClock.nowMs();
        var shifts = mShiftLedger.snapshot(stopAt);
        if (shifts[:onIce] && !mOpenShiftFinalized) {
            var finalPush = null;
            try { finalPush = mDistanceEstimator.endShift(stopAt - mStartedAt); }
            catch (pushEndEx) { }
            mAnalytics.onShiftEnded(stopAt);
            mPendingPushSummaries[shifts[:shiftCount]] = finalPush;
            mOpenShiftFinalized = true;
        }
        if (mSessionSummary == null) {
            mSessionSummary = mAnalytics.finish(stopAt);
        }
        drainReadyShiftLaps(stopAt);
        mRecorder.writeActivitySummary(mSessionSummary);
        var saved = mRecorder.stopAndSave();
        if (mRecorder.getState() == :stopped || mRecorder.getState() == :saved) {
            mStoppedAt = stopAt;
            if (mShiftLedger.snapshot(mStoppedAt)[:onIce]) {
                mLastShiftHrAverage = mShiftHrCount == 0 ? null :
                    mShiftHrTotal / mShiftHrCount;
            }
            mShiftLedger.close(mStoppedAt);
            releaseHeartRateSource();
            releaseMotionSource();
        }
        return saved;
    }

    private function drainReadyShiftLaps(atMs) as Void {
        var ready = mAnalytics.drainReadyShiftLaps(atMs);
        for (var i = 0; i < ready.size(); i += 1) {
            var item = ready[i];
            var index = item[:index];
            var pushSummary = mPendingPushSummaries.hasKey(index) ?
                mPendingPushSummaries[index] : null;
            var lap = {:index=>index,
                :endedAtMs=>item[:endedAtMs] - mStartedAt,
                :durationMs=>item[:durationMs],
                :averageHeartRate=>item[:averageHeartRate],
                :heartRateDrop30=>item[:heartRateDrop30],
                :heartRateDrop60=>item[:heartRateDrop60]};
            try { mRecorder.writeShiftLap(lap, pushSummary); } catch (ex) { }
        }
    }

    private function averageShiftHeartRate(includeOpenShift as Lang.Boolean) {
        var total = mCompletedShiftHrAverageTotal;
        var count = mCompletedShiftHrAverageCount;
        if (includeOpenShift && mShiftHrCount > 0) {
            total += mShiftHrTotal / mShiftHrCount;
            count += 1;
        }
        return count == 0 ? null : total / count;
    }
    function retrySave() as Lang.Boolean { return mRecorder.retrySave(); }
    function discardSession() as Lang.Boolean {
        var discarded = mRecorder.discardSession();
        if (discarded) {
            mStoppedAt = mClock.nowMs();
            mShiftLedger.close(mStoppedAt);
            releaseHeartRateSource();
            releaseMotionSource();
        }
        return discarded;
    }

    private function releaseHeartRateSource() as Void {
        if (mHeartRateSourceStarted && mHeartRateSource != null) {
            try { mHeartRateSource.stop(); } catch (ex) { }
        }
        mHeartRateSourceStarted = false;
    }

    private function releaseMotionSource() as Void {
        if (mMotionSourceStarted && mMotionSource != null) {
            try { mMotionSource.stop(); } catch (ex) { }
        }
        mMotionSourceStarted = false;
    }
}
