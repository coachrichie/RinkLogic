using Toybox.Lang;
using Toybox.Test as Test;

function detectorBatch(times, peaks) as Lang.Dictionary {
    var ax = [];
    var ay = [];
    var az = [];
    var gx = [];
    var gy = [];
    var gz = [];
    for (var i = 0; i < times.size(); i += 1) {
        var peak = false;
        for (var j = 0; j < peaks.size(); j += 1) {
            if (times[i] == peaks[j]) { peak = true; }
        }
        ax.add(0); ay.add(0); az.add(peak ? 1220 : 1000);
        gx.add(0); gy.add(0); gz.add(peak ? 60 : 0);
    }
    return {:ax=>ax, :ay=>ay, :az=>az, :gx=>gx, :gy=>gy,
        :gz=>gz, :accelTimes=>times, :gyroTimes=>times};
}

(:test)
function detectorNeedsThreeRhythmicPeaksAndRejectsSingleSpike(logger as Test.Logger) as Lang.Boolean {
    var detector = new PushDetector();
    var single = detector.push(detectorBatch([0, 100, 200, 300, 400], [100]), 400);
    if (!single[:sensorValid] || single[:events].size() != 0) { return false; }
    var pair = detector.push(detectorBatch([500, 600, 700, 800, 900], [700]), 900);
    if (!pair[:sensorValid] || pair[:events].size() != 0 ||
        pair[:profile] != :unconfirmed) { return false; }
    var third = detector.push(detectorBatch(
        [1000, 1100, 1200, 1300, 1400], [1300]), 1400);
    return third[:sensorValid] && third[:profile] == :start &&
        third[:events].size() == 3 &&
        third[:events][0][:atMs] == 100 &&
        third[:events][0][:startsBurst] &&
        third[:events][1][:atMs] == 700 &&
        third[:events][2][:atMs] == 1300 &&
        !third[:events][2][:startsBurst];
}

(:test)
function detectorCooldownDoesNotDoubleCountPeak(logger as Test.Logger) as Lang.Boolean {
    var detector = new PushDetector();
    var result = detector.push(detectorBatch(
        [0, 100, 200, 300, 400, 500, 600, 700, 800, 900,
         1000, 1100, 1200, 1300, 1400], [100, 300, 700, 1300]), 1400);
    return result[:events].size() == 3 &&
        result[:events][0][:atMs] == 100 &&
        result[:events][1][:atMs] == 700 &&
        result[:events][2][:atMs] == 1300;
}

(:test)
function detectorQuietTransitionStartsNewBurst(logger as Test.Logger) as Lang.Boolean {
    var detector = new PushDetector();
    detector.push(detectorBatch([0, 100, 200, 300, 400, 500, 600, 700,
        800, 900, 1000, 1100, 1200, 1300], [100, 700, 1300]), 1300);
    detector.push(detectorBatch([2300, 2400, 2500, 2600, 2700, 2800], []), 2800);
    var next = detector.push(detectorBatch(
        [4000, 4100, 4200, 4300, 4400, 4500, 4600, 4700,
         4800, 4900, 5000, 5100, 5200, 5300],
        [4100, 4700, 5300]), 5300);
    return next[:events].size() == 3 &&
        next[:events][0][:startsBurst] &&
        !next[:events][2][:startsBurst];
}

(:test)
function detectorMissingGyroAndTimestampsAreInvalid(logger as Test.Logger) as Lang.Boolean {
    var detector = new PushDetector();
    var noGyro = detectorBatch([0, 100, 200], [100]);
    noGyro[:gyroTimes] = null;
    var first = detector.push(noGyro, 200);
    var second = detector.push(null, 1200);
    return !first[:sensorValid] && first[:events].size() == 0 &&
        first[:validMs] == 0 && !second[:sensorValid] &&
        second[:events].size() == 0;
}

(:test)
function detectorGapNeverInterpolatesMissingPushes(logger as Test.Logger) as Lang.Boolean {
    var detector = new PushDetector();
    detector.push(detectorBatch([0, 100, 200, 300, 400, 500, 600, 700,
        800, 900, 1000, 1100, 1200, 1300], [100, 700, 1300]), 1300);
    var afterGap = detector.push(detectorBatch(
        [5000, 5100, 5200, 5300], [5100]), 5300);
    return afterGap[:gap] && afterGap[:events].size() == 0 &&
        afterGap[:validMs] <= 300;
}

(:test)
function detectorReportsOnlyObservedTimeIntervals(logger as Test.Logger) as Lang.Boolean {
    var detector = new PushDetector();
    var result = detector.push(detectorBatch(
        [0, 100, 3000, 3100], []), 3100);
    return result[:atMs] == 3100 && result[:gap] &&
        result[:validMs] == 100 &&
        result[:observedIntervals].size() == 1 &&
        result[:observedIntervals][0][:startMs] == 3000 &&
        result[:observedIntervals][0][:endMs] == 3100;
}

(:test)
function estimatedPacketsRejectOverlappingCallbackWindows(logger as Test.Logger) as Lang.Boolean {
    var detector = new PushDetector();
    var times = [-900, -800, -700, -600, -500,
        -400, -300, -200, -100, 0];
    var first = detectorBatch(times, [-700]);
    first[:timebase] = :estimated;
    var second = detectorBatch(times, [-700]);
    second[:timebase] = :estimated;
    var initial = detector.push(first, 1000);
    var overlapping = detector.push(second, 1800);
    return initial[:sensorValid] && !overlapping[:sensorValid] &&
        overlapping[:gap] && overlapping[:validMs] == 0 &&
        overlapping[:events].size() == 0;
}

(:test)
function estimatedCoverageRequiresPairedGyroSamples(logger as Test.Logger) as Lang.Boolean {
    var detector = new PushDetector();
    var times = [-900, -800, -700, -600, -500,
        -400, -300, -200, -100, 0];
    var batch = detectorBatch(times, []);
    batch[:gyroTimes] = [-400, -300, -200, -100, 0];
    batch[:gx] = [0, 0, 0, 0, 0];
    batch[:gy] = [0, 0, 0, 0, 0];
    batch[:gz] = [0, 0, 0, 0, 0];
    batch[:timebase] = :estimated;
    var result = detector.push(batch, 1000);
    return result[:sensorValid] && result[:gap] &&
        result[:validMs] == 500 &&
        result[:observedIntervals].size() == 5;
}
