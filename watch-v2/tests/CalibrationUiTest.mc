using Toybox.Lang;
using Toybox.Test as Test;

class CalibrationTargetFake {
    var starts = 0;
    var cancels = 0;
    var saves = 0;
    var last = null;
    function startCalibration(sport, condition, distanceCm, repetitions) as Void {
        starts += 1;
        last = {:sport=>sport, :condition=>condition,
            :distanceCm=>distanceCm, :repetitions=>repetitions};
    }
    function cancelCalibration() as Void { cancels += 1; }
    function saveCalibration() as Void { saves += 1; }
}

class CalibrationCoordinatorFake {
    var toggles = 0;
    var lastShiftPushes = 8;
    var lastShiftDistanceCm = 2500;
    var coveragePercent = 90;
    function toggleShift() as Lang.Boolean { toggles += 1; return true; }
    function getDashboard() as Lang.Dictionary {
        return {:onIce=>false, :lastShiftPushes=>lastShiftPushes,
            :lastShiftDistanceCm=>lastShiftDistanceCm,
            :coveragePercent=>coveragePercent};
    }
}

(:test)
function setupDefaultsUseInlineTwentyFiveMetresAndFiveRepetitions(logger as Test.Logger) as Lang.Boolean {
    var view = new CalibrationSetupView(new CalibrationTargetFake());
    var config = view.configuration();
    return config[:sport] == :inline && config[:condition] == :skate_only &&
        config[:referenceDistanceCm] == 2500 && config[:targetRepetitions] == 5;
}

(:test)
function setupCyclesToIceAndStickhandling(logger as Test.Logger) as Lang.Boolean {
    var target = new CalibrationTargetFake();
    var view = new CalibrationSetupView(target);
    view.cycleSelection(1);
    view.cycleSelection(1);
    view.requestStart();
    return target.starts == 1 && target.last[:sport] == :ice &&
        target.last[:condition] == :puck_stickhandling;
}

(:test)
function runViewUsesLowerMarkerForStartAndEndStates(logger as Test.Logger) as Lang.Boolean {
    var target = new CalibrationTargetFake();
    var controller = new CalibrationController();
    controller.configure(:inline, :skate_only, 2500, 5);
    var view = new CalibrationRunView(target, controller);
    if (view.getState() != :ready) { return false; }
    if (!view.toggleMarker(1000) || view.getState() != :run) { return false; }
    if (!view.toggleMarker(4000) || view.getState() != :end) { return false; }
    view.requestCancel();
    return target.cancels == 1;
}

(:test)
function runViewForwardsMarkersToLiveCoordinator(logger as Test.Logger) as Lang.Boolean {
    var target = new CalibrationTargetFake();
    var controller = new CalibrationController();
    controller.configure(:inline, :skate_only, 2500, 5);
    var coordinator = new CalibrationCoordinatorFake();
    var view = new CalibrationRunView(target, controller);
    view.setCoordinator(coordinator);
    if (!view.toggleMarker(1000) || !view.toggleMarker(4000)) { return false; }
    return coordinator.toggles == 2 && controller.validCount() == 1;
}

(:test)
function runViewUpperActionSavesCalibration(logger as Test.Logger) as Lang.Boolean {
    var target = new CalibrationTargetFake();
    var controller = new CalibrationController();
    controller.configure(:inline, :skate_only, 2500, 5);
    var view = new CalibrationRunView(target, controller);
    view.requestSave();
    return target.saves == 1;
}

(:test)
function missingMotionStillCompletesMarkerPairAndAdvances(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    controller.configure(:inline, :skate_only, 2000, 5);
    var coordinator = new CalibrationCoordinatorFake();
    coordinator.lastShiftPushes = null;
    coordinator.lastShiftDistanceCm = null;
    coordinator.coveragePercent = 0;
    var view = new CalibrationRunView(new CalibrationTargetFake(), controller);
    view.setCoordinator(coordinator);
    if (!view.toggleMarker(1000) || !view.toggleMarker(11000)) { return false; }
    if (view.getState() != :end || controller.invalidCount() != 1 ||
        controller.validCount() != 0) { return false; }
    if (!view.toggleMarker(12000)) { return false; }
    if (view.getState() != :ready || coordinator.toggles != 2) { return false; }
    return view.toggleMarker(13000) && view.getState() == :run &&
        coordinator.toggles == 3;
}
