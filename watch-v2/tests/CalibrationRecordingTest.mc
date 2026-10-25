using Toybox.Lang;
using Toybox.Test as Test;

(:test)
function calibrationManifestRowUsesExplicitUnitsAndStatus(logger as Test.Logger) as Lang.Boolean {
    var row = CalibrationManifest.row("session-1", 2, :inline,
        :puck_stickhandling, 2000, 9, :valid);
    return row[:sessionId].equals("session-1") && row[:repetition] == 2 &&
        row[:sport].equals("inline") && row[:condition].equals("puck_stickhandling") &&
        row[:referenceDistanceCm] == 2000 && row[:referencePushes] == 9 &&
        row[:markerStatus].equals("valid");
}

class CalibrationActivationCoordinatorFake {
    var setResult = true;
    var saveResult = true;
    var discardResult = true;
    var setCalls = 0;
    var saveCalls = 0;
    var discardCalls = 0;
    function setSessionCalibrationFactor(factor) as Lang.Boolean {
        setCalls += 1; return setResult;
    }
    function stopAndSave() as Lang.Boolean { saveCalls += 1; return saveResult; }
    function discardSession() as Lang.Boolean { discardCalls += 1; return discardResult; }
}

class CalibrationActivationStoreFake {
    var result = true;
    var calls = 0;
    function activate(candidate) as Lang.Boolean { calls += 1; return result; }
}

(:test)
function calibrationActivationNeverStoresWhenSaveFails(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new CalibrationActivationCoordinatorFake();
    coordinator.saveResult = false;
    var store = new CalibrationActivationStoreFake();
    var workflow = new CalibrationActivationWorkflow(coordinator, store);
    return workflow.activate(calibrationProfileCandidate(:ice, 1.0)) == :save_error &&
        coordinator.setCalls == 1 && coordinator.saveCalls == 1 && store.calls == 0;
}

(:test)
function calibrationActivationReportsSuccessOnlyAfterStorage(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new CalibrationActivationCoordinatorFake();
    var store = new CalibrationActivationStoreFake();
    var workflow = new CalibrationActivationWorkflow(coordinator, store);
    if (workflow.activate(calibrationProfileCandidate(:ice, 1.0)) != :activated ||
        store.calls != 1) { return false; }
    store.result = false;
    return workflow.activate(calibrationProfileCandidate(:ice, 1.0)) == :storage_error;
}

(:test)
function calibrationDiscardNeverChangesStoredProfile(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new CalibrationActivationCoordinatorFake();
    var store = new CalibrationActivationStoreFake();
    var workflow = new CalibrationActivationWorkflow(coordinator, store);
    return workflow.discard() && coordinator.discardCalls == 1 && store.calls == 0;
}
