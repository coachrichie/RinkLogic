using Toybox.Lang;
using Toybox.Math;

class CalibrationController {
    private var mSport = null;
    private var mReferenceDistanceCm = null;
    private var mCurrent = null;
    private var mAccepted = [];
    private var mInvalid = 0;
    private var mLastMarkerMs = null;
    private var mStatus = :unconfigured;
    private var mCandidate = null;

    function initialize() { }

    function configure(sport, referenceDistanceCm) as Lang.Boolean {
        if (!CalibrationTypes.validSport(sport) ||
            !CalibrationTypes.validReferenceDistance(referenceDistanceCm)) {
            return false;
        }
        mSport = sport;
        mReferenceDistanceCm = referenceDistanceCm;
        mCurrent = null;
        mAccepted = [];
        mInvalid = 0;
        mLastMarkerMs = null;
        mStatus = :setup;
        mCandidate = null;
        return true;
    }

    // Temporary bridge for the prototype setup screen; Task 6 removes it.
    function configureLegacy(sport, condition, referenceDistanceCm,
                             targetRepetitions) as Lang.Boolean {
        if (!CalibrationTypes.validCondition(condition) || targetRepetitions != 5) {
            return false;
        }
        return configure(sport, referenceDistanceCm);
    }

    function currentCondition() { return CalibrationTypes.conditionForIndex(mAccepted.size()); }
    function currentPace() { return CalibrationTypes.paceForIndex(mAccepted.size()); }

    function startRepetition(atMs) as Lang.Boolean {
        if (mSport == null || mStatus == :incomplete || mStatus == :eligible ||
            mStatus == :inconsistent || mAccepted.size() >= 10) { return false; }
        if (!validMarker(atMs)) {
            mInvalid += 1;
            return false;
        }
        if (mCurrent != null) {
            mCurrent = null;
            mInvalid += 1;
            mLastMarkerMs = atMs;
            mStatus = :running;
            return false;
        }
        mCurrent = {:startMs=>atMs, :condition=>currentCondition(),
            :pace=>currentPace()};
        mLastMarkerMs = atMs;
        mStatus = :running;
        return true;
    }

    function endRepetition(atMs, metrics) as Lang.Boolean {
        if (mCurrent == null) {
            mInvalid += 1;
            return false;
        }
        var started = mCurrent;
        mCurrent = null;
        if (!validMarker(atMs)) {
            mInvalid += 1;
            return false;
        }
        mLastMarkerMs = atMs;
        try {
            var durationMs = atMs - started[:startMs];
            var distance = dictionaryValue(metrics, :distanceCm);
            var pushes = dictionaryValue(metrics, :pushes);
            var coverage = dictionaryValue(metrics, :coveragePercent);
            var timebase = dictionaryValue(metrics, :timebase);
            if (durationMs < 2000 || durationMs > 30000 ||
                distance == null || distance != distance || distance <= 0 ||
                pushes == null || pushes != pushes || pushes <= 0 ||
                coverage == null || coverage != coverage || coverage < 80 || coverage > 100 ||
                !CalibrationTypes.validTimebase(timebase)) {
                return rejectRun();
            }
            var ratio = mReferenceDistanceCm.toFloat() / distance.toFloat();
            if (ratio != ratio || ratio < 0.50 || ratio > 1.50) {
                return rejectRun();
            }
            var durationMinutes = durationMs.toFloat() / 60000.0;
            mAccepted.add({
                :condition=>started[:condition], :pace=>started[:pace],
                :durationMinutes=>durationMinutes,
                :cadencePerMinute=>pushes.toFloat() / durationMinutes,
                :effectiveStepLengthCm=>mReferenceDistanceCm.toFloat() / pushes.toFloat(),
                :baselineDistanceCm=>distance.toFloat(), :baselineRatio=>ratio,
                :pushes=>pushes, :coveragePercent=>coverage, :timebase=>timebase
            });
            if (mAccepted.size() == 10) { evaluateCandidate(); }
            return true;
        } catch (ex) {
            return rejectRun();
        }
    }

    function abort() as Void {
        mCurrent = null;
        mCandidate = null;
        mStatus = :incomplete;
    }

    function isEligible() as Lang.Boolean {
        return mStatus == :eligible && mCandidate != null && mAccepted.size() == 10;
    }

    function validCount() as Lang.Number { return mAccepted.size(); }
    function invalidCount() as Lang.Number { return mInvalid; }

    function candidateProfile() {
        if (!isEligible()) { return null; }
        return copyCandidate(mCandidate);
    }

