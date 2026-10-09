using Toybox.Lang;
using Toybox.Test as Test;

function distanceResult(atMs, events, startMs, sensorValid, gap) as Lang.Dictionary {
    var intervals = [];
    if (sensorValid) {
        intervals.add({:startMs=>startMs, :endMs=>atMs});
    }
    return {:atMs=>atMs, :events=>events,
        :validMs=>sensorValid ? atMs - startMs : 0,
        :observedIntervals=>intervals,
        :sensorValid=>sensorValid, :gap=>gap};
}

function pushAt(atMs, startsBurst) as Lang.Dictionary {
    return {:atMs=>atMs, :startsBurst=>startsBurst};
}

(:test)
function fourShortTwoLongPushesMakeNinePointFiveMetres(logger as Test.Logger) as Lang.Boolean {
    var estimate = new DistanceEstimator();
    estimate.beginShift(0);
    var times = [100, 700, 1300, 1900, 2500, 3100];
    for (var i = 0; i < times.size(); i += 1) {
        estimate.observe(distanceResult(times[i],
            [pushAt(times[i], i == 0)], times[i] - 100, true, false));
    }
    var finalShift = estimate.endShift(3200);
    var summary = estimate.sessionSummary();
    return finalShift[:pushes] == 6 && finalShift[:distanceCm] == 950 &&
        finalShift[:shortPushes] == 4 && summary[:totalDistanceCm] == 950 &&
        summary[:shortPushesTotal] == 4;
}

(:test)
function secondBurstRestartsFourShortPushes(logger as Test.Logger) as Lang.Boolean {
    var estimate = new DistanceEstimator();
    estimate.beginShift(0);
    estimate.observe(distanceResult(600, [pushAt(100, true), pushAt(600, false)],
        0, true, false));
    estimate.observe(distanceResult(3100,
        [pushAt(2600, true), pushAt(3100, false)], 2500, true, false));
    return estimate.snapshot(3100)[:totalDistanceCm] == 500 &&
        estimate.snapshot(3100)[:shortPushesTotal] == 4;
}

(:test)
function benchAndPreShiftEventsNeverAddDistance(logger as Test.Logger) as Lang.Boolean {
    var estimate = new DistanceEstimator();
    estimate.observe(distanceResult(200, [pushAt(100, true)], 0, true, false));
    estimate.beginShift(500);
    estimate.observe(distanceResult(800,
        [pushAt(100, true), pushAt(700, false)], 500, true, false));
    var shift = estimate.endShift(800);
    estimate.observe(distanceResult(1000, [pushAt(900, false)], 800, true, false));
    return shift[:pushes] == 1 && shift[:distanceCm] == 225 &&
        estimate.sessionSummary()[:totalPushes] == 1;
}

(:test)
function threeEventsWithFiveSecondsOfSignalShowEighteenPerMinute(logger as Test.Logger) as Lang.Boolean {
    var estimate = new DistanceEstimator();
    estimate.beginShift(0);
    for (var i = 1; i <= 5; i += 1) {
        var events = [];
        if (i == 1 || i == 3 || i == 5) {
            events.add(pushAt(i*1000, i == 1));
        }
        estimate.observe(distanceResult(i*1000, events,
            (i-1)*1000, true, false));
    }
    return estimate.snapshot(5000)[:cadencePerMin] == 18;
}

(:test)
function validInactivityShowsZeroButMissingSignalShowsUnknown(logger as Test.Logger) as Lang.Boolean {
    var estimate = new DistanceEstimator();
    estimate.beginShift(0);
    for (var i = 1; i <= 5; i += 1) {
        estimate.observe(distanceResult(i*1000, [], (i-1)*1000,
            true, false));
    }
    if (estimate.snapshot(5000)[:cadencePerMin] != 0) { return false; }
    estimate.observe(distanceResult(6000, [], 6000, false, true));
    var missing = estimate.snapshot(6000);
    return missing[:cadencePerMin] == null && missing[:partial] &&
        missing[:totalDistanceCm] == 0;
}

