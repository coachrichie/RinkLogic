using Toybox.Lang;

class PhaseLapTracker {
    private var mPhase = null;
    private var mStartedAtMs = null;
    private var mLastTransitionAtMs = null;
    private var mFinished = false;

    function initialize() {
        mPhase = null;
        mStartedAtMs = null;
        mLastTransitionAtMs = null;
        mFinished = false;
    }

    function startShift(atMs as Lang.Number) as Lang.Dictionary or Null {
        if (mFinished || (mLastTransitionAtMs != null &&
                atMs <= mLastTransitionAtMs)) { return null; }
        if (mPhase == :on_ice) { return null; }

        var interval = null;
        if (mPhase == :bench) {
            interval = closeOpenPhase(atMs);
        }
        mPhase = :on_ice;
        mStartedAtMs = atMs;
        mLastTransitionAtMs = atMs;
        return interval;
    }

    function endShift(atMs as Lang.Number) as Lang.Dictionary or Null {
        if (mFinished || mPhase != :on_ice ||
                atMs <= mStartedAtMs ||
                (mLastTransitionAtMs != null && atMs <= mLastTransitionAtMs)) {
            return null;
        }

        var interval = closeOpenPhase(atMs);
        mPhase = :bench;
        mStartedAtMs = atMs;
        mLastTransitionAtMs = atMs;
        return interval;
    }

    function finish(atMs as Lang.Number) as Lang.Dictionary or Null {
        if (mFinished) { return null; }
        if (mPhase == null || atMs <= mStartedAtMs ||
                (mLastTransitionAtMs != null && atMs <= mLastTransitionAtMs)) {
            return null;
        }
        var interval = closeOpenPhase(atMs);
        mFinished = true;
        mPhase = null;
        mStartedAtMs = null;
        mLastTransitionAtMs = atMs;
        return interval;
    }

    private function closeOpenPhase(atMs as Lang.Number) as Lang.Dictionary {
        return {:phase=>mPhase, :startedAtMs=>mStartedAtMs,
            :endedAtMs=>atMs, :durationMs=>atMs - mStartedAtMs};
    }
}
