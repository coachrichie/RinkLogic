using Toybox.Lang;
using Toybox.Test as Test;
using Toybox.Activity;
using Toybox.FitContributor;

class FailingShadowWriterFactoryFake {
    function create(session) { return new FailingShadowWriterFake(); }
}
class FailingShadowWriterFake {
    function allocate() { return false; }
}
class ShadowFieldFake {
    var lastValue = null;
    function setData(value) { lastValue = value; }
}
class ThrowingPushFieldFake extends ShadowFieldFake {
    function setData(value) { throw new Lang.Exception(); }
}
class ShadowSessionFake extends RecordingSessionFake {
    var fieldIds = [];
    var fieldNames = {};
    var fieldTypes = {};
    var fieldScopes = {};
    var fieldUnits = {};
    var fieldNativeNums = {};
    var fieldCounts = {};
    var fields = {};
    var laps = 0;
    var lapSnapshots = [];
    var nativeFinalLap = null;
    var stopLapCount = null;
    var lastBoundaryMs = null;
    var lastAutoBoundaryMs = null;
    function createField(name, id, type, options) {
        fieldIds.add(id);
        fieldNames[id] = name;
        fieldTypes[id] = type;
        fieldScopes[id] = options[:mesgType];
        fieldUnits[id] = options[:units];
        fieldNativeNums[id] = options.hasKey(:nativeNum) ?
            options[:nativeNum] : null;
        fieldCounts[id] = options.hasKey(:count) ? options[:count] : null;
        var field = new ShadowFieldFake();
        fields[id] = field;
        return field;
    }
    function addLap() {
        laps += 1;
        lastBoundaryMs = fields[51].lastValue;
        if (fields.hasKey(55)) { lastAutoBoundaryMs = fields[55].lastValue; }
        lapSnapshots.add(snapshotLap());
        return true;
    }
    function snapshotLap() {
        var ice = fields.hasKey(113) ? fields[113].lastValue : null;
        var bench = fields.hasKey(114) ? fields[114].lastValue : null;
        var phase = ice != null && ice == ice ? "On-Ice" :
            (bench != null && bench == bench ? "Bench" : "");
        return {:manualState=>fields[52].lastValue,
            :autoState=>fields.hasKey(56) ? fields[56].lastValue : null,
            :pushes=>fields.hasKey(65) ? fields[65].lastValue : null,
            :distance=>fields.hasKey(66) ? fields[66].lastValue : null,
            :distanceMetres=>fields.hasKey(111) ? fields[111].lastValue : null,
            :phase=>phase, :onIceMinutes=>ice, :benchMinutes=>bench,
            :shortPushes=>fields.hasKey(71) ? fields[71].lastValue : null,
            :coverage=>fields.hasKey(72) ? fields[72].lastValue : null,
            :drop30=>fields.hasKey(93) ? fields[93].lastValue : null,
            :drop60=>fields.hasKey(94) ? fields[94].lastValue : null,
            :averageHeartRate=>fields.hasKey(95) ? fields[95].lastValue : null,
            :durationMinutes=>fields.hasKey(99) ? fields[99].lastValue : null};
    }
    function stop() as Lang.Boolean {
        stopLapCount = laps;
        stops += 1;
        if (stops == 1 && fields.hasKey(113) && fields.hasKey(114)) {
            var ice = fields[113].lastValue;
            var bench = fields[114].lastValue;
            if ((ice != null && ice == ice) || (bench != null && bench == bench)) {
                nativeFinalLap = snapshotLap();
                lapSnapshots.add(nativeFinalLap);
            }
        }
        return stopResult;
    }
}
class RejectingPhaseMinutesSessionFake extends ShadowSessionFake {
    function createField(name, id, type, options) {
        if (id == 113) { return null; }
        return ShadowSessionFake.createField(name, id, type, options);
    }
}
class FailingPushShadowSessionFake extends ShadowSessionFake {
    function createField(name, id, type, options) {
        var field = ShadowSessionFake.createField(name, id, type, options);
        if (id == 101) {
            field = new ThrowingPushFieldFake();
            fields[id] = field;
        }
        return field;
    }
}
class FailingPushRecordingFactoryFake {
    var session = new FailingPushShadowSessionFake();
    function createSession(options) { return session; }
}
class FailingSecondEndEstimator extends DistanceEstimator {
    var ends = 0;
    function endShift(atMs) as Lang.Dictionary {
        ends += 1;
        if (ends == 2) { throw new Lang.Exception(); }
        return DistanceEstimator.endShift(atMs);
    }
}
class FailingSummaryEstimator extends DistanceEstimator {
    function sessionSummary() as Lang.Dictionary {
        throw new Lang.Exception();
    }
}
class FailingLapShadowSessionFake extends ShadowSessionFake {
    function addLap() { laps += 1; return false; }
}
class FailingLapRecordingFactoryFake {
    var session = new FailingLapShadowSessionFake();
    function createSession(options) { return session; }
}
class ShadowRecordingFactoryFake {
    var session = new ShadowSessionFake();
    function createSession(options) { return session; }
}

function schemaTwelveSummary(factor) as Lang.Dictionary {
    var summary = {
        :shiftCount=>3, :timeOnIceMs=>95000, :benchTimeMs=>205000,
        :averageShiftMs=>31666, :averageShiftHeartRate=>157,
        :zoneSeconds=>[11, 22, 33, 44, 55], :overNinetySeconds=>12,
        :workRestTenths=>5, :shiftDensityPerHour=>36,
        :shortestShiftMs=>28000, :longestShiftMs=>36000,
        :medianShiftMs=>31000, :topShiftHeartRates=>[181, 175, 169],
        :detectedPushes=>146, :estimatedDistanceCm=>22000
    };
    if (factor != null) { summary[:personalCalibrationFactor] = factor; }
    return summary;
}

