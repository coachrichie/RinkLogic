using Toybox.Lang;
using Toybox.Test as Test;

function calibrationMetrics(distanceCm, pushes, coveragePercent, timebase) as Lang.Dictionary {
    return {:distanceCm=>distanceCm, :pushes=>pushes,
        :coveragePercent=>coveragePercent, :timebase=>timebase};
}

function acceptCalibrationRun(controller, index, distanceCm) as Lang.Boolean {
    var start = 1000 + index * 40000;
    if (controller.progress()[:status] == :accepted ||
        controller.progress()[:status] == :retry) {
        if (!controller.acknowledgeResult()) { return false; }
    }
    return controller.startRepetition(start) &&
        controller.endRepetition(start + 10000,
            calibrationMetrics(distanceCm, 10, 90, :measured));
}

function completeCalibration(controller, distances) as Lang.Boolean {
    for (var i = 0; i < distances.size(); i += 1) {
        if (!acceptCalibrationRun(controller, i, distances[i])) { return false; }
    }
    return true;
}

(:test)
function calibrationUsesExactConditionAndPaceOrder(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    if (!controller.configure(:ice)) { return false; }
    var paces = [:slow, :fast, :normal, :slow, :fast];
    for (var i = 0; i < 10; i += 1) {
        if (controller.currentCondition() != (i < 5 ? :skate_only : :puck_stickhandling) ||
            controller.currentPace() != paces[i % 5] ||
            !acceptCalibrationRun(controller, i, 2500)) { return false; }
    }
    return controller.currentCondition() == null && controller.currentPace() == null;
}

(:test)
function calibrationRejectsUnsupportedConfiguration(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    return !controller.configure(:run) && controller.configure(:inline) &&
        controller.summary()[:referenceDistanceCm] == 2000;
}

(:test)
function calibrationRunGatesAreInclusive(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    if (!controller.configure(:inline)) { return false; }
    if (!controller.startRepetition(1000) ||
        !controller.endRepetition(3000,
            calibrationMetrics(4000, 1, 80, :measured))) { return false; }
    if (!controller.acknowledgeResult()) { return false; }
    if (!controller.startRepetition(4000) ||
        !controller.endRepetition(34000,
            calibrationMetrics(1334, 1, 100, :estimated))) { return false; }
    return controller.validCount() == 2 && controller.invalidCount() == 0;
}

(:test)
function calibrationRejectsEveryOutOfRangeRunWithoutAdvancing(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    if (!controller.configure(:ice)) { return false; }
    var invalid = [
        {:duration=>1999, :metrics=>calibrationMetrics(2500, 8, 90, :measured)},
        {:duration=>30001, :metrics=>calibrationMetrics(2500, 8, 90, :measured)},
        {:duration=>5000, :metrics=>calibrationMetrics(0, 8, 90, :measured)},
        {:duration=>5000, :metrics=>calibrationMetrics(2500, 0, 90, :measured)},
        {:duration=>5000, :metrics=>calibrationMetrics(2500, 8, 79, :measured)},
        {:duration=>5000, :metrics=>calibrationMetrics(2500, 8, 101, :measured)},
        {:duration=>5000, :metrics=>calibrationMetrics(2500, 8, 90, :unknown)},
        {:duration=>5000, :metrics=>calibrationMetrics(499, 8, 90, :estimated)},
        {:duration=>5000, :metrics=>calibrationMetrics(5001, 8, 90, :estimated)}
    ];
    for (var i = 0; i < invalid.size(); i += 1) {
        var start = 1000 + i * 40000;
        if (!controller.startRepetition(start) ||
            controller.endRepetition(start + invalid[i][:duration], invalid[i][:metrics]) ||
            controller.currentCondition() != :skate_only ||
            controller.currentPace() != :slow) { return false; }
        if (!controller.acknowledgeResult()) { return false; }
    }
    return controller.validCount() == 0 && controller.invalidCount() == invalid.size();
}

(:test)
function calibrationRequiresMonotonicMarkersAndRetriesSamePrompt(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    if (!controller.configure(:ice) || !controller.startRepetition(1000)) { return false; }
    if (controller.endRepetition(1000,
        calibrationMetrics(2500, 8, 90, :measured))) { return false; }
    if (!controller.acknowledgeResult() || controller.startRepetition(999)) { return false; }
    if (!controller.acknowledgeResult() || !controller.startRepetition(2000) ||
        controller.startRepetition(3000)) { return false; }
    return controller.validCount() == 0 && controller.invalidCount() == 3 &&
        controller.currentCondition() == :skate_only && controller.currentPace() == :slow;
}

(:test)
function calibrationStoresCompactDerivedRunMetrics(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    if (!controller.configure(:inline) || !controller.startRepetition(1000) ||
        !controller.endRepetition(11000,
            calibrationMetrics(1600, 8, 88, :estimated))) { return false; }
    var run = controller.summary()[:acceptedRuns][0];
    return run[:condition] == :skate_only && run[:pace] == :slow &&
        run[:durationMinutes] > 0.1666 && run[:durationMinutes] < 0.1667 &&
        run[:cadencePerMinute] == 48.0 && run[:effectiveStepLengthCm] == 250.0 &&
        run[:baselineRatio] == 1.25 && run[:timebase] == :estimated;
}

