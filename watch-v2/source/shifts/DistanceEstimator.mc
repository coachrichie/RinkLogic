using Toybox.Lang;

class DistanceEstimator {
    private var mShiftStartedAt = null;
    private var mShiftPushes = 0;
    private var mShiftDistanceCm = 0;
    private var mShiftShortPushes = 0;
    private var mShiftValidMs = 0;
    private var mShiftHadGap = false;
    private var mLastCoverageEnd = null;
    private var mLastShiftPushes = null;
    private var mLastShiftDistanceCm = null;
    private var mLastShiftCoverage = null;
    private var mLastShiftHadValidMotion = false;
    private var mLastShiftPartial = false;
    private var mTotalPushes = 0;
    private var mTotalDistanceCm = 0;
    private var mShortPushesTotal = 0;
    private var mTotalIceMs = 0;
    private var mTotalValidMs = 0;
    private var mBurstPushes = 4;
    private var mCadenceEvents = [];
    private var mCadenceIntervals = [];
    private var mLastEventAt = null;
    private var mSignalAt = null;
    private var mSignalValid = false;
    private var mMotionProfile = null;
    private var mShiftTimebase = null;
    private var mLastShiftTimebase = null;
    private var mTotalTimebase = null;

    function initialize() { }

    function beginShift(atMs) as Void {
        if (mShiftStartedAt != null) { return; }
        mShiftStartedAt = atMs;
        mShiftPushes = 0;
        mShiftDistanceCm = 0;
        mShiftShortPushes = 0;
        mShiftValidMs = 0;
        mShiftHadGap = false;
        mLastCoverageEnd = atMs;
        mMotionProfile = :unconfirmed;
        mShiftTimebase = null;
        clearCadence();
    }

    function observe(result as Lang.Dictionary) as Void {
        if (mShiftStartedAt == null || result == null ||
            !result.hasKey(:atMs)) { return; }
        var now = result[:atMs];
        if (now == null || now < mShiftStartedAt) { return; }
        if (result[:gap] || !result[:sensorValid]) {
            mShiftHadGap = true;
            mMotionProfile = :unconfirmed;
            clearCadence();
        }
        if (!result[:sensorValid]) { return; }
        if (result.hasKey(:timebase)) {
            if (result[:timebase] == :estimated) {
                mShiftTimebase = :estimated;
                mTotalTimebase = :estimated;
            } else if (result[:timebase] == :measured) {
                if (mShiftTimebase == null) { mShiftTimebase = :measured; }
                if (mTotalTimebase == null) { mTotalTimebase = :measured; }
            }
        }
        mSignalAt = now;
        mSignalValid = true;
        var intervals = result.hasKey(:observedIntervals) ?
            result[:observedIntervals] : null;
        if (intervals != null) {
            for (var i = 0; i < intervals.size(); i += 1) {
                var start = intervals[i][:startMs];
                var finish = intervals[i][:endMs];
                if (start == null || finish == null || finish <= start) { continue; }
                if (start < mShiftStartedAt) { start = mShiftStartedAt; }
                if (start < mLastCoverageEnd) { start = mLastCoverageEnd; }
                if (finish > now) { finish = now; }
                if (finish <= start) { continue; }
                mShiftValidMs += finish - start;
                mLastCoverageEnd = finish;
                mCadenceIntervals.add({:startMs=>start, :endMs=>finish});
            }
        }
        var events = result[:events];
        if (events == null || events.size() == 0) {
            mMotionProfile = result.hasKey(:profile) &&
                result[:profile] == :unconfirmed ? :unconfirmed : :no_push;
        }
        if (events != null) {
            for (var e = 0; e < events.size(); e += 1) {
                var at = events[e][:atMs];
                if (at == null || at < mShiftStartedAt || at > now) { continue; }
                if (events[e][:startsBurst]) { mBurstPushes = 0; }
                var shortPush = mBurstPushes < 4;
                var centimetres = shortPush ? 125 : 225;
                mMotionProfile = shortPush ? :start : :rhythm;
                mBurstPushes += 1;
                mShiftPushes += 1;
                mTotalPushes += 1;
                mShiftDistanceCm += centimetres;
                mTotalDistanceCm += centimetres;
                if (shortPush) {
                    mShiftShortPushes += 1;
                    mShortPushesTotal += 1;
                }
                mCadenceEvents.add(at);
                mLastEventAt = at;
            }
        }
        pruneCadence(now);
    }

