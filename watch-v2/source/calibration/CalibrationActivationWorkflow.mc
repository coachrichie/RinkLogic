using Toybox.Lang;

class CalibrationActivationWorkflow {
    private var mCoordinator;
    private var mStore;
    private var mActivated = false;
    function initialize(coordinator, store) {
        mCoordinator = coordinator;
        mStore = store;
    }
    function activate(candidate) as Lang.Symbol {
        if (mActivated) { return :activated; }
        try {
            if (!validCandidate(candidate)) {
                return :candidate_error;
            }
            var sport = candidate[:sport];
            var previous = mStore.snapshot(sport);
            if (!mCoordinator.setSessionCalibrationFactor(candidate[:factor])) {
                return :candidate_error;
            }
            var stored = false;
            try { stored = mStore.activate(candidate); }
            catch (storeEx) { stored = false; }
            if (!stored) {
                mStore.restore(sport, previous);
                return :storage_error;
            }
            var saved = false;
            try { saved = mCoordinator.stopAndSave(); }
            catch (saveEx) { saved = false; }
            if (!saved) {
                mStore.restore(sport, previous);
                return :save_error;
            }
            mActivated = true;
            return :activated;
        } catch (ex) { return :save_error; }
    }
    function discard() as Lang.Boolean {
        try { return mCoordinator != null && mCoordinator.discardSession(); }
        catch (ex) { return false; }
    }

    private function validCandidate(candidate) as Lang.Boolean {
        try {
            if (candidate == null || !(candidate instanceof Lang.Dictionary) ||
                !candidate.hasKey(:schemaVersion) || candidate[:schemaVersion] != 1 ||
                !candidate.hasKey(:sport) || !CalibrationTypes.validSport(candidate[:sport]) ||
                !candidate.hasKey(:source) || candidate[:source] != :local_known_distance ||
                !candidate.hasKey(:referenceDistanceCm) ||
                    !CalibrationTypes.validReferenceDistance(candidate[:referenceDistanceCm]) ||
                !candidate.hasKey(:validRepetitionCount) ||
                    candidate[:validRepetitionCount] != 10 ||
                !candidate.hasKey(:factor)) { return false; }
            var factor = candidate[:factor].toFloat();
            return factor == factor && factor >= 0.50 && factor <= 1.50;
        } catch (ex) { return false; }
    }
}