    function summary() as Lang.Dictionary {
        return {:sport=>mSport, :condition=>currentCondition(),
            :pace=>currentPace(), :referenceDistanceCm=>mReferenceDistanceCm,
            :targetRepetitions=>10, :validRepetitions=>mAccepted.size(),
            :invalidRepetitions=>mInvalid, :status=>mStatus,
            :eligible=>isEligible(), :acceptedRuns=>copyRuns()};
    }

    private function validMarker(atMs) as Lang.Boolean {
        try {
            return atMs != null && atMs >= 0 &&
                (mLastMarkerMs == null || atMs > mLastMarkerMs);
        } catch (ex) { return false; }
    }

    private function dictionaryValue(dictionary, key) {
        if (dictionary == null || !(dictionary instanceof Lang.Dictionary) ||
            !dictionary.hasKey(key)) { return null; }
        return dictionary[key];
    }

    private function rejectRun() as Lang.Boolean {
        mInvalid += 1;
        mStatus = :running;
        return false;
    }

    private function evaluateCandidate() as Void {
        var skate = [];
        var puck = [];
        var all = [];
        for (var i = 0; i < mAccepted.size(); i += 1) {
            var ratio = mAccepted[i][:baselineRatio];
            all.add(ratio);
            if (mAccepted[i][:condition] == :skate_only) { skate.add(ratio); }
            else { puck.add(ratio); }
        }
        var skateMedian = median(skate);
        var puckMedian = median(puck);
        var midpoint = (skateMedian + puckMedian) / 2.0;
        var disagreement = midpoint <= 0 ? 999.0 :
            (skateMedian - puckMedian).toFloat().abs() / midpoint;
        var factor = roundFour(median(all));
        if (relativeMad(skate) > 0.15 || relativeMad(puck) > 0.15 ||
            disagreement > 0.15 || factor < 0.50 || factor > 1.50) {
            mCandidate = null;
            mStatus = :inconsistent;
            return;
        }
        mCandidate = {:schemaVersion=>1, :sport=>mSport, :factor=>factor,
            :source=>:local_known_distance,
            :referenceDistanceCm=>mReferenceDistanceCm,
            :conditionMedians=>{:skate_only=>roundFour(skateMedian),
                :puck_stickhandling=>roundFour(puckMedian)},
            :validRepetitionCount=>10};
        mStatus = :eligible;
    }

    private function median(values) as Lang.Float {
        var sorted = [];
        for (var i = 0; i < values.size(); i += 1) {
            var value = values[i].toFloat();
            var insertAt = sorted.size();
            while (insertAt > 0 && sorted[insertAt - 1] > value) { insertAt -= 1; }
            sorted.add(value);
            for (var j = sorted.size() - 1; j > insertAt; j -= 1) {
                sorted[j] = sorted[j - 1];
            }
            sorted[insertAt] = value;
        }
        var middle = sorted.size() / 2;
        if ((sorted.size() % 2) == 1) { return sorted[middle].toFloat(); }
        return ((sorted[middle - 1] + sorted[middle]) / 2.0).toFloat();
    }

    private function relativeMad(values) as Lang.Float {
        var center = median(values);
        if (center <= 0) { return 999.0; }
        var deviations = [];
        for (var i = 0; i < values.size(); i += 1) {
            deviations.add((values[i].toFloat() - center).abs());
        }
        return (median(deviations) / center).toFloat();
    }

    private function roundFour(value) as Lang.Float {
        return (Math.floor(value.toFloat() * 10000.0 + 0.5).toFloat() / 10000.0).toFloat();
    }

    private function copyCandidate(candidate) as Lang.Dictionary {
        return {:schemaVersion=>candidate[:schemaVersion], :sport=>candidate[:sport],
            :factor=>candidate[:factor], :source=>candidate[:source],
            :referenceDistanceCm=>candidate[:referenceDistanceCm],
            :conditionMedians=>{
                :skate_only=>candidate[:conditionMedians][:skate_only],
                :puck_stickhandling=>candidate[:conditionMedians][:puck_stickhandling]
            }, :validRepetitionCount=>candidate[:validRepetitionCount]};
    }

    private function copyRuns() as Lang.Array {
        var copies = [];
        for (var i = 0; i < mAccepted.size(); i += 1) {
            var run = mAccepted[i];
            copies.add({:condition=>run[:condition], :pace=>run[:pace],
                :durationMinutes=>run[:durationMinutes],
                :cadencePerMinute=>run[:cadencePerMinute],
                :effectiveStepLengthCm=>run[:effectiveStepLengthCm],
                :baselineDistanceCm=>run[:baselineDistanceCm],
                :baselineRatio=>run[:baselineRatio], :pushes=>run[:pushes],
                :coveragePercent=>run[:coveragePercent], :timebase=>run[:timebase]});
        }
        return copies;
    }
}
