using Toybox;
using Toybox.Activity;
using Toybox.ActivityRecording;
using Toybox.Lang;
using Toybox.System;

class FitSessionFactory {
    public function createSession(options) {
        if (!(Toybox has :ActivityRecording)) {
            return null;
        }
        return ActivityRecording.createSession(options);
    }
}

class SessionController {
    hidden var mStartFailureCode = "";
    public function getStartFailureCode() as Lang.String { return mStartFailureCode; }
    private function failStart(code) as Lang.Boolean {
        mStartFailureCode = code;
        System.println("ShiftSense start failed [" + code + "]");
        return false;
    }
    hidden var mFactory = null;
    hidden var mSession = null;
    hidden var mWriter = null;
    hidden var mState = :idle;
    hidden var mMode = null;
    hidden var mShiftIndex = 0;
    hidden var mSummaryMetrics = {};

    public function initialize(factory) {
        mFactory = factory;
    }

    public function getState() as Lang.Symbol {
        return mState;
    }

    public function start(mode as Lang.Symbol) as Lang.Boolean {
        if (mState != :idle || !isSupportedMode(mode)) {
            return failStart("STATE");
        }
        mStartFailureCode = "";
        var stage = "CREATE";
        try {
            if (mSession == null) {
                mSession = mFactory.createSession({:name=>"ShiftSense", :sport=>Activity.SPORT_GENERIC});
                if (mSession == null) {
                    return failStart(stage);
                }
            }
            if (mWriter == null) {
                mWriter = new FitWriter(mSession);
            }
            stage = "FIELD";
            if (!mWriter.allocateFields()) {
                failStart("FIELD:" + mWriter.getFailedFieldId());
                cleanupFailedSetup();
                return false;
            }
            mMode = mode;
            mShiftIndex = 0;
            mSummaryMetrics = {};
            stage = "INIT";
            if (!mWriter.writeRecord({
                :schemaVersion=>FitSchema.VERSION,
                :hockeyMode=>modeCode(mMode),
                :shiftState=>shiftStateCode(:bench)
            })) {
                failStart(stage);
                cleanupUnstartedSetup();
                return false;
            }
            stage = "START";
            if (!mSession.start()) {
                failStart(stage);
                cleanupFailedSetup();
                return false;
            }
        } catch (ex) {
            System.println("ShiftSense exception " + stage + ": " + ex.getErrorMessage());
            failStart(stage);
            cleanupUnstartedSetup();
            return false;
        }
        mState = :recording;
        System.println("ShiftSense recording started schema=" + FitSchema.VERSION);
        return true;
    }

    public function setSummaryMetrics(metrics as Lang.Dictionary) as Lang.Boolean {
        if (mState != :recording || metrics == null) {
            return false;
        }
        mSummaryMetrics = metrics;
        return true;
    }

    public function markShift(state as Lang.Symbol, timestampMs as Lang.Number) as Lang.Boolean {
        if (mState != :recording || !isShiftState(state) || timestampMs < 0) {
            return false;
        }
        var isShiftEntry = state == :shift;
        if (isShiftEntry) {
            mShiftIndex += 1;
        }
        var shift = {
            :shiftIndex=>mShiftIndex,
            :shiftState=>shiftStateCode(state),
            :shiftTimestampMs=>timestampMs,
            :schemaVersion=>FitSchema.VERSION,
            :hockeyMode=>modeCode(mMode)
        };
        // addLap is the irreversible marker boundary. Write it first so a
        // failed boundary can never leave a new record-state behind.
        if (!mWriter.writeShift(shift)) {
            if (isShiftEntry) {
                mShiftIndex -= 1;
            }
            return false;
        }
        // A successful lap is Garmin's irreversible marker commit. Record
        // data is a best-effort mirror and must not roll back an accepted lap.
        mWriter.writeRecord(shift);
        return true;
    }

    public function stop() as Lang.Boolean {
        if (mState != :recording) {
            return false;
        }
        var summary = {
            :schemaVersion=>FitSchema.VERSION,
            :hockeyMode=>modeCode(mMode),
            :shiftCount=>mShiftIndex
        };
        var metricKeys = mSummaryMetrics.keys();
        for (var metricIndex = 0; metricIndex < metricKeys.size(); metricIndex += 1) {
            var metricKey = metricKeys[metricIndex];
            summary[metricKey] = mSummaryMetrics[metricKey];
        }
        try {
            if (!mWriter.writeSummary(summary) || !mSession.stop()) {
                return false;
            }
        } catch (ex) {
            return false;
        }
        mState = :stopped;
        return true;
    }

    public function save() as Lang.Boolean {
        return close(:saved);
    }

    public function discard() as Lang.Boolean {
        return close(:discarded);
    }

    private function close(nextState as Lang.Symbol) as Lang.Boolean {
        if (mState != :stopped || mSession == null) {
            return false;
        }
        try {
            var completed = nextState == :saved ? mSession.save() : mSession.discard();
            if (!completed) {
                return false;
            }
        } catch (ex) {
            return false;
        }
        mState = nextState;
        mSession = null;
        mWriter = null;
        return true;
    }

    // A partial field allocation cannot safely be retried on the same FIT
    // session because Garmin field IDs are session-unique. If the documented
    // lifecycle calls succeed, discard the provisional session so a later user
    // retry obtains a fresh session. If any cleanup step fails, retain the
    // invalid writer/session and reject retries instead of duplicating IDs.
    private function cleanupFailedSetup() as Void {
        if (mSession == null || !(mSession has :start) ||
            !(mSession has :stop) || !(mSession has :discard)) {
            return;
        }
        try {
            if (mSession.start() && mSession.stop() && mSession.discard()) {
                mSession = null;
                mWriter = null;
            }
        } catch (ex) {
        }
    }

    private function cleanupUnstartedSetup() as Void {
        if (mSession == null || !(mSession has :discard)) {
            return;
        }
        try {
            if (mSession.discard()) {
                mSession = null;
                mWriter = null;
            }
        } catch (ex) {
        }
    }

    private function isSupportedMode(mode as Lang.Symbol) as Lang.Boolean {
        return mode == HockeyMode.ICE ||
            mode == HockeyMode.INLINE_INDOOR ||
            mode == HockeyMode.INLINE_OUTDOOR;
    }

    private function isShiftState(state as Lang.Symbol) as Lang.Boolean {
        return state == :bench || state == :transition || state == :shift ||
            state == :stoppage || state == :uncertain;
    }

    private function modeCode(mode as Lang.Symbol) as Lang.Number {
        if (mode == HockeyMode.ICE) { return 1; }
        if (mode == HockeyMode.INLINE_INDOOR) { return 2; }
        return 3;
    }

    private function shiftStateCode(state as Lang.Symbol) as Lang.Number {
        if (state == :bench) { return 1; }
        if (state == :transition) { return 2; }
        if (state == :shift) { return 3; }
        if (state == :stoppage) { return 4; }
        return 5;
    }
}
