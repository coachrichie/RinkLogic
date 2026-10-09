using Toybox.Lang;
using Toybox.Test as Test;

(:test)
function calibrationNeedsFiveValidRepetitions(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    controller.configure(:ice, :skate_only, 2500, 5);
    for (var i = 0; i < 4; i += 1) {
        controller.startRepetition(i * 10000);
        controller.endRepetition(i * 10000 + 4000,
            {:distanceCm=>2500, :pushes=>8, :coveragePercent=>100});
    }
    return !controller.isEligible() && controller.validCount() == 4;
}

(:test)
function calibrationEligibleAfterFiveMatchingRepetitions(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    controller.configure(:inline, :puck_stickhandling, 3000, 5);
    for (var i = 0; i < 5; i += 1) {
        controller.startRepetition(i * 10000);
        controller.endRepetition(i * 10000 + 5000,
            {:distanceCm=>3000, :pushes=>9, :coveragePercent=>90});
    }
    return controller.isEligible() && controller.validCount() == 5 &&
        controller.summary()[:sport] == :inline &&
        controller.summary()[:condition] == :puck_stickhandling;
}

(:test)
function invalidDistanceAndDuplicateMarkerNeverBecomeEligible(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    controller.configure(:ice, :skate_only, 2000, 5);
    controller.startRepetition(0);
    controller.endRepetition(1000, {:distanceCm=>null, :pushes=>4,
        :coveragePercent=>100});
    controller.startRepetition(2000);
    controller.startRepetition(2500);
    return !controller.isEligible() && controller.validCount() == 0 &&
        controller.invalidCount() == 2;
}

(:test)
function zeroMotionCoverageCannotValidateARepetition(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    controller.configure(:inline, :skate_only, 2000, 5);
    controller.startRepetition(1000);
    var accepted = controller.endRepetition(11000,
        {:distanceCm=>0, :pushes=>0, :coveragePercent=>0});
    return !accepted && controller.validCount() == 0 &&
        controller.invalidCount() == 1 && !controller.isEligible();
}

(:test)
function incompleteCalibrationCannotBeEligible(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    controller.configure(:ice, :skate_only, 2500, 5);
    controller.startRepetition(0);
    controller.abort();
    return !controller.isEligible() && controller.summary()[:status] == :incomplete;
}
