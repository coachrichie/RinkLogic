using Toybox.Lang;
using Toybox.Math;

class PushDetector {
    private var mLastRawTime = null;
    private var mLastSampleAt = null;
    private var mLastActiveAt = null;
    private var mLastCandidateAt = null;
    private var mLastAcceptedAt = null;
    private var mPendingAt = null;
    private var mPendingSecondAt = null;
    private var mPendingStartsBurst = false;
    private var mNextStartsBurst = true;
    private var mAboveThreshold = false;

    function initialize() { reset(); }

    function reset() as Void {
        mLastRawTime = null;
        mLastSampleAt = null;
        mLastActiveAt = null;
        clearRhythm();
    }

    private function clearRhythm() as Void {
        mLastCandidateAt = null;
        mLastAcceptedAt = null;
        mPendingAt = null;
        mPendingSecondAt = null;
        mPendingStartsBurst = false;
        mNextStartsBurst = true;
        mAboveThreshold = false;
    }

    private function invalid(gap, atMs) as Lang.Dictionary {
        clearRhythm();
        return {:events=>[], :validMs=>0, :sensorValid=>false,
            :gap=>gap, :atMs=>atMs, :observedIntervals=>[],
            :profile=>:unconfirmed, :timebase=>:unavailable};
    }

    function push(batch as Lang.Dictionary or Null,
                  callbackElapsedMs as Lang.Number) as Lang.Dictionary {
        if (batch == null || callbackElapsedMs == null || callbackElapsedMs < 0) {
            return invalid(true, callbackElapsedMs);
        }
        try {
            var ax = batch[:ax];
            var ay = batch[:ay];
            var az = batch[:az];
            var gx = batch[:gx];
            var gy = batch[:gy];
            var gz = batch[:gz];
            var at = batch[:accelTimes];
            var gt = batch[:gyroTimes];
            var estimated = batch.hasKey(:timebase) &&
                batch[:timebase] == :estimated;
            if (ax == null || ay == null || az == null || gx == null ||
                gy == null || gz == null || at == null || gt == null ||
                at.size() < 2 || gt.size() < 1 || ax.size() != at.size() ||
                ay.size() != at.size() || az.size() != at.size() ||
                gx.size() != gt.size() || gy.size() != gt.size() ||
                gz.size() != gt.size()) { return invalid(true, callbackElapsedMs); }
            if (!increasing(at) || !increasing(gt) ||
                (!estimated && mLastRawTime != null &&
                    at[0] <= mLastRawTime)) {
                return invalid(true, callbackElapsedMs);
            }
            var events = [];
            var observed = 0;
            var observedIntervals = [];
            var gap = false;
            var rawEnd = at[at.size() - 1];
            var firstAt = callbackElapsedMs - (rawEnd - at[0]);
            if (firstAt < 0) { return invalid(true, callbackElapsedMs); }
            if (estimated && mLastSampleAt != null &&
                firstAt <= mLastSampleAt) {
                return invalid(true, callbackElapsedMs);
            }
            if (mLastSampleAt != null &&
                (firstAt - mLastSampleAt > 2000 ||
                 (estimated && callbackElapsedMs - mLastSampleAt > 2000))) {
                gap = true;
                clearRhythm();
            }
            var previousPaired = false;
            for (var i = 0; i < at.size(); i += 1) {
                var sampleAt = callbackElapsedMs - (rawEnd - at[i]);
                var interval = 0;
                if (i > 0) {
                    interval = at[i] - at[i - 1];
                    if (interval > 2000) { gap = true; clearRhythm(); }
                }
                if (ax[i] == null || ay[i] == null || az[i] == null ||
                    ax[i] < -16000 || ax[i] > 16000 ||
                    ay[i] < -16000 || ay[i] > 16000 ||
                    az[i] < -16000 || az[i] > 16000) {
                    return invalid(true, callbackElapsedMs);
                }
                var gyroIndex = nearestGyro(at[i], gt);
                if (gyroIndex < 0 || gx[gyroIndex] == null ||
                    gy[gyroIndex] == null || gz[gyroIndex] == null) {
                    gap = true;
                    clearRhythm();
                    previousPaired = false;
                    continue;
                }
                if (i > 0 && previousPaired && interval <= 250) {
                    var intervalStart = callbackElapsedMs - (rawEnd - at[i - 1]);
                    var windowStart = callbackElapsedMs - 1000;
                    if (intervalStart < windowStart) { intervalStart = windowStart; }
                    if (sampleAt > intervalStart) {
                        observed += sampleAt - intervalStart;
                        observedIntervals.add({:startMs=>intervalStart,
                            :endMs=>sampleAt});
                    }
                }
                previousPaired = true;
                var magnitude = Math.sqrt(ax[i]*ax[i] + ay[i]*ay[i] + az[i]*az[i]);
                var dynamic = magnitude - 1000.0;
                if (dynamic < 0) { dynamic = -dynamic; }
                var high = dynamic >= 150;
                if (mLastActiveAt != null && sampleAt - mLastActiveAt > 2000) {
                    clearRhythm();
                }
                var rotation = Math.sqrt(gx[gyroIndex]*gx[gyroIndex] +
                    gy[gyroIndex]*gy[gyroIndex] + gz[gyroIndex]*gz[gyroIndex]);
                if (high || rotation >= 40) { mLastActiveAt = sampleAt; }
                if (high && !mAboveThreshold && rotation >= 40 &&
                    (mLastCandidateAt == null || sampleAt - mLastCandidateAt >= 350)) {
                    acceptCandidate(sampleAt, events);
                }
                mAboveThreshold = high;
            }
            if (observed == 0) { return invalid(true, callbackElapsedMs); }
            mLastRawTime = estimated ? null : rawEnd;
            mLastSampleAt = callbackElapsedMs;
            return {:events=>events, :validMs=>observed,
                :sensorValid=>true, :gap=>gap, :atMs=>callbackElapsedMs,
                :observedIntervals=>observedIntervals,
                :profile=>profile(events),
                :timebase=>estimated ? :estimated : :measured};
        } catch (ex) { return invalid(true, callbackElapsedMs); }
    }