(:test)
function calibrationCandidateUsesTenRunMedianRoundedHalfUp(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    if (!controller.configure(:inline)) { return false; }
    var distances = [2000, 2000, 2000, 2000, 2000,
        2001, 2001, 2001, 2001, 2001];
    if (!completeCalibration(controller, distances) || !controller.isEligible()) { return false; }
    var candidate = controller.candidateProfile();
    return candidate != null && candidate[:schemaVersion] == 1 &&
        candidate[:sport] == :inline && candidate[:source] == :local_known_distance &&
        candidate[:referenceDistanceCm] == 2000 && candidate[:validRepetitionCount] == 10 &&
        candidate[:factor] == 0.9998 &&
        candidate[:conditionMedians][:skate_only] == 1.0 &&
        candidate[:conditionMedians][:puck_stickhandling] > 0.9994;
}

(:test)
function calibrationRejectsHighRelativeMad(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    if (!controller.configure(:ice) ||
        !completeCalibration(controller, [1667, 1667, 2500, 3333, 3333,
            2500, 2500, 2500, 2500, 2500])) { return false; }
    return !controller.isEligible() && controller.candidateProfile() == null &&
        controller.summary()[:status] == :inconsistent;
}

(:test)
function calibrationRejectsConditionMedianDisagreement(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    if (!controller.configure(:ice) ||
        !completeCalibration(controller, [2500, 2500, 2500, 2500, 2500,
            3125, 3125, 3125, 3125, 3125])) { return false; }
    return !controller.isEligible() && controller.candidateProfile() == null;
}

(:test)
function calibrationAbortIsTerminal(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    if (!controller.configure(:ice) || !controller.startRepetition(1000)) { return false; }
    controller.abort();
    return !controller.startRepetition(2000) && !controller.isEligible() &&
        controller.summary()[:status] == :incomplete;
}

(:test)
function calibrationCandidateReturnsDefensiveCopies(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    if (!controller.configure(:ice) ||
        !completeCalibration(controller, [2000, 2000, 2000, 2000, 2000,
            2000, 2000, 2000, 2000, 2000])) { return false; }
    var first = controller.candidateProfile();
    first[:factor] = 0.5;
    first[:conditionMedians][:skate_only] = 0.5;
    var second = controller.candidateProfile();
    return second[:factor] == 1.0 &&
        second[:conditionMedians][:skate_only] == 1.0 &&
        second[:conditionMedians][:puck_stickhandling] == 1.0;
}

(:test)
function calibrationFixedProtocolReportsSportCountsAndTwentyMetres(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    if (!controller.configure(:ice)) { return false; }
    var initial = controller.progress();
    if (initial[:sport] != :ice || initial[:referenceDistanceCm] != 2000 ||
        initial[:condition] != :skate_only || initial[:pace] != :slow ||
        initial[:withinConditionIndex] != 1 || initial[:acceptedCount] != 0 ||
        initial[:status] != :ready) { return false; }
    for (var i = 0; i < 10; i += 1) {
        var before = controller.progress();
        if (before[:withinConditionIndex] != (i % 5) + 1 ||
            before[:acceptedCount] != i ||
            !acceptCalibrationRun(controller, i, 2000)) { return false; }
        if (i < 9 && !controller.acknowledgeResult()) { return false; }
    }
    var complete = controller.progress();
    return complete[:sport] == :ice && complete[:acceptedCount] == 10 &&
        complete[:status] == :complete && controller.isEligible();
}

(:test)
function calibrationRejectionsExposeStableReasonsWithoutAdvancing(logger as Test.Logger) as Lang.Boolean {
    var cases = [
        {:duration=>1999, :metrics=>calibrationMetrics(2000, 8, 90, :measured), :reason=>:too_short},
        {:duration=>30001, :metrics=>calibrationMetrics(2000, 8, 90, :measured), :reason=>:too_long},
        {:duration=>5000, :metrics=>calibrationMetrics(null, null, 0, null), :reason=>:missing_motion},
        {:duration=>5000, :metrics=>calibrationMetrics(2000, 8, 79, :measured), :reason=>:low_coverage},
        {:duration=>5000, :metrics=>calibrationMetrics(0, 8, 90, :measured), :reason=>:invalid_distance},
        {:duration=>5000, :metrics=>calibrationMetrics(5000, 8, 90, :measured), :reason=>:invalid_ratio}
    ];
    for (var i = 0; i < cases.size(); i += 1) {
        var controller = new CalibrationController();
        if (!controller.configure(:inline) || !controller.startRepetition(1000) ||
            controller.endRepetition(1000 + cases[i][:duration], cases[i][:metrics])) {
            return false;
        }
        var progress = controller.progress();
        if (progress[:acceptedCount] != 0 || progress[:withinConditionIndex] != 1 ||
            progress[:status] != :retry ||
            progress[:lastRejectionReason] != cases[i][:reason]) { return false; }
    }
    var marker = new CalibrationController();
    if (!marker.configure(:ice) || !marker.startRepetition(1000) ||
        marker.endRepetition(1000, calibrationMetrics(2000, 8, 90, :measured))) {
        return false;
    }
    return marker.progress()[:acceptedCount] == 0 &&
        marker.progress()[:lastRejectionReason] == :invalid_marker;
}
