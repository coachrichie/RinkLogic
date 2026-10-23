using Toybox.Lang;

class CalibrationActivationWorkflow {
    private var mCoordinator;
    private var mStore;
    function initialize(coordinator, store) {
        mCoordinator = coordinator;
        mStore = store;
    }
    function activate(candidate) as Lang.Symbol {
        try {
            if (candidate == null || !(candidate instanceof Lang.Dictionary) ||
                !candidate.hasKey(:factor) ||
                !mCoordinator.setSessionCalibrationFactor(candidate[:factor])) {
                return :candidate_error;
            }
            if (!mCoordinator.stopAndSave()) { return :save_error; }
            if (!mStore.activate(candidate)) { return :storage_error; }
            return :activated;
        } catch (ex) { return :save_error; }
    }
    function discard() as Lang.Boolean {
        try { return mCoordinator != null && mCoordinator.discardSession(); }
        catch (ex) { return false; }
    }
}