(:test)
function schemaTwelveReplacesAboveNinetyWithPersonalFactor(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    if (!writer.allocate() || session.fields[73].lastValue != 12 ||
        session.fields.hasKey(108) || !session.fields.hasKey(115) ||
        session.fieldTypes[115] != FitContributor.DATA_TYPE_FLOAT ||
        session.fieldScopes[115] != FitContributor.MESG_TYPE_SESSION ||
        !writer.writeActivitySummary(schemaTwelveSummary(0.7521))) { return false; }
    return session.fields[115].lastValue > 0.75209 &&
        session.fields[115].lastValue < 0.75211;
}

(:test)
function schemaTwelveKeepsThirtyFourTotalAndSixteenSessionFields(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    if (!(new ShadowFitWriter(session)).allocate() || session.fieldIds.size() != 34) {
        return false;
    }
    var sessionCount = 0;
    for (var i = 0; i < session.fieldIds.size(); i += 1) {
        if (session.fieldScopes[session.fieldIds[i]] == FitContributor.MESG_TYPE_SESSION) {
            sessionCount += 1;
        }
    }
    return sessionCount == 16 && session.fields.hasKey(97) &&
        session.fields.hasKey(110) && session.fields.hasKey(111) &&
        session.fields.hasKey(113) && session.fields.hasKey(114) &&
        session.fields.hasKey(115);
}

(:test)
function missingPersonalFactorWritesFitInvalid(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    return writer.allocate() &&
        writer.writeActivitySummary(schemaTwelveSummary(null)) &&
        session.fields[115].lastValue != session.fields[115].lastValue;
}

(:test)
function schemaTwelveAllocatesExclusivePhaseMinuteFieldsWithinLimit(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    if (!(new ShadowFitWriter(session)).allocate() ||
        session.fieldIds.size() != 34 || session.fields[73].lastValue != 12) { return false; }
    var sessionCount = 0;
    for (var i = 0; i < session.fieldIds.size(); i += 1) {
        if (session.fieldScopes[session.fieldIds[i]] == FitContributor.MESG_TYPE_SESSION) {
            sessionCount += 1;
        }
    }
    return sessionCount == 16 &&
        !session.fields.hasKey(63) && !session.fields.hasKey(66) &&
        !session.fields.hasKey(93) && !session.fields.hasKey(94) &&
        session.fieldNames[110].equals("estimated_distance_m_total") &&
        session.fieldTypes[110] == FitContributor.DATA_TYPE_FLOAT &&
        session.fieldScopes[110] == FitContributor.MESG_TYPE_RECORD &&
        session.fieldUnits[110].equals("m") &&
        session.fieldNames[111].equals("shift_estimated_distance_m") &&
        session.fieldTypes[111] == FitContributor.DATA_TYPE_FLOAT &&
        session.fieldScopes[111] == FitContributor.MESG_TYPE_LAP &&
        session.fieldUnits[111].equals("m") &&
        !session.fields.hasKey(112) &&
        session.fieldNames[113].equals("on_ice_phase_minutes") &&
        session.fieldNames[114].equals("bench_phase_minutes") &&
        session.fieldTypes[113] == FitContributor.DATA_TYPE_FLOAT &&
        session.fieldTypes[114] == FitContributor.DATA_TYPE_FLOAT &&
        session.fieldScopes[113] == FitContributor.MESG_TYPE_LAP &&
        session.fieldScopes[114] == FitContributor.MESG_TYPE_LAP &&
        session.fieldUnits[113].equals("min") &&
        session.fieldUnits[114].equals("min") &&
        session.fieldNativeNums[97] == null;
}

(:test)
function recordDistanceWritesMetresInsteadOfCentimetres(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    return writer.allocate() && writer.writeSecond(null, null, :on_ice,
        0, 1, 1000, {:totalPushes=>4, :totalDistanceCm=>22000}) &&
        session.fields[110].lastValue == 220.0;
}

(:test)
function onIceLapWritesPhaseDurationAndMetreDistance(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    if (!writer.allocate() || !writer.writePhaseLap({:phase=>:on_ice,
        :startedAtMs=>1000, :endedAtMs=>121000, :durationMs=>120000},
        {:averageHeartRate=>151, :pushes=>6, :distanceCm=>714,
            :coveragePercent=>80})) { return false; }
    var lap = session.lapSnapshots[0];
    return session.laps == 1 && lap[:phase].equals("On-Ice") &&
        lap[:onIceMinutes] == 2.0 &&
        lap[:benchMinutes] != lap[:benchMinutes] &&
        lap[:durationMinutes] == 2.0 && lap[:distanceMetres] == 7.14 &&
        lap[:pushes] == 6 && lap[:averageHeartRate] == 151 &&
        lap[:coverage] == 80;
}

(:test)
function benchLapWritesPhaseAndInvalidOptionalMetrics(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    if (!writer.allocate() || !writer.writePhaseLap({:phase=>:bench,
        :startedAtMs=>1000, :endedAtMs=>61000, :durationMs=>60000}, null)) { return false; }
    var lap = session.lapSnapshots[0];
    return lap[:phase].equals("Bench") && lap[:durationMinutes] == 1.0 &&
        lap[:benchMinutes] == 1.0 && lap[:onIceMinutes] != lap[:onIceMinutes] &&
        lap[:pushes] == 65535 && lap[:averageHeartRate] == 255 &&
        lap[:coverage] == 255 &&
        lap[:distanceMetres] != lap[:distanceMetres];
}

(:test)
function missingMotionWritesInvalidMetreDistance(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    if (!writer.allocate() || !writer.writePhaseLap({:phase=>:on_ice,
        :startedAtMs=>1000, :endedAtMs=>61000, :durationMs=>60000},
        {:averageHeartRate=>null, :pushes=>null, :distanceCm=>null,
            :coveragePercent=>null})) { return false; }
    var lap = session.lapSnapshots[0];
    return lap[:phase].equals("On-Ice") && lap[:durationMinutes] == 1.0 &&
        lap[:pushes] == 65535 && lap[:averageHeartRate] == 255 &&
        lap[:distanceMetres] != lap[:distanceMetres];
}

