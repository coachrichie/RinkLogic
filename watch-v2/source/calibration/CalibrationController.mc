using Toybox.Lang;

class CalibrationController {
    private var mSport = null;
    private var mCondition = null;
    private var mReferenceDistanceCm = null;
    private var mTargetRepetitions = 5;
    private var mCurrent = null;
    private var mValid = [];
    private var mInvalid = 0;
    private var mStatus = :setup;

    function initialize() { }

    function configure(sport, condition, referenceDistanceCm, targetRepetitions) as Lang.Boolean {
        if (!CalibrationTypes.validSport(sport) ||
            !CalibrationTypes.validCondition(condition) ||
            referenceDistanceCm == null || referenceDistanceCm <= 0 ||
            targetRepetitions == null || targetRepetitions <= 0) {
            return false;
        }
        mSport = sport;
        mCondition = condition;
        mReferenceDistanceCm = referenceDistanceCm;
        mTargetRepetitions = targetRepetitions;
        mCurrent = null;
        mValid = [];
        mInvalid = 0;
        mStatus = :setup;
        return true;
    }

    function startRepetition(atMs) as Lang.Boolean {
        if (mSport == null || mStatus == :incomplete || atMs == null) { return false; }
        if (mCurrent != null) {
            mCurrent = null;
            mInvalid += 1;
            mStatus = :running;
            return false;
        }
        mCurrent = {:startMs=>atMs};
        mStatus = :running;
        return true;
    }

    function endRepetition(atMs, metrics) as Lang.Boolean {
        if (mCurrent == null || atMs == null || metrics == null) {
            mInvalid += 1;
            return false;
        }
        var distance = metrics.hasKey(:distanceCm) ? metrics[:distanceCm] : null;
        var pushes = metrics.hasKey(:pushes) ? metrics[:pushes] : null;
        var coverage = metrics.hasKey(:coveragePercent) ? metrics[:coveragePercent] : null;
        if (atMs <= mCurrent[:startMs] || distance == null || pushes == null ||
            coverage == null || coverage <= 0 || coverage > 100) {
            mCurrent = null;
            mInvalid += 1;
            return false;
        }
        mValid.add({:startMs=>mCurrent[:startMs], :endMs=>atMs,
            :distanceCm=>distance, :pushes=>pushes, :coveragePercent=>coverage});
        mCurrent = null;
        if (mValid.size() >= mTargetRepetitions) { mStatus = :eligible; }
        return true;
    }

    function abort() as Void {
        mCurrent = null;
        mStatus = :incomplete;
    }

    function isEligible() as Lang.Boolean {
        return mStatus == :eligible && mValid.size() >= mTargetRepetitions;
    }

    function validCount() as Lang.Number { return mValid.size(); }
    function invalidCount() as Lang.Number { return mInvalid; }

    function summary() as Lang.Dictionary {
        return {:sport=>mSport, :condition=>mCondition,
            :referenceDistanceCm=>mReferenceDistanceCm,
            :targetRepetitions=>mTargetRepetitions,
            :validRepetitions=>mValid.size(), :invalidRepetitions=>mInvalid,
            :status=>mStatus, :eligible=>isEligible()};
    }
}