(:test)
function coverageCountsOnlyObservedManualIceTime(logger as Test.Logger) as Lang.Boolean {
    var estimate = new DistanceEstimator();
    estimate.beginShift(500);
    estimate.observe(distanceResult(1000, [], 0, true, false));
    estimate.observe(distanceResult(2000, [], 1000, false, true));
    var first = estimate.endShift(2000);
    estimate.observe(distanceResult(3000, [], 2000, true, false));
    var summary = estimate.sessionSummary();
    return first[:coveragePercent] == 33 &&
        summary[:coveragePercent] == 33 && summary[:partial];
}

(:test)
function noShiftHasUnknownCoverage(logger as Test.Logger) as Lang.Boolean {
    var estimate = new DistanceEstimator();
    estimate.observe(distanceResult(1000, [], 0, true, false));
    return estimate.sessionSummary()[:coveragePercent] == null &&
        estimate.snapshot(1000)[:shiftPushes] == null;
}

(:test)
function hockeyProfileSeparatesStartRhythmAndUnconfirmed(logger as Test.Logger) as Lang.Boolean {
    var estimate = new DistanceEstimator();
    estimate.beginShift(0);
    for (var i = 1; i <= 4; i += 1) {
        estimate.observe(distanceResult(i*500,
            [pushAt(i*500, i == 1)], i*500-100, true, false));
    }
    if (estimate.snapshot(2000)[:motionProfile] != :start) { return false; }
    estimate.observe(distanceResult(2500, [pushAt(2500, false)],
        2400, true, false));
    if (estimate.snapshot(2500)[:motionProfile] != :rhythm) { return false; }
    estimate.observe(distanceResult(3000, [], 2900, true, false));
    if (estimate.snapshot(3000)[:motionProfile] != :no_push) { return false; }
    estimate.observe(distanceResult(4000, [], 4000, false, true));
    return estimate.snapshot(4000)[:motionProfile] == :unconfirmed;
}

(:test)
function tinyValidIntervalStaysObservedWhenCoverageRoundsToZero(logger as Test.Logger) as Lang.Boolean {
    var estimate = new DistanceEstimator();
    estimate.beginShift(0);
    estimate.observe(distanceResult(1, [], 0, true, false));
    var closed = estimate.endShift(200000);
    return closed[:coveragePercent] == 0 && closed[:hasValidMotion] &&
        estimate.snapshot(200000)[:hasValidMotion];
}

(:test)
function estimatedSensorTimebaseRemainsVisibleInDistanceSnapshot(logger as Test.Logger) as Lang.Boolean {
    var estimate = new DistanceEstimator();
    estimate.beginShift(0);
    var result = distanceResult(1000, [pushAt(300, true)], 100, true, false);
    result[:timebase] = :estimated;
    estimate.observe(result);
    return estimate.snapshot(1000)[:timebase] == :estimated &&
        estimate.endShift(1000)[:timebase] == :estimated &&
        estimate.sessionSummary()[:timebase] == :estimated;
}

(:test)
function laterMeasuredShiftDoesNotInheritEstimatedShiftTimebase(logger as Test.Logger) as Lang.Boolean {
    var estimate = new DistanceEstimator();
    estimate.beginShift(0);
    var estimated = distanceResult(1000, [pushAt(300, true)],
        100, true, false);
    estimated[:timebase] = :estimated;
    estimate.observe(estimated);
    estimate.endShift(1000);
    estimate.beginShift(2000);
    var measured = distanceResult(3000, [pushAt(2300, true)],
        2100, true, false);
    measured[:timebase] = :measured;
    estimate.observe(measured);
    var current = estimate.snapshot(3000);
    return current[:timebase] == :measured &&
        current[:totalTimebase] == :estimated &&
        estimate.endShift(3000)[:timebase] == :measured &&
        estimate.sessionSummary()[:timebase] == :estimated;
}