(:test)
function phaseMinuteAllocationFailurePreventsPartialSchemaActivation(logger as Test.Logger) as Lang.Boolean {
    var session = new RejectingPhaseMinutesSessionFake();
    var writer = new ShadowFitWriter(session);
    return !writer.allocate() && session.fields[73].lastValue == null &&
        !writer.writeSecond(null, null, :on_ice, 0, 1, 1000,
            {:totalPushes=>1, :totalDistanceCm=>100});
}

(:test)
function sessionRecorderDelegatesImmediatePhaseLap(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    return recorder.start(:ice) && recorder.writePhaseLap({:phase=>:bench,
        :startedAtMs=>1000, :endedAtMs=>61000, :durationMs=>60000}, null) &&
        factory.session.laps == 1 &&
        factory.session.lapSnapshots[0][:phase].equals("Bench");
}

(:test)
function finalPhaseIsStagedForNativeStopWithoutExplicitLap(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(recorder, clock);
    if (!coordinator.start(:ice) || !coordinator.toggleShift()) { return false; }
    clock.now = 61000;
    return coordinator.stopAndSave() && factory.session.stopLapCount == 0 &&
        factory.session.nativeFinalLap != null &&
        factory.session.nativeFinalLap[:onIceMinutes] == 1.0 &&
        factory.session.nativeFinalLap[:benchMinutes] !=
            factory.session.nativeFinalLap[:benchMinutes];
}

(:test)
function fifteenShiftsProduceTwentyNineExplicitAndOneNativeFinalLap(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(recorder, clock);
    if (!coordinator.start(:ice)) { return false; }
    for (var i = 0; i < 30; i += 1) {
        clock.now = 1000 + i * 1000;
        if (!coordinator.toggleShift()) { return false; }
    }
    if (factory.session.laps != 29) { return false; }
    clock.now = 31000;
    return coordinator.stopAndSave() && factory.session.stopLapCount == 29 &&
        factory.session.nativeFinalLap != null &&
        factory.session.nativeFinalLap[:benchMinutes] > 0 &&
        factory.session.nativeFinalLap[:onIceMinutes] !=
            factory.session.nativeFinalLap[:onIceMinutes];
}

(:test)
function distanceModelSourceDoesNotCreateFitField(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    var expectedIds = [44, 45, 51, 52, 55, 56, 62, 65, 71, 72,
        73, 74, 78, 85, 86, 95, 96, 97, 98, 99, 100,
        101, 102, 103, 104, 105, 106, 107, 109, 110, 111, 113, 114, 115];
    var expectedNames = ["motion_mg", "rotation_dps",
        "manual_boundary_ms", "manual_boundary_state",
        "auto_boundary_ms", "auto_boundary_state", "push_count_total",
        "shift_push_count",
        "shift_short_push_count", "shift_motion_coverage_percent", "summary_schema_version",
        "shift_count", "average_shift_heart_rate", "work_rest_ratio_tenths",
        "shift_density_per_hour",
        "shift_average_heart_rate", "detected_push_count", "estimated_distance_m",
        "average_shift_minutes", "shift_duration_minutes",
        "raw_push_candidate_count_total", "time_on_ice_minutes",
        "bench_time_minutes", "heart_rate_zone_1_minutes",
        "heart_rate_zone_2_minutes", "heart_rate_zone_3_minutes",
        "heart_rate_zone_4_minutes", "heart_rate_zone_5_minutes",
        "median_shift_minutes",
        "estimated_distance_m_total", "shift_estimated_distance_m",
        "on_ice_phase_minutes", "bench_phase_minutes",
        "personal_calibration_factor"];
    if (!writer.allocate() || !writer.writeSecond(null, null, :on_ice,
        0, 1, 1000, {:totalPushes=>2, :totalDistanceCm=>264,
            :cadencePerMin=>12, :distanceModelSource=>:profile_height}) ||
        session.fieldIds.size() != 34 || session.fieldNames.size() != 34) { return false; }
    for (var i = 0; i < expectedIds.size(); i += 1) {
        if (session.fieldIds[i] != expectedIds[i] ||
            !session.fieldNames[expectedIds[i]].equals(expectedNames[i])) { return false; }
    }
    return session.fields[62].lastValue == 2 && session.fields[110].lastValue == 2.64;
}

(:test)
function shadowWriterUsesOnlyNewStableFieldIds(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    var expected = [44, 45, 51, 52, 55, 56, 62, 65, 71, 72,
        73, 74, 78, 85, 86, 95, 96, 97, 98, 99, 100,
        101, 102, 103, 104, 105, 106, 107, 109, 110, 111, 113, 114, 115];
    if (!writer.allocate() || session.fieldIds.size() != 34) { return false; }
    for (var i = 0; i < expected.size(); i += 1) {
        if (session.fieldIds[i] != expected[i]) { return false; }
    }
    return session.fieldNames[73].equals("summary_schema_version") &&
        session.fieldNames[78].equals("average_shift_heart_rate") &&
        session.fieldNames[62].equals("push_count_total") &&
        session.fieldNames[95].equals("shift_average_heart_rate") &&
        session.fieldNames[99].equals("shift_duration_minutes") &&
        session.fieldNames[100].equals("raw_push_candidate_count_total") &&
        session.fieldTypes[62] == FitContributor.DATA_TYPE_UINT32 &&
        session.fieldTypes[74] == FitContributor.DATA_TYPE_UINT8 &&
        session.fieldTypes[101] == FitContributor.DATA_TYPE_FLOAT &&
        session.fieldTypes[96] == FitContributor.DATA_TYPE_UINT16 &&
        session.fieldTypes[97] == FitContributor.DATA_TYPE_FLOAT &&
        session.fieldTypes[98] == FitContributor.DATA_TYPE_FLOAT &&
        session.fieldTypes[113] == FitContributor.DATA_TYPE_FLOAT &&
        session.fieldTypes[114] == FitContributor.DATA_TYPE_FLOAT &&
        session.fieldScopes[62] == FitContributor.MESG_TYPE_RECORD &&
        session.fieldScopes[65] == FitContributor.MESG_TYPE_LAP &&
        session.fieldScopes[73] == FitContributor.MESG_TYPE_RECORD &&
        session.fieldScopes[115] == FitContributor.MESG_TYPE_SESSION &&
        session.fieldScopes[111] == FitContributor.MESG_TYPE_LAP &&
        session.fieldNativeNums[97] == null &&
        session.fields[73].lastValue == 12 &&
        writer.writeManualBoundary(12000, :on_ice, null) && session.laps == 1 &&
        session.lastBoundaryMs == 12000 && session.fields[51].lastValue == 0 &&
        session.fields[52].lastValue == 0;
}