    private function profile(events) as Lang.Symbol {
        if (events.size() > 0) {
            return events[0][:startsBurst] ? :start : :rhythm;
        }
        return mPendingAt != null ? :unconfirmed : :no_push;
    }

    private function increasing(values) as Lang.Boolean {
        for (var i = 0; i < values.size(); i += 1) {
            if (values[i] == null ||
                (i > 0 && values[i] <= values[i - 1])) { return false; }
        }
        return true;
    }

    private function nearestGyro(time, gyroTimes) as Lang.Number {
        var nearest = -1;
        var error = 101;
        for (var i = 0; i < gyroTimes.size(); i += 1) {
            var delta = time - gyroTimes[i];
            if (delta < 0) { delta = -delta; }
            if (delta < error) { nearest = i; error = delta; }
        }
        return error <= 100 ? nearest : -1;
    }

    private function acceptCandidate(atMs, events) as Void {
        mLastCandidateAt = atMs;
        if (mPendingAt != null) {
            var previous = mPendingSecondAt == null ? mPendingAt : mPendingSecondAt;
            var interval = atMs - previous;
            if (interval >= 350 && interval <= 1300 &&
                mPendingSecondAt == null) {
                mPendingSecondAt = atMs;
                return;
            }
            if (interval >= 350 && interval <= 1300) {
                events.add({:atMs=>mPendingAt,
                    :startsBurst=>mPendingStartsBurst});
                events.add({:atMs=>mPendingSecondAt, :startsBurst=>false});
                events.add({:atMs=>atMs, :startsBurst=>false});
                mLastAcceptedAt = atMs;
                mPendingAt = null;
                mPendingSecondAt = null;
                mNextStartsBurst = false;
                return;
            }
        }
        if (mLastAcceptedAt != null) {
            var sinceAccepted = atMs - mLastAcceptedAt;
            if (sinceAccepted >= 350 && sinceAccepted <= 1300) {
                events.add({:atMs=>atMs, :startsBurst=>false});
                mLastAcceptedAt = atMs;
                return;
            }
        }
        mPendingAt = atMs;
        mPendingSecondAt = null;
        mPendingStartsBurst = mNextStartsBurst;
    }
}