    function endShift(atMs) as Lang.Dictionary {
        if (mShiftStartedAt == null) { return {}; }
        var duration = atMs - mShiftStartedAt;
        if (duration < 0) { duration = 0; }
        mTotalIceMs += duration;
        mTotalValidMs += mShiftValidMs;
        mLastShiftPushes = mShiftPushes;
        mLastShiftDistanceCm = mShiftDistanceCm;
        mLastShiftCoverage = percentage(mShiftValidMs, duration);
        mLastShiftHadValidMotion = mShiftValidMs > 0;
        mLastShiftPartial = mShiftHadGap || mShiftValidMs < duration;
        mLastShiftTimebase = mShiftTimebase;
        var result = {:pushes=>mShiftPushes,
            :distanceCm=>mShiftDistanceCm,
            :shortPushes=>mShiftShortPushes,
            :coveragePercent=>mLastShiftCoverage,
            :partial=>mLastShiftPartial,
            :hasValidMotion=>mShiftValidMs > 0,
            :timebase=>mLastShiftTimebase};
        mShiftStartedAt = null;
        clearCadence();
        return result;
    }

    function snapshot(atMs) as Lang.Dictionary {
        var onIce = mShiftStartedAt != null;
        var duration = onIce ? atMs - mShiftStartedAt : 0;
        if (duration < 0) { duration = 0; }
        var coverage = onIce ? percentage(mShiftValidMs, duration) :
            mLastShiftCoverage;
        var partial = onIce ? (mShiftHadGap || mShiftValidMs < duration) :
            mLastShiftPartial;
        return {:shiftPushes=>onIce ? mShiftPushes : mLastShiftPushes,
            :lastShiftPushes=>mLastShiftPushes,
            :shiftDistanceCm=>onIce ? mShiftDistanceCm : mLastShiftDistanceCm,
            :lastShiftDistanceCm=>mLastShiftDistanceCm,
            :totalPushes=>mTotalPushes,
            :totalDistanceCm=>mTotalDistanceCm,
            :cadencePerMin=>cadence(atMs),
            :shortPushesTotal=>mShortPushesTotal,
            :coveragePercent=>coverage, :partial=>partial,
            :motionProfile=>mMotionProfile,
            :timebase=>onIce ? mShiftTimebase : mLastShiftTimebase,
            :totalTimebase=>mTotalTimebase,
            :hasValidMotion=>onIce ? mShiftValidMs > 0 :
                mLastShiftHadValidMotion};
    }

    function sessionSummary() as Lang.Dictionary {
        var ice = mTotalIceMs;
        var valid = mTotalValidMs;
        if (mShiftStartedAt != null && mSignalAt != null) {
            ice += mSignalAt - mShiftStartedAt;
            valid += mShiftValidMs;
        }
        return {:totalPushes=>mTotalPushes,
            :totalDistanceCm=>mTotalDistanceCm,
            :shortPushesTotal=>mShortPushesTotal,
            :coveragePercent=>percentage(valid, ice),
            :partial=>ice > 0 && valid < ice,
            :hasValidMotion=>valid > 0, :timebase=>mTotalTimebase};
    }

    private function percentage(valid, elapsed) {
        if (elapsed <= 0) { return null; }
        var ratio = (valid * 100.0 / elapsed).toNumber();
        if (ratio > 100) { return 100; }
        return ratio;
    }

    private function clearCadence() as Void {
        mCadenceEvents = [];
        mCadenceIntervals = [];
        mLastEventAt = null;
        mSignalAt = null;
        mSignalValid = false;
    }

    private function pruneCadence(now) as Void {
        var cutoff = now - 10000;
        var events = [];
        for (var i = 0; i < mCadenceEvents.size(); i += 1) {
            if (mCadenceEvents[i] >= cutoff) { events.add(mCadenceEvents[i]); }
        }
        mCadenceEvents = events;
        var intervals = [];
        for (var j = 0; j < mCadenceIntervals.size(); j += 1) {
            if (mCadenceIntervals[j][:endMs] > cutoff) {
                intervals.add(mCadenceIntervals[j]);
            }
        }
        mCadenceIntervals = intervals;
    }

    private function cadence(atMs) {
        if (mShiftStartedAt == null || !mSignalValid ||
            mSignalAt == null || atMs - mSignalAt > 1500) { return null; }
        pruneCadence(atMs);
        var cutoff = atMs - 10000;
        var valid = 0;
        for (var i = 0; i < mCadenceIntervals.size(); i += 1) {
            var start = mCadenceIntervals[i][:startMs];
            if (start < cutoff) { start = cutoff; }
            valid += mCadenceIntervals[i][:endMs] - start;
        }
        if (valid < 5000) { return null; }
        if (mLastEventAt == null || atMs - mLastEventAt >= 5000) { return 0; }
        if (mCadenceEvents.size() < 3) { return null; }
        return mCadenceEvents.size() * 6;
    }
}