(:test)
function schemaTwelveWritesLosslessShiftDurationAndDiagnostics(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    if (!writer.allocate() || session.fieldIds.size() != 34) { return false; }
    if (!session.fields.hasKey(44) || !session.fields.hasKey(45) ||
        !session.fields.hasKey(99) || !session.fields.hasKey(100)) { return false; }
    if (!writer.writeSecond({:valid=>true, :motionMg=>220,
        :rotationDps=>41}, null, :on_ice, 0, 1, 1000,
        {:totalPushes=>2, :totalDistanceCm=>250,
            :rawCandidateCountTotal=>5})) { return false; }
    if (session.fields[44].lastValue != 220 ||
        session.fields[45].lastValue != 41 ||
        session.fields[100].lastValue != 5) { return false; }
    if (!writer.writeShiftLap({:endedAtMs=>300000, :durationMs=>299000,
        :heartRateDrop30=>null, :heartRateDrop60=>null,
        :averageHeartRate=>150}, null)) { return false; }
    var duration = session.lapSnapshots[0][:durationMinutes];
    return duration > 4.983 && duration < 4.984;
}

(:test)
function unknownCoverageUsesInvalidSentinelButKnownZeroIsZero(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    if (!writer.allocate() || !writer.writeActivitySummary({
        :shiftCount=>0, :timeOnIceMs=>0, :benchTimeMs=>0,
        :averageShiftMs=>null, :averageShiftHeartRate=>null,
        :zoneSeconds=>null, :overNinetySeconds=>null,
        :workRestTenths=>null, :shiftDensityPerHour=>null,
        :shortestShiftMs=>null, :longestShiftMs=>null,
        :medianShiftMs=>null, :topShiftHeartRates=>[]})) { return false; }
    if (session.fields[98].lastValue == session.fields[98].lastValue ||
        session.fields[78].lastValue != 255 ||
        session.fields[103].lastValue == session.fields[103].lastValue) { return false; }
    if (!writer.writePhaseLap({:phase=>:on_ice, :endedAtMs=>1000,
        :durationMs=>1000}, {:pushes=>null, :distanceCm=>null,
            :shortPushes=>null, :coveragePercent=>null})) { return false; }
    if (session.lapSnapshots[0][:pushes] != 65535 ||
        session.lapSnapshots[0][:distanceMetres] ==
            session.lapSnapshots[0][:distanceMetres] ||
        session.lapSnapshots[0][:coverage] != 255) { return false; }
    return writer.writePhaseLap({:phase=>:on_ice, :endedAtMs=>2000,
        :durationMs=>1000}, {:pushes=>0, :distanceCm=>0,
            :shortPushes=>0, :coveragePercent=>100}) &&
        session.lapSnapshots[1][:pushes] == 0 &&
        session.lapSnapshots[1][:distanceMetres] == 0.0 &&
        session.lapSnapshots[1][:coverage] == 100;
}

(:test)
function failedSecondShiftEstimateCannotReusePreviousLap(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(recorder, clock);
    var estimator = new FailingSecondEndEstimator();
    coordinator.setDistanceEstimator(estimator);
    if (!coordinator.start(:ice) || !coordinator.toggleShift()) { return false; }
    estimator.observe(distanceResult(1000, [pushAt(500, true)],
        0, true, false));
    clock.now = 2000;
    if (!coordinator.toggleShift()) { return false; }
    clock.now = 3000;
    if (!coordinator.toggleShift()) { return false; }
    clock.now = 4000;
    if (!coordinator.toggleShift()) { return false; }
    if (!coordinator.stopAndSave()) { return false; }
    return factory.session.lapSnapshots.size() == 3 &&
        factory.session.lapSnapshots[0][:pushes] == 1 &&
        factory.session.lapSnapshots[1][:phase].equals("Bench") &&
        factory.session.lapSnapshots[2][:pushes] == 65535;
}

(:test)
function unavailableSessionEstimateStaysUnknown(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var coordinator = new RecordingCoordinator(recorder, new ClockFake());
    if (!coordinator.start(:ice) || !coordinator.stopAndSave()) { return false; }
    var averageMinutes = factory.session.fields[98].lastValue;
    var distanceMetres = factory.session.fields[97].lastValue;
    return averageMinutes != averageMinutes && distanceMetres != distanceMetres &&
        factory.session.fields[78].lastValue == 255 &&
        factory.session.fields[103].lastValue != factory.session.fields[103].lastValue;
}

(:test)
function pushSummaryWriteFailureDoesNotPreventActivitySave(logger as Test.Logger) as Lang.Boolean {
    var factory = new FailingPushRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var coordinator = new RecordingCoordinator(recorder, new ClockFake());
    return coordinator.start(:ice) && coordinator.stopAndSave() &&
        factory.session.stops == 1 && factory.session.saves == 1 &&
        coordinator.getState() == :saved;
}

