using Toybox.Lang;
using Toybox.Test;

(:test)
function analyticsUsesLastValidHeartRatePerSecond(logger as Test.Logger) as Lang.Boolean {
    var analytics = new SessionAnalytics();
    analytics.start(1000, {:hrMax=>200, :hrZones=>[100, 120, 140, 160, 180, 200]});
    analytics.onHeartRate(1100, 80);
    analytics.onHeartRate(1500, 90);
    analytics.onHeartRate(2100, 100);
    analytics.finish(3000);
    var summary = analytics.snapshot();
    return summary[:durationMs] == 2000 &&
        summary[:averageHeartRate] == 95 &&
        summary[:maximumHeartRate] == 100;
}

(:test)
function analyticsComputesAverageMaximumZonesAndOverNinety(logger as Test.Logger) as Lang.Boolean {
    var analytics = new SessionAnalytics();
    analytics.start(0, {:hrMax=>200, :hrZones=>[100, 120, 140, 160, 180, 200]});
    analytics.onHeartRate(100, 110);
    analytics.onHeartRate(1100, 130);
    analytics.onHeartRate(2100, 150);
    analytics.onHeartRate(3100, 170);
    analytics.onHeartRate(4100, 190);
    analytics.finish(5000);
    var summary = analytics.snapshot();
    var zones = summary[:zoneSeconds];
    return summary[:averageHeartRate] == 150 &&
        summary[:maximumHeartRate] == 190 &&
        zones != null && zones.size() == 5 &&
        zones[0] == 1 && zones[1] == 1 && zones[2] == 1 &&
        zones[3] == 1 && zones[4] == 1 &&
        summary[:overNinetySeconds] == 1;
}

(:test)
function analyticsLeavesZonesUnavailableWithoutBoundariesOrHrMax(logger as Test.Logger) as Lang.Boolean {
    var analytics = new SessionAnalytics();
    analytics.start(0, {:hrMax=>null, :hrZones=>null});
    analytics.onHeartRate(100, 150);
    analytics.finish(1000);
    var summary = analytics.snapshot();
    return summary[:averageHeartRate] == 150 &&
        summary[:maximumHeartRate] == 150 &&
        summary[:zoneSeconds] == null &&
        summary[:overNinetySeconds] == null;
}

(:test)
function analyticsComputesShiftDurationsMedianRatiosAndDensity(logger as Test.Logger) as Lang.Boolean {
    var analytics = new SessionAnalytics();
    analytics.start(0, {:hrMax=>200, :hrZones=>null});
    analytics.onShiftStarted(1000);
    analytics.onShiftEnded(11000);
    analytics.onShiftStarted(21000);
    analytics.onShiftEnded(41000);
    analytics.finish(60000);
    var summary = analytics.snapshot();
    return summary[:shiftCount] == 2 && summary[:timeOnIceMs] == 30000 &&
        summary[:benchTimeMs] == 30000 && summary[:averageShiftMs] == 15000 &&
        summary[:shortestShiftMs] == 10000 && summary[:longestShiftMs] == 20000 &&
        summary[:medianShiftMs] == 15000 && summary[:workRestTenths] == 10 &&
        summary[:shiftDensityPerHour] == 120;
}

(:test)
function analyticsClosesOpenShiftAtFinish(logger as Test.Logger) as Lang.Boolean {
    var analytics = new SessionAnalytics();
    analytics.start(0, {:hrMax=>200, :hrZones=>null});
    analytics.onShiftStarted(1000);
    analytics.finish(11000);
    var summary = analytics.snapshot();
    return summary[:shiftCount] == 1 && summary[:timeOnIceMs] == 10000 &&
        summary[:benchTimeMs] == 1000 && summary[:averageShiftMs] == 10000 &&
        summary[:shortestShiftMs] == 10000 && summary[:longestShiftMs] == 10000 &&
        summary[:medianShiftMs] == 10000;
}

