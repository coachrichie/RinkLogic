using Toybox.Lang;

class ShiftInference {
    private var mActive;
    private var mQuiet;
    private var mTimes;
    private var mLastAtMs = null;
    private var mMissing = 0;
    private var mUncertain = false;
    private var mSettledState = :no_shift;

    function initialize() {
        mActive = [];
        mQuiet = [];
        mTimes = [];
    }

    function state() as Lang.Symbol {
        return mUncertain ? :uncertain : mSettledState;
    }

    function push(feature as Lang.Dictionary, atMs as Lang.Number) as Lang.Dictionary or Null {
        if (mLastAtMs != null && (atMs <= mLastAtMs || atMs - mLastAtMs > 2000)) {
            clearEvidence();
            mUncertain = true;
        }
        mLastAtMs = atMs;
        if (feature[:valid] != true || feature[:motionMg] == null) {
            mMissing += 1;
            if (mMissing >= 3) {
                clearEvidence();
                mUncertain = true;
            }
            return null;
        }
        if (mMissing > 0) { clearEvidence(); }
        mMissing = 0;

        var motion = feature[:motionMg] as Lang.Number;
        var rotation = feature[:rotationDps];
        mActive.add(motion >= 180 && feature[:periodic] == true);
        mQuiet.add(motion < 70 && (rotation == null || rotation < 25));
        mTimes.add(atMs);
        if (mActive.size() > 20) {
            mActive = mActive.slice(1, null);
            mQuiet = mQuiet.slice(1, null);
            mTimes = mTimes.slice(1, null);
        }
        if (mActive.size() >= 10) { mUncertain = false; }

        var nextState = null;
        var boundaryAt = atMs;
        if (mActive.size() >= 10 && countRecent(mActive, 10) >= 8) {
            nextState = :on_ice;
            boundaryAt = firstRecentTrueAt(mActive, 10);
        } else if (mQuiet.size() >= 20 && countRecent(mQuiet, 20) >= 15) {
            nextState = :bench;
            boundaryAt = firstRecentTrueAt(mQuiet, 20);
        }
        if (nextState == null || nextState == mSettledState) { return null; }
        mSettledState = nextState;
        return {:atMs=>boundaryAt, :confirmedAtMs=>atMs,
            :state=>nextState, :source=>:auto,
            :confidence=>80, :reason=>nextState == :on_ice ?
                :sustained_motion : :sustained_quiet};
    }

    private function clearEvidence() as Void {
        mActive = [];
        mQuiet = [];
        mTimes = [];
    }

    private function countRecent(values as Lang.Array, recent as Lang.Number) as Lang.Number {
        var count = 0;
        for (var i = values.size() - recent; i < values.size(); i += 1) {
            if (values[i]) { count += 1; }
        }
        return count;
    }

    private function firstRecentTrueAt(values as Lang.Array, recent as Lang.Number) as Lang.Number {
        for (var i = values.size() - recent; i < values.size(); i += 1) {
            if (values[i]) { return mTimes[i]; }
        }
        return mTimes[mTimes.size() - 1];
    }
}