(:test)
function cumulativePushRecordsSurviveSkippedIntervals(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    if (!writer.allocate() || !writer.writeSecond(null, null, :on_ice,
        0, 1, 1000, {:totalPushes=>2, :totalDistanceCm=>250,
            :cadencePerMin=>12})) { return false; }
    if (session.fields[62].lastValue != 2 ||
        session.fields[110].lastValue != 2.5) { return false; }
    if (!writer.writeSecond(null, null, :on_ice, 0, 4, 4000,
        {:totalPushes=>8, :totalDistanceCm=>1400,
            :cadencePerMin=>null})) { return false; }
    return session.fields[62].lastValue == 8 &&
        session.fields[110].lastValue == 14.0;
}

(:test)
function manualLapMetricsDoNotLeakIntoAutomaticLap(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    if (!writer.allocate() || !writer.writePhaseLap({:phase=>:on_ice,
        :endedAtMs=>3000, :durationMs=>3000},
        {:pushes=>6, :distanceCm=>950, :shortPushes=>4,
            :coveragePercent=>80})) { return false; }
    if (!writer.writeAutoBoundary(3200, :on_ice)) { return false; }
    var manual = session.lapSnapshots[0];
    var automatic = session.lapSnapshots[1];
    return manual[:pushes] == 6 && manual[:distanceMetres] == 9.5 &&
        manual[:shortPushes] == 4 && manual[:coverage] == 80 &&
        automatic[:pushes] == 65535 &&
        automatic[:distanceMetres] != automatic[:distanceMetres] &&
        automatic[:phase].equals("") &&
        automatic[:shortPushes] == 65535 && automatic[:coverage] == 255;
}

(:test)
function openShiftPushSummaryIsLappedBeforeSessionStop(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(recorder, clock);
    if (!coordinator.start(:ice) || !coordinator.toggleShift()) { return false; }
    var estimator = new DistanceEstimator();
    estimator.beginShift(0);
    estimator.observe(distanceResult(1000, [pushAt(500, true)],
        0, true, false));
    coordinator.setDistanceEstimator(estimator);
    clock.now = 2000;
    if (!coordinator.stopAndSave()) { return false; }
    var lap = factory.session.lapSnapshots[0];
    return factory.session.stopLapCount == 0 &&
        lap[:manualState] == 1 && lap[:phase].equals("On-Ice") &&
        lap[:pushes] == 1 && lap[:distanceMetres] == 1.25 &&
        factory.session.fields[74].lastValue == 1 &&
        factory.session.fields[96].lastValue == 1 &&
        factory.session.fields[97].lastValue > 1.24 &&
        factory.session.fields[97].lastValue < 1.26;
}

(:test)
function inferredShiftBeforeManualStartWritesNoLap(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(recorder, clock);
    if (!coordinator.start(:ice)) { return false; }
    for (var i = 0; i < 10; i += 1) {
        clock.now = 1000 + i * 1000;
        coordinator.onMotionFeature({:valid=>true, :motionMg=>220,
            :rotationDps=>40, :periodic=>true});
    }
    if (factory.session.laps != 0 || coordinator.getDashboard()[:onIce] ||
        coordinator.getDashboard()[:shiftCount] != 0) { return false; }
    clock.now = 11000;
    return coordinator.stopAndSave() && factory.session.laps == 0 &&
        factory.session.fields[44].lastValue == 220;
}

(:test)
function inferredBoundariesBetweenManualPhasesWriteNoExtraLaps(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(recorder, clock);
    if (!coordinator.start(:ice) || !coordinator.toggleShift()) { return false; }
    for (var i = 0; i < 10; i += 1) {
        clock.now = 1000 + i * 1000;
        coordinator.onMotionFeature({:valid=>true, :motionMg=>220,
            :rotationDps=>40, :periodic=>true});
    }
    if (factory.session.laps != 0) { return false; }
    clock.now = 11000;
    if (!coordinator.toggleShift() || factory.session.laps != 1) { return false; }
    for (var j = 10; j < 30; j += 1) {
        clock.now = 1000 + j * 1000;
        coordinator.onMotionFeature({:valid=>true, :motionMg=>20,
            :rotationDps=>5, :periodic=>false});
    }
    if (factory.session.laps != 1 || coordinator.getDashboard()[:onIce]) { return false; }
    clock.now = 31000;
    if (!coordinator.toggleShift() || factory.session.laps != 2) { return false; }
    clock.now = 41000;
    return coordinator.stopAndSave() && factory.session.laps == 2 &&
        factory.session.lapSnapshots[0][:phase].equals("On-Ice") &&
        factory.session.lapSnapshots[1][:phase].equals("Bench") &&
        factory.session.lapSnapshots[2][:phase].equals("On-Ice");
}

(:test)
function coordinatorPhaseLapRetainsValidShortPushes(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(recorder, clock);
    var estimator = new DistanceEstimator();
    var config = new DistanceModelConfigFake();
    config.selectedMode = :fixed;
    coordinator.setDistanceEstimator(estimator);
    if (!coordinator.setDistanceModelConfig(config) || !coordinator.start(:ice) ||
        !coordinator.toggleShift()) { return false; }
    var times = [100, 700, 1300, 1900, 2500, 3100];
    for (var i = 0; i < times.size(); i += 1) {
        estimator.observe(distanceResult(times[i],
            [pushAt(times[i], i == 0)], times[i] - 100, true, false));
    }
    clock.now = 4200;
    if (!coordinator.toggleShift() || factory.session.laps != 1) { return false; }
    var lap = factory.session.lapSnapshots[0];
    if (!lap[:phase].equals("On-Ice") || lap[:pushes] != 6 ||
        lap[:shortPushes] != 4 || lap[:distanceMetres] != 9.5) { return false; }
    clock.now = 5000;
    if (!coordinator.toggleShift()) { return false; }
    clock.now = 6000;
    return coordinator.stopAndSave() && factory.session.laps == 2 &&
        factory.session.lapSnapshots[1][:shortPushes] == 65535 &&
        factory.session.lapSnapshots[2][:shortPushes] == 65535;
}