(:test)
function analyticsRequiresSeventyPercentCoverageForShiftHeartRate(logger as Test.Logger) as Lang.Boolean {
    var analytics = new SessionAnalytics();
    analytics.start(0, {:hrMax=>200, :hrZones=>null});
    analytics.onShiftStarted(0);
    for (var second = 0; second < 7; second += 1) {
        analytics.onHeartRate(second * 1000 + 100, 130);
    }
    analytics.onShiftEnded(10000);
    analytics.onShiftStarted(11000);
    for (var later = 11; later < 17; later += 1) {
        analytics.onHeartRate(later * 1000 + 100, 180);
    }
    analytics.onShiftEnded(21000);
    analytics.finish(22000);
    var summary = analytics.snapshot();
    return summary[:averageShiftHeartRate] == 130 &&
        summary[:topShiftHeartRates].size() == 1 &&
        summary[:topShiftHeartRates][0] == 130;
}

(:test)
function analyticsRanksTopThreeByHeartRateDurationThenStart(logger as Test.Logger) as Lang.Boolean {
    var analytics = new SessionAnalytics();
    analytics.start(0, {:hrMax=>220, :hrZones=>null});
    addAnalyticsShift(analytics, 0, 10000, 150);
    addAnalyticsShift(analytics, 11000, 31000, 160);
    addAnalyticsShift(analytics, 32000, 42000, 160);
    addAnalyticsShift(analytics, 43000, 53000, 170);
    analytics.finish(54000);
    var summary = analytics.snapshot();
    var heartRates = summary[:topShiftHeartRates];
    var indices = summary[:topShiftIndices];
    return heartRates.size() == 3 && heartRates[0] == 170 &&
        heartRates[1] == 160 && heartRates[2] == 160 &&
        indices[0] == 4 && indices[1] == 2 && indices[2] == 3;
}

function addAnalyticsShift(analytics, startedAtMs, endedAtMs, bpm) as Void {
    analytics.onShiftStarted(startedAtMs);
    var firstSecond = startedAtMs / 1000;
    var lastSecond = endedAtMs / 1000;
    for (var second = firstSecond; second < lastSecond; second += 1) {
        analytics.onHeartRate(second * 1000 + 100, bpm);
    }
    analytics.onShiftEnded(endedAtMs);
}

(:test)
function analyticsComputesThirtyAndSixtySecondHeartRateDrops(logger as Test.Logger) as Lang.Boolean {
    var analytics = new SessionAnalytics();
    analytics.start(0, {:hrMax=>200, :hrZones=>null});
    addAnalyticsShift(analytics, 0, 10000, 180);
    analytics.onHeartRate(40100, 150);
    analytics.onHeartRate(70100, 130);
    analytics.finish(76000);
    var laps = analytics.drainReadyShiftLaps(76000);
    return laps.size() == 1 && laps[0][:heartRateDrop30] == 30 &&
        laps[0][:heartRateDrop60] == 50 &&
        analytics.drainReadyShiftLaps(76000).size() == 0;
}

(:test)
function analyticsAllowsNegativeRecovery(logger as Test.Logger) as Lang.Boolean {
    var analytics = new SessionAnalytics();
    analytics.start(0, {:hrMax=>200, :hrZones=>null});
    addAnalyticsShift(analytics, 0, 10000, 150);
    analytics.onHeartRate(40100, 160);
    analytics.onHeartRate(70100, 170);
    analytics.finish(76000);
    var laps = analytics.drainReadyShiftLaps(76000);
    return laps.size() == 1 && laps[0][:heartRateDrop30] == -10 &&
        laps[0][:heartRateDrop60] == -20;
}

(:test)
function analyticsAbortsPendingRecoveryWhenNextShiftStarts(logger as Test.Logger) as Lang.Boolean {
    var analytics = new SessionAnalytics();
    analytics.start(0, {:hrMax=>200, :hrZones=>null});
    addAnalyticsShift(analytics, 0, 10000, 180);
    analytics.onHeartRate(40100, 150);
    analytics.onShiftStarted(50000);
    var laps = analytics.drainReadyShiftLaps(50000);
    return laps.size() == 1 && laps[0][:heartRateDrop30] == 30 &&
        laps[0][:heartRateDrop60] == null;
}

(:test)
function analyticsLeavesRecoveryMissingWithoutTargetSample(logger as Test.Logger) as Lang.Boolean {
    var analytics = new SessionAnalytics();
    analytics.start(0, {:hrMax=>200, :hrZones=>null});
    addAnalyticsShift(analytics, 0, 10000, 180);
    analytics.finish(76000);
    var laps = analytics.drainReadyShiftLaps(76000);
    return laps.size() == 1 && laps[0][:heartRateDrop30] == null &&
        laps[0][:heartRateDrop60] == null;
}
