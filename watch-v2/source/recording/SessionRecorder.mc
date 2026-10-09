using Toybox.Activity;
using Toybox.ActivityRecording;
using Toybox.Lang;

class SystemSessionFactory {
    function createSession(options) {
        return ActivityRecording.createSession(options);
    }
}

class SessionRecorder {
    private var mFactory;
    private var mSession = null;
    private var mState = :idle;
    private var mErrorCode = null;
    private var mShadowWriterFactory = null;
    private var mShadowWriter = null;

    function initialize(factory) { mFactory = factory; }

    function setShadowWriterFactory(factory) as Void {
        if (mState == :idle) { mShadowWriterFactory = factory; }
    }

    function start() as Lang.Boolean {
        return startWithOptions(null);
    }

    function startCalibration(calibrationOptions) as Lang.Boolean {
        return startWithOptions({:name=>"ShiftSense Hockey Calibration",
            :sport=>Activity.SPORT_HOCKEY, :calibration=>calibrationOptions});
    }

    private function startWithOptions(options) as Lang.Boolean {
        if (mState != :idle) { return false; }
        mState = :starting;
        try {
            var sessionName = options != null && options.hasKey(:name) ?
                options[:name] : "ShiftSense Hockey";
            var sport = options != null && options.hasKey(:sport) ?
                options[:sport] : Activity.SPORT_HOCKEY;
            mSession = mFactory.createSession({
                :name=>sessionName,
                :sport=>sport
            });
            if (mSession == null) { return fail("REC_CREATE"); }
            if (mShadowWriterFactory != null) {
                try {
                    mShadowWriter = mShadowWriterFactory.create(mSession);
                    if (!mShadowWriter.allocate()) { mShadowWriter = null; }
                } catch (shadowEx) { mShadowWriter = null; }
            }
            if (!mSession.start()) { return failCreatedSession("REC_START"); }
        } catch (ex) {
            return failCreatedSession("REC_EXCEPTION");
        }
        mState = :recording;
        return true;
    }

    function getState() as Lang.Symbol { return mState; }
    function getErrorCode() { return mErrorCode; }
    function hasPendingSession() as Lang.Boolean { return mSession != null; }

    function writeShadowSecond(feature, proposal, manualState, eventBits,
                               sampleSeq, sampleAtMs, pushSnapshot) as Lang.Boolean {
        if (mState != :recording || mShadowWriter == null) { return false; }
        try {
            if (mShadowWriter.writeSecond(feature, proposal, manualState,
                eventBits, sampleSeq, sampleAtMs, pushSnapshot)) {
                return true;
            }
        } catch (ex) { }
        mShadowWriter = null;
        return false;
    }

    function writeManualBoundary(elapsedMs, state, pushSummary) as Lang.Boolean {
        if (mState != :recording || mShadowWriter == null) { return false; }
        try {
            if (mShadowWriter.writeManualBoundary(elapsedMs, state,
                pushSummary)) { return true; }
        } catch (ex) { }
        mShadowWriter = null;
        return false;
    }

    function writeShiftLap(summary, pushSummary) as Lang.Boolean {
        if (mState != :recording || mShadowWriter == null || summary == null) {
            return false;
        }
        try {
            if (mShadowWriter.writeShiftLap(summary, pushSummary)) { return true; }
        } catch (ex) { }
        mShadowWriter = null;
        return false;
    }

    function writeAutoBoundary(elapsedMs, state) as Lang.Boolean {
        if (mState != :recording || mShadowWriter == null) { return false; }
        try {
            if (mShadowWriter.writeAutoBoundary(elapsedMs, state)) { return true; }
        } catch (ex) { }
        mShadowWriter = null;
        return false;
    }

    function writeActivitySummary(summary) as Lang.Boolean {
        if (mState != :recording || mShadowWriter == null) { return false; }
        try {
            if (mShadowWriter.writeActivitySummary(summary)) { return true; }
        } catch (ex) { }
        mShadowWriter = null;
        return false;
    }

    function stopAndSave() as Lang.Boolean {
        if (mState != :recording) { return false; }
        try {
            if (!mSession.stop()) { mErrorCode = "REC_STOP"; return false; }
        } catch (ex) {
            mErrorCode = "REC_STOP";
            return false;
        }
        mState = :stopped;
        return retrySave();
    }

    function retrySave() as Lang.Boolean {
        if (mState != :stopped) { return false; }
        try {
            if (!mSession.save()) { mErrorCode = "REC_SAVE"; return false; }
        } catch (ex) {
            mErrorCode = "REC_SAVE";
            return false;
        }
        mErrorCode = null;
        mState = :saved;
        mSession = null;
        mShadowWriter = null;
        return true;
    }

    function discardSession() as Lang.Boolean {
        if (mSession == null || (mState != :recording && mState != :stopped &&
            mState != :failed)) { return false; }
        try {
            if (!mSession.discard()) { mErrorCode = "REC_DISCARD"; return false; }
        } catch (ex) {
            mErrorCode = "REC_DISCARD";
            return false;
        }
        mSession = null;
        mShadowWriter = null;
        mErrorCode = null;
        mState = :discarded;
        return true;
    }

    private function failCreatedSession(code as Lang.String) as Lang.Boolean {
        if (mSession != null) {
            try {
                if (mSession.discard()) { mSession = null; }
            } catch (ex) { }
        }
        mShadowWriter = null;
        return fail(code);
    }

    private function fail(code as Lang.String) as Lang.Boolean {
        mErrorCode = code;
        mState = :failed;
        return false;
    }
}