(:test)
function equalTimeTogglesPreservePhaseAndLedgerThroughSave(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(recorder, clock);
    if (!coordinator.start(:ice) || !coordinator.toggleShift()) { return false; }
    if (coordinator.toggleShift() || !coordinator.getDashboard()[:onIce] ||
        coordinator.getDashboard()[:shiftCount] != 1 || factory.session.laps != 0) {
        return false;
    }
    clock.now = 61000;
    if (!coordinator.toggleShift() || coordinator.toggleShift() ||
        coordinator.getDashboard()[:onIce] || factory.session.laps != 1) { return false; }
    clock.now = 60000;
    if (coordinator.toggleShift() || coordinator.getDashboard()[:onIce]) { return false; }
    clock.now = 121000;
    if (!coordinator.toggleShift() || coordinator.toggleShift() ||
        !coordinator.getDashboard()[:onIce] ||
        coordinator.getDashboard()[:shiftCount] != 2) { return false; }
    clock.now = 181000;
    if (!coordinator.stopAndSave() || factory.session.laps != 2) { return false; }
    var laps = factory.session.lapSnapshots;
    var summary = coordinator.getSessionSummary();
    return laps[0][:phase].equals("On-Ice") && laps[0][:durationMinutes] == 1.0 &&
        laps[1][:phase].equals("Bench") && laps[1][:durationMinutes] == 1.0 &&
        laps[2][:phase].equals("On-Ice") && laps[2][:durationMinutes] == 1.0 &&
        !coordinator.getDashboard()[:onIce] && summary[:shiftCount] == 2 &&
        summary[:timeOnIceMs] == 120000 && summary[:benchTimeMs] == 60000;
}

(:test)
function manualTogglesWriteAlternatingOnIceAndBenchLaps(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(recorder, clock);
    if (!coordinator.start(:ice) || !coordinator.toggleShift() ||
        factory.session.laps != 0) { return false; }
    clock.now = 10000;
    if (!coordinator.toggleShift() || factory.session.laps != 1) { return false; }
    clock.now = 20000;
    if (!coordinator.toggleShift() || factory.session.laps != 2) { return false; }
    clock.now = 30000;
    if (!coordinator.toggleShift() || factory.session.laps != 3) { return false; }
    return factory.session.lapSnapshots[0][:phase].equals("On-Ice") &&
        factory.session.lapSnapshots[1][:phase].equals("Bench") &&
        factory.session.lapSnapshots[2][:phase].equals("On-Ice");
}

(:test)
function saveOnIceClosesOneOnIceLap(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(recorder, clock);
    if (!coordinator.start(:ice) || !coordinator.toggleShift()) { return false; }
    clock.now = 12000;
    return coordinator.stopAndSave() && factory.session.laps == 0 &&
        factory.session.nativeFinalLap != null &&
        factory.session.lapSnapshots[0][:phase].equals("On-Ice");
}

(:test)
function saveOnBenchClosesOneBenchLap(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(recorder, clock);
    if (!coordinator.start(:ice) || !coordinator.toggleShift()) { return false; }
    clock.now = 10000;
    if (!coordinator.toggleShift() || factory.session.laps != 1) { return false; }
    clock.now = 18000;
    return coordinator.stopAndSave() && factory.session.laps == 1 &&
        factory.session.nativeFinalLap != null &&
        factory.session.lapSnapshots[1][:phase].equals("Bench");
}

(:test)
function saveBeforeFirstShiftWritesNoPhaseLap(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var coordinator = new RecordingCoordinator(recorder, new ClockFake());
    return coordinator.start(:ice) && coordinator.stopAndSave() &&
        factory.session.laps == 0 && factory.session.nativeFinalLap == null;
}

(:test)
function missingMotionAndHeartRateKeepPhaseAndDuration(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(recorder, clock);
    if (!coordinator.start(:ice) || !coordinator.toggleShift()) { return false; }
    clock.now = 61000;
    if (!coordinator.stopAndSave() || factory.session.laps != 0) { return false; }
    var lap = factory.session.lapSnapshots[0];
    return lap[:phase].equals("On-Ice") && lap[:durationMinutes] == 1.0 &&
        lap[:averageHeartRate] == 255 && lap[:pushes] == 65535 &&
        lap[:distanceMetres] != lap[:distanceMetres];
}

(:test)
function recoveryDeadlinesNeverCreateAdditionalLaps(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(recorder, clock);
    if (!coordinator.start(:ice) || !coordinator.toggleShift()) { return false; }
    clock.now = 10000;
    if (!coordinator.toggleShift() || factory.session.laps != 1) { return false; }
    clock.now = 75000;
    coordinator.onHeartRate({:heartRate=>120});
    if (factory.session.laps != 1) { return false; }
    return coordinator.stopAndSave() && factory.session.laps == 1 &&
        factory.session.lapSnapshots[1][:phase].equals("Bench");
}

(:test)
function activitySummaryWritesHockeyMetricsBeforeSave(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    if (!writer.allocate() || !writer.writeActivitySummary({
        :shiftCount=>3,
        :timeOnIceMs=>95000, :benchTimeMs=>205000,
        :averageShiftMs=>31666, :averageShiftHeartRate=>157,
        :zoneSeconds=>[11, 22, 33, 44, 55], :overNinetySeconds=>12,
        :workRestTenths=>5, :shiftDensityPerHour=>36,
        :shortestShiftMs=>28000, :longestShiftMs=>36000,
        :medianShiftMs=>31000, :topShiftHeartRates=>[181, 175, 169],
        :detectedPushes=>146, :estimatedDistanceCm=>22000,
        :personalCalibrationFactor=>0.7521
    })) { return false; }
    return session.fields.hasKey(96) && session.fields.hasKey(97) &&
        session.fields.hasKey(98) && session.fields[74].lastValue == 3 &&
        session.fields[101].lastValue > 1.583 && session.fields[101].lastValue < 1.584 &&
        session.fields[102].lastValue > 3.416 && session.fields[102].lastValue < 3.417 &&
        session.fields[98].lastValue > 0.527 && session.fields[98].lastValue < 0.529 &&
        session.fields[78].lastValue == 157 &&
        session.fields[96].lastValue == 146 && session.fields[97].lastValue == 220.0 &&
        session.fields[103].lastValue > 0.183 && session.fields[103].lastValue < 0.184 &&
        session.fields[107].lastValue > 0.916 && session.fields[107].lastValue < 0.917 &&
        session.fields[115].lastValue > 0.75209 && session.fields[115].lastValue < 0.75211 &&
        session.fields[85].lastValue == 5 &&
        session.fields[86].lastValue == 36 &&
        session.fields[109].lastValue > 0.516 && session.fields[109].lastValue < 0.517;
}

