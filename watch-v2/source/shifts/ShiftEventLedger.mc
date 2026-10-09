using Toybox.Lang;

class ShiftEventLedger {
    private var mShiftStartedAt = null;
    private var mShiftCount = 0;
    private var mCompletedShiftCount = 0;
    private var mLastShiftMs = null;
    private var mIceTimeMs = 0;
    private var mLastAtMs = -1;
    private var mClosed = false;
    private var mLatestProposal = null;

    function manualToggle(atMs as Lang.Number) as Lang.Dictionary or Null {
        if (mClosed || atMs < mLastAtMs) { return null; }
        mLastAtMs = atMs;
        if (mShiftStartedAt == null) {
            mShiftStartedAt = atMs;
            mShiftCount += 1;
            return {:atMs=>atMs, :state=>:on_ice,
                :source=>:manual, :confidence=>100};
        }
        mLastShiftMs = atMs - mShiftStartedAt;
        mIceTimeMs += mLastShiftMs;
        mCompletedShiftCount += 1;
        mShiftStartedAt = null;
        return {:atMs=>atMs, :state=>:bench,
            :source=>:manual, :confidence=>100};
    }

    function noteProposal(event) as Void { mLatestProposal = event; }

    function snapshot(atMs as Lang.Number) as Lang.Dictionary {
        var currentMs = mShiftStartedAt == null ? 0 :
            (atMs < mShiftStartedAt ? 0 : atMs - mShiftStartedAt);
        return {:shiftCount=>mShiftCount, :onIce=>mShiftStartedAt != null,
            :lastShiftMs=>mLastShiftMs,
            :averageShiftMs=>mCompletedShiftCount == 0 ? null :
                mIceTimeMs / mCompletedShiftCount,
            :timeOnIceMs=>mIceTimeMs + currentMs};
    }

    function close(atMs as Lang.Number) as Void {
        if (mClosed) { return; }
        if (mShiftStartedAt != null) { manualToggle(atMs); }
        mClosed = true;
    }
}
