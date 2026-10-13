using Toybox.Lang;
using Toybox.Test;

(:test)
function firstShiftStartsWithoutArtificialBenchLap(logger as Test.Logger) as Lang.Boolean {
    var tracker = new PhaseLapTracker();
    tracker.initialize();
    var firstStartInterval = tracker.startShift(1000);
    if (firstStartInterval != null) { return false; }
    var interval = tracker.finish(6000);
    if (interval == null) { return false; }
    if (interval[:phase] != :on_ice) { return false; }
    if (interval[:startedAtMs] != 1000) { return false; }
    if (interval[:endedAtMs] != 6000) { return false; }
    if (interval[:durationMs] != 5000) { return false; }
    return tracker.finish(6000) == null;
}

(:test)
function endShiftClosesOnIceAndStartsBench(logger as Test.Logger) as Lang.Boolean {
    var tracker = new PhaseLapTracker();
    tracker.initialize();
    tracker.startShift(1000);
    var interval = tracker.endShift(4000);
    if (interval == null) { return false; }
    if (interval[:phase] != :on_ice) { return false; }
    if (interval[:startedAtMs] != 1000) { return false; }
    if (interval[:endedAtMs] != 4000) { return false; }
    return interval[:durationMs] == 3000;
}

(:test)
function nextShiftClosesBenchAndStartsOnIce(logger as Test.Logger) as Lang.Boolean {
    var tracker = new PhaseLapTracker();
    tracker.initialize();
    tracker.startShift(1000);
    var first = tracker.endShift(4000);
    var second = tracker.startShift(7000);
    var third = tracker.finish(9000);
    if (first == null) { return false; }
    if (first[:phase] != :on_ice || first[:startedAtMs] != 1000 ||
            first[:endedAtMs] != 4000 || first[:durationMs] != 3000) { return false; }
    if (second == null) { return false; }
    if (second[:phase] != :bench || second[:startedAtMs] != 4000 ||
            second[:endedAtMs] != 7000 || second[:durationMs] != 3000) { return false; }
    if (third == null) { return false; }
    return third[:phase] == :on_ice && third[:startedAtMs] == 7000 &&
        third[:endedAtMs] == 9000 && third[:durationMs] == 2000;
}

(:test)
function finishClosesOpenOnIceOrBenchExactlyOnce(logger as Test.Logger) as Lang.Boolean {
    var onIce = new PhaseLapTracker();
    onIce.initialize();
    onIce.startShift(1000);
    var onIceFinal = onIce.finish(4500);
    var onIceAgain = onIce.finish(5000);

    var bench = new PhaseLapTracker();
    bench.initialize();
    bench.startShift(1000);
    bench.endShift(3000);
    var benchFinal = bench.finish(8000);
    var benchAgain = bench.finish(9000);

    if (onIceFinal == null || onIceAgain != null) { return false; }
    if (onIceFinal[:phase] != :on_ice || onIceFinal[:startedAtMs] != 1000 ||
            onIceFinal[:endedAtMs] != 4500 || onIceFinal[:durationMs] != 3500) { return false; }
    if (benchFinal == null || benchAgain != null) { return false; }
    return benchFinal[:phase] == :bench && benchFinal[:startedAtMs] == 3000 &&
        benchFinal[:endedAtMs] == 8000 && benchFinal[:durationMs] == 5000;
}

(:test)
function finishBeforeFirstShiftReturnsNull(logger as Test.Logger) as Lang.Boolean {
    var tracker = new PhaseLapTracker();
    tracker.initialize();
    var firstFinish = tracker.finish(1000);
    var repeatedFinish = tracker.finish(2000);
    return firstFinish == null && repeatedFinish == null;
}

(:test)
function duplicateOrBackwardTimestampDoesNotCreateLap(logger as Test.Logger) as Lang.Boolean {
    var tracker = new PhaseLapTracker();
    tracker.initialize();
    tracker.startShift(1000);
    var duplicateEnd = tracker.endShift(1000);
    var backwardEnd = tracker.endShift(900);
    var backwardFinish = tracker.finish(900);
    var validEnd = tracker.endShift(3000);
    var duplicateStart = tracker.startShift(3000);
    var validStart = tracker.startShift(5000);
    if (duplicateEnd != null || backwardEnd != null || backwardFinish != null) { return false; }
    if (validEnd == null || duplicateStart != null) { return false; }
    if (validEnd[:phase] != :on_ice || validEnd[:startedAtMs] != 1000 ||
            validEnd[:endedAtMs] != 3000 || validEnd[:durationMs] != 2000) { return false; }
    if (validStart == null) { return false; }
    return validStart[:phase] == :bench && validStart[:startedAtMs] == 3000 &&
        validStart[:endedAtMs] == 5000 && validStart[:durationMs] == 2000;
}

(:test)
function laterDuplicateStartWhileOnIceKeepsOriginalInterval(logger as Test.Logger) as Lang.Boolean {
    var tracker = new PhaseLapTracker();
    tracker.initialize();
    tracker.startShift(1000);
    var duplicateStart = tracker.startShift(2500);
    var originalInterval = tracker.endShift(4000);

    if (duplicateStart != null || originalInterval == null) { return false; }
    return originalInterval[:phase] == :on_ice &&
        originalInterval[:startedAtMs] == 1000 &&
        originalInterval[:endedAtMs] == 4000 &&
        originalInterval[:durationMs] == 3000;
}

(:test)
function laterDuplicateEndWhileBenchKeepsOriginalInterval(logger as Test.Logger) as Lang.Boolean {
    var tracker = new PhaseLapTracker();
    tracker.initialize();
    tracker.startShift(1000);
    tracker.endShift(3000);
    var duplicateEnd = tracker.endShift(5000);
    var originalInterval = tracker.startShift(7000);

    if (duplicateEnd != null || originalInterval == null) { return false; }
    return originalInterval[:phase] == :bench &&
        originalInterval[:startedAtMs] == 3000 &&
        originalInterval[:endedAtMs] == 7000 &&
        originalInterval[:durationMs] == 4000;
}

(:test)
function backwardStartFromBenchKeepsBenchInterval(logger as Test.Logger) as Lang.Boolean {
    var tracker = new PhaseLapTracker();
    tracker.initialize();
    tracker.startShift(1000);
    tracker.endShift(3000);
    var backwardStart = tracker.startShift(2500);
    var benchInterval = tracker.startShift(5000);

    if (backwardStart != null || benchInterval == null) { return false; }
    return benchInterval[:phase] == :bench &&
        benchInterval[:startedAtMs] == 3000 &&
        benchInterval[:endedAtMs] == 5000 &&
        benchInterval[:durationMs] == 2000;
}

(:test)
function transitionsAfterFinishDoNotCreateIntervals(logger as Test.Logger) as Lang.Boolean {
    var tracker = new PhaseLapTracker();
    tracker.initialize();
    tracker.startShift(1000);
    var finalInterval = tracker.finish(3000);
    var lateStart = tracker.startShift(4000);
    var lateEnd = tracker.endShift(5000);
    var repeatedFinish = tracker.finish(6000);

    if (finalInterval == null || lateStart != null || lateEnd != null ||
            repeatedFinish != null) { return false; }
    return finalInterval[:phase] == :on_ice &&
        finalInterval[:startedAtMs] == 1000 &&
        finalInterval[:endedAtMs] == 3000 &&
        finalInterval[:durationMs] == 2000;
}