(:test)
function estimatedDistanceRemainsDeveloperSessionMetresAtCentimetrePrecision(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    if (!writer.allocate() || !writer.writeActivitySummary({
        :shiftCount=>1,
        :timeOnIceMs=>60000, :benchTimeMs=>0,
        :averageShiftMs=>60000, :averageShiftHeartRate=>150,
        :zoneSeconds=>[0, 0, 0, 60, 0], :overNinetySeconds=>0,
        :workRestTenths=>10, :shiftDensityPerHour=>60,
        :medianShiftMs=>60000, :detectedPushes=>9,
        :estimatedDistanceCm=>12345
    })) { return false; }
    return session.fieldScopes[97] == FitContributor.MESG_TYPE_SESSION &&
        session.fieldNativeNums[97] == null &&
        session.fields[97].lastValue == 123.45;
}

(:test)
function schemaTwelveWritesMinuteSessionFields(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    if (!writer.allocate() || !writer.writeActivitySummary({
        :shiftCount=>1, :timeOnIceMs=>95000, :benchTimeMs=>0,
        :averageShiftMs=>95000, :averageShiftHeartRate=>150,
        :zoneSeconds=>[0, 30, 60, 90, 120], :overNinetySeconds=>45,
        :workRestTenths=>1, :shiftDensityPerHour=>1,
        :medianShiftMs=>95000, :detectedPushes=>0,
        :estimatedDistanceCm=>0, :personalCalibrationFactor=>1.125
    })) { return false; }
    if (session.fields[73].lastValue != 12 ||
        session.fields[101].lastValue < 1.583 || session.fields[101].lastValue > 1.584 ||
        session.fields[102].lastValue != 0.0 ||
        session.fields[103].lastValue != 0.0 ||
        session.fields[104].lastValue != 0.5 ||
        session.fields[105].lastValue != 1.0 ||
        session.fields[115].lastValue != 1.125 ||
        session.fields[109].lastValue < 1.583 || session.fields[109].lastValue > 1.584) {
        return false;
    }
    return !session.fields.hasKey(75) && !session.fields.hasKey(76) &&
        !session.fields.hasKey(79) && !session.fields.hasKey(84) &&
        !session.fields.hasKey(89);
}

(:test)
function savedSummaryRejectsSparseShiftHeartRate(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(recorder, clock);
    if (!coordinator.start(:ice) || !coordinator.toggleShift()) { return false; }
    coordinator.onHeartRate({:heartRate=>100});
    coordinator.onHeartRate({:heartRate=>140});
    clock.now = 31000;
    if (!coordinator.toggleShift()) { return false; }
    clock.now = 61000;
    if (!coordinator.toggleShift()) { return false; }
    coordinator.onHeartRate({:heartRate=>160});
    clock.now = 91000;
    if (!coordinator.toggleShift() || !coordinator.stopAndSave()) { return false; }
    return factory.session.fields[74].lastValue == 2 &&
        factory.session.fields[101].lastValue == 1.0 &&
        factory.session.fields[102].lastValue == 0.5 &&
        factory.session.fields[98].lastValue == 0.5 &&
        factory.session.fields[78].lastValue == 255;
}

(:test)
function transitionalShiftLapWritesOnIceWithoutRecoveryFields(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    if (!writer.allocate() || session.fields.hasKey(93) || session.fields.hasKey(94) ||
        !writer.writeShiftLap({:endedAtMs=>12000, :durationMs=>10000,
        :heartRateDrop30=>-7, :heartRateDrop60=>22,
        :averageHeartRate=>181}, null)) { return false; }
    return session.lapSnapshots[0][:phase].equals("On-Ice") &&
        session.lapSnapshots[0][:averageHeartRate] == 181 &&
        session.lapSnapshots[0][:durationMinutes] > 0.166 &&
        session.lapSnapshots[0][:durationMinutes] < 0.167;
}

(:test)
function transitionalShiftLapWithoutValidMotionWritesInvalidMetrics(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    if (!recorder.start(:ice) || !recorder.writeShiftLap(
        {:endedAtMs=>12000, :durationMs=>10000, :averageHeartRate=>181},
        {:hasValidMotion=>false, :pushes=>0, :distanceCm=>0,
            :shortPushes=>0, :coveragePercent=>0})) { return false; }
    var lap = factory.session.lapSnapshots[0];
    return lap[:phase].equals("On-Ice") &&
        lap[:averageHeartRate] == 181 &&
        lap[:pushes] == 65535 &&
        lap[:distanceMetres] != lap[:distanceMetres] &&
        lap[:shortPushes] == 65535 && lap[:coverage] == 255;
}

(:test)
function transitionalShiftLapPreservesShortPushesWithValidMotion(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    if (!recorder.start(:ice) || !recorder.writeShiftLap(
        {:endedAtMs=>12000, :durationMs=>10000, :averageHeartRate=>181},
        {:hasValidMotion=>true, :pushes=>6, :distanceCm=>950,
            :shortPushes=>4, :coveragePercent=>80})) { return false; }
    var lap = factory.session.lapSnapshots[0];
    return lap[:pushes] == 6 && lap[:distanceMetres] == 9.5 &&
        lap[:shortPushes] == 4 && lap[:coverage] == 80;
}

(:test)
function summaryOverflowUsesMissingInsteadOfClamping(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    if (!writer.allocate() || !writer.writeActivitySummary({
        :shiftCount=>255, :timeOnIceMs=>65535000, :benchTimeMs=>-1,
        :averageShiftMs=>65535000, :averageShiftHeartRate=>255,
        :zoneSeconds=>[65535, 0, 1, 2, 3], :overNinetySeconds=>65535,
        :workRestTenths=>255, :shiftDensityPerHour=>255,
        :shortestShiftMs=>65535000, :longestShiftMs=>0,
        :medianShiftMs=>1000, :topShiftHeartRates=>[255]
    })) { return false; }
    return session.fields[74].lastValue == 255 &&
        session.fields[101].lastValue > 1092.24 &&
        session.fields[101].lastValue < 1092.26 &&
        session.fields[102].lastValue != session.fields[102].lastValue &&
        session.fields[98].lastValue > 1092.24 &&
        session.fields[98].lastValue < 1092.26 &&
        session.fields[78].lastValue == 255 &&
        session.fields[103].lastValue > 1092.24 &&
        session.fields[103].lastValue < 1092.26;
}

(:test)
function manualShiftLapWritesImmediatelyWithoutRecoveryDuplicate(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(recorder, clock);
    if (!coordinator.start(:ice) || !coordinator.toggleShift()) { return false; }
    clock.now = 11000;
    if (!coordinator.toggleShift() || factory.session.laps != 1 ||
        !factory.session.lapSnapshots[0][:phase].equals("On-Ice")) { return false; }
    clock.now = 76000;
    if (!coordinator.stopAndSave()) { return false; }
    return factory.session.laps == 1 && factory.session.stopLapCount == 1 &&
        factory.session.lapSnapshots[1][:phase].equals("Bench") &&
        factory.session.fields[51].lastValue == 75000;
}

(:test)
function saveRetryNeverDuplicatesFinalPhaseLap(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    factory.session.saveResult = false;
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(recorder, clock);
    if (!coordinator.start(:ice) || !coordinator.toggleShift()) { return false; }
    clock.now = 11000;
    if (coordinator.stopAndSave() || factory.session.laps != 0) { return false; }
    factory.session.saveResult = true;
    return coordinator.retrySave() && factory.session.laps == 0 &&
        factory.session.lapSnapshots.size() == 1 &&
        factory.session.stops == 1 && factory.session.saves == 2;
}

(:test)
function autoBoundaryUsesDurableLapAndFreshSampleIds(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    if (!writer.allocate()) { return false; }
    if (!writer.writeSecond({:valid=>true, :motionMg=>220,
        :rotationDps=>40}, {:state=>:on_ice, :confidence=>80},
        :bench, 4, 1, 1000, null)) { return false; }
    return session.fields[62].lastValue == null &&
        writer.writeAutoBoundary(0, :on_ice) &&
        session.lastAutoBoundaryMs == 0 && session.fields[55].lastValue == 0 &&
        session.fields[56].lastValue == 0;
}

(:test)
function optionalWriterFailureDoesNotLoseActivity(logger as Test.Logger) as Lang.Boolean {
    var factory = new RecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new FailingShadowWriterFactoryFake());
    return recorder.start(:ice) && recorder.stopAndSave() &&
        recorder.getState() == :saved && factory.session.saves == 1;
}

(:test)
function manualBoundaryWriteFailureDoesNotBlockShift(logger as Test.Logger) as Lang.Boolean {
    var factory = new FailingLapRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var coordinator = new RecordingCoordinator(
        recorder, new ClockFake());
    coordinator.start(:ice);
    return coordinator.toggleShift() &&
        coordinator.getDashboard()[:shiftCount] == 1 &&
        coordinator.stopAndSave() && factory.session.saves == 1;
}

(:test)
function realShadowSessionStartsAndSaves(logger as Test.Logger) as Lang.Boolean {
    var recorder = new SessionRecorder(new SystemSessionFactory());
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    if (!recorder.start(:ice)) { return false; }
    recorder.writeShadowSecond({:valid=>true, :motionMg=>200,
        :rotationDps=>40}, {:state=>:on_ice, :confidence=>80},
        :on_ice, 0, 1, 1000, null);
    recorder.writeManualBoundary(1000, :on_ice, null);
    if (!recorder.writeActivitySummary({
        :shiftCount=>0, :timeOnIceMs=>0, :benchTimeMs=>1000,
        :averageShiftMs=>null, :averageShiftHeartRate=>null,
        :zoneSeconds=>null, :overNinetySeconds=>null,
        :workRestTenths=>null, :shiftDensityPerHour=>null,
        :shortestShiftMs=>null, :longestShiftMs=>null,
        :medianShiftMs=>null, :topShiftHeartRates=>[]})) { return false; }
    return recorder.stopAndSave() && recorder.getState() == :saved;
}

(:test)
function realShadowFieldsAllocate(logger as Test.Logger) as Lang.Boolean {
    var session = (new SystemSessionFactory()).createSession({
        :name=>"ShiftSense FIT Test", :sport=>Activity.SPORT_GENERIC});
    if (session == null) { return false; }
    var allocated = (new ShadowFitWriter(session)).allocate();
    session.discard();
    return allocated;
}

(:test)
function realUint32FieldAcceptsFitInvalidLong(logger as Test.Logger) as Lang.Boolean {
    var session = (new SystemSessionFactory()).createSession({
        :name=>"ShiftSense FIT Invalid Test", :sport=>Activity.SPORT_GENERIC});
    if (session == null) { return false; }
    var accepted = true;
    try {
        var field = session.createField("invalid_uint32", 90,
            FitContributor.DATA_TYPE_UINT32,
            {:mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"cm"});
        field.setData(4294967295l);
    } catch (ex) { accepted = false; }
    session.discard();
    return accepted;
}
