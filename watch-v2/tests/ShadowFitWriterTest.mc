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
    var fields = {};
    var laps = 0;
    var lapSnapshots = [];
    var stopLapCount = null;
    var lastBoundaryMs = null;
    var lastAutoBoundaryMs = null;
    function createField(name, id, type, options) {
        fieldIds.add(id);
        fieldNames[id] = name;
        fieldTypes[id] = type;
        fieldScopes[id] = options[:mesgType];
        fieldUnits[id] = options[:units];
        var field = new ShadowFieldFake();
        fields[id] = field;
        return field;
    }
    function addLap() {
        laps += 1;
        lastBoundaryMs = fields[51].lastValue;
        if (fields.hasKey(55)) { lastAutoBoundaryMs = fields[55].lastValue; }
        lapSnapshots.add({:manualState=>fields[52].lastValue,
            :autoState=>fields.hasKey(56) ? fields[56].lastValue : null,
            :pushes=>fields.hasKey(65) ? fields[65].lastValue : null,
            :distance=>fields.hasKey(66) ? fields[66].lastValue : null,
            :shortPushes=>fields.hasKey(71) ? fields[71].lastValue : null,
            :coverage=>fields.hasKey(72) ? fields[72].lastValue : null,
            :drop30=>fields.hasKey(93) ? fields[93].lastValue : null,
            :drop60=>fields.hasKey(94) ? fields[94].lastValue : null,
            :averageHeartRate=>fields.hasKey(95) ? fields[95].lastValue : null});
        return true;
    }
    function stop() as Lang.Boolean {
        stopLapCount = laps;
        stops += 1;
        return stopResult;
    }
}
class FailingPushShadowSessionFake extends ShadowSessionFake {
    function createField(name, id, type, options) {
        var field = ShadowSessionFake.createField(name, id, type, options);
        if (id == 75) {
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

(:test)
function shadowWriterUsesOnlyNewStableFieldIds(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    var expected = [51, 52, 55, 56, 62, 63, 65, 66, 71, 72,
        73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86,
        87, 88, 89, 93, 94, 95];
    if (!writer.allocate() || session.fieldIds.size() != 30) { return false; }
    for (var i = 0; i < expected.size(); i += 1) {
        if (session.fieldIds[i] != expected[i]) { return false; }
    }
    return session.fieldNames[73].equals("summary_schema_version") &&
        session.fieldNames[78].equals("average_shift_heart_rate") &&
        session.fieldNames[62].equals("push_count_total") &&
        session.fieldNames[95].equals("shift_average_heart_rate") &&
        session.fieldTypes[62] == FitContributor.DATA_TYPE_UINT32 &&
        session.fieldTypes[74] == FitContributor.DATA_TYPE_UINT8 &&
        session.fieldTypes[75] == FitContributor.DATA_TYPE_UINT16 &&
        session.fieldTypes[77] == FitContributor.DATA_TYPE_UINT8 &&
        session.fieldTypes[93] == FitContributor.DATA_TYPE_SINT16 &&
        session.fieldScopes[62] == FitContributor.MESG_TYPE_RECORD &&
        session.fieldScopes[65] == FitContributor.MESG_TYPE_LAP &&
        session.fieldScopes[73] == FitContributor.MESG_TYPE_RECORD &&
        session.fieldScopes[84] == FitContributor.MESG_TYPE_SESSION &&
        session.fieldScopes[93] == FitContributor.MESG_TYPE_LAP &&
        session.fields[73].lastValue == 7 &&
        writer.writeManualBoundary(12000, :on_ice, null) && session.laps == 1 &&
        session.lastBoundaryMs == 12000 && session.fields[51].lastValue == 0 &&
        session.fields[52].lastValue == 0;
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
    if (session.fields[77].lastValue != 255 ||
        session.fields[78].lastValue != 255 ||
        session.fields[79].lastValue != 65535) { return false; }
    if (!writer.writeManualBoundary(1000, :bench,
        {:pushes=>0, :distanceCm=>0, :shortPushes=>0,
            :coveragePercent=>0, :hasValidMotion=>false})) { return false; }
    if (session.lapSnapshots[0][:pushes] != 65535 ||
        session.lapSnapshots[0][:distance] != 4294967295l ||
        session.lapSnapshots[0][:coverage] != 255) { return false; }
    return writer.writeManualBoundary(2000, :bench,
        {:pushes=>0, :distanceCm=>0, :shortPushes=>0,
            :coveragePercent=>100, :hasValidMotion=>true}) &&
        session.lapSnapshots[1][:pushes] == 0 &&
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
    if (!coordinator.start() || !coordinator.toggleShift()) { return false; }
    estimator.observe(distanceResult(1000, [pushAt(500, true)],
        0, true, false));
    clock.now = 2000;
    if (!coordinator.toggleShift()) { return false; }
    clock.now = 3000;
    if (!coordinator.toggleShift()) { return false; }
    clock.now = 4000;
    if (!coordinator.toggleShift()) { return false; }
    if (!coordinator.stopAndSave()) { return false; }
    return factory.session.lapSnapshots.size() == 2 &&
        factory.session.lapSnapshots[0][:pushes] == 1 &&
        factory.session.lapSnapshots[1][:pushes] == 65535;
}

(:test)
function unavailableSessionEstimateStaysUnknown(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var coordinator = new RecordingCoordinator(recorder, new ClockFake());
    return coordinator.start() && coordinator.stopAndSave() &&
        factory.session.fields[77].lastValue == 255 &&
        factory.session.fields[78].lastValue == 255 &&
        factory.session.fields[79].lastValue == 65535;
}

(:test)
function pushSummaryWriteFailureDoesNotPreventActivitySave(logger as Test.Logger) as Lang.Boolean {
    var factory = new FailingPushRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var coordinator = new RecordingCoordinator(recorder, new ClockFake());
    return coordinator.start() && coordinator.stopAndSave() &&
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
        session.fields[63].lastValue != 250) { return false; }
    if (!writer.writeSecond(null, null, :on_ice, 0, 4, 4000,
        {:totalPushes=>8, :totalDistanceCm=>1400,
            :cadencePerMin=>null})) { return false; }
    return session.fields[62].lastValue == 8 &&
        session.fields[63].lastValue == 1400;
}

(:test)
function manualLapMetricsDoNotLeakIntoAutomaticLap(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    if (!writer.allocate() || !writer.writeManualBoundary(3000, :bench,
        {:pushes=>6, :distanceCm=>950, :shortPushes=>4,
            :coveragePercent=>80, :hasValidMotion=>true})) { return false; }
    if (!writer.writeAutoBoundary(3200, :on_ice)) { return false; }
    var manual = session.lapSnapshots[0];
    var automatic = session.lapSnapshots[1];
    return manual[:pushes] == 6 && manual[:distance] == 950 &&
        manual[:shortPushes] == 4 && manual[:coverage] == 80 &&
        automatic[:pushes] == 65535 && automatic[:distance] == 4294967295l &&
        automatic[:shortPushes] == 65535 && automatic[:coverage] == 255;
}

(:test)
function openShiftPushSummaryIsLappedBeforeSessionStop(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(recorder, clock);
    if (!coordinator.start() || !coordinator.toggleShift()) { return false; }
    var estimator = new DistanceEstimator();
    estimator.beginShift(0);
    estimator.observe(distanceResult(1000, [pushAt(500, true)],
        0, true, false));
    coordinator.setDistanceEstimator(estimator);
    clock.now = 2000;
    if (!coordinator.stopAndSave()) { return false; }
    var lap = factory.session.lapSnapshots[0];
    return factory.session.stopLapCount == 1 &&
        lap[:manualState] == 2 && lap[:pushes] == 1 &&
        lap[:distance] == 125 && factory.session.fields[74].lastValue == 1;
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
        :medianShiftMs=>31000, :topShiftHeartRates=>[181, 175, 169]
    })) { return false; }
    return session.fields[74].lastValue == 3 &&
        session.fields[75].lastValue == 95 && session.fields[76].lastValue == 205 &&
        session.fields[77].lastValue == 31 && session.fields[78].lastValue == 157 &&
        session.fields[79].lastValue == 11 && session.fields[83].lastValue == 55 &&
        session.fields[84].lastValue == 12 && session.fields[85].lastValue == 5 &&
        session.fields[86].lastValue == 36 && session.fields[87].lastValue == 28 &&
        session.fields[88].lastValue == 36 && session.fields[89].lastValue == 31;
}

(:test)
function savedSummaryRejectsSparseShiftHeartRate(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(recorder, clock);
    if (!coordinator.start() || !coordinator.toggleShift()) { return false; }
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
        factory.session.fields[75].lastValue == 60 &&
        factory.session.fields[76].lastValue == 30 &&
        factory.session.fields[77].lastValue == 30 &&
        factory.session.fields[78].lastValue == 255;
}

(:test)
function recoveryLapWritesSignedValuesAndMissingSentinels(logger as Test.Logger) as Lang.Boolean {
    var session = new ShadowSessionFake();
    var writer = new ShadowFitWriter(session);
    if (!writer.allocate() || !writer.writeShiftLap({:endedAtMs=>12000,
        :heartRateDrop30=>-7, :heartRateDrop60=>22,
        :averageHeartRate=>181}, null)) { return false; }
    if (session.lapSnapshots[0][:drop30] != -7 ||
        session.lapSnapshots[0][:drop60] != 22 ||
        session.lapSnapshots[0][:averageHeartRate] != 181) { return false; }
    return writer.writeShiftLap({:endedAtMs=>13000,
        :heartRateDrop30=>null, :heartRateDrop60=>40000,
        :averageHeartRate=>null}, null) &&
        session.lapSnapshots[1][:drop30] == 32767 &&
        session.lapSnapshots[1][:drop60] == 32767 &&
        session.lapSnapshots[1][:averageHeartRate] == 255;
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
        session.fields[75].lastValue == 65535 &&
        session.fields[76].lastValue == 65535 &&
        session.fields[77].lastValue == 255 &&
        session.fields[78].lastValue == 255 &&
        session.fields[79].lastValue == 65535;
}

(:test)
function manualShiftLapWaitsForRecoveryAndWritesOnce(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(recorder, clock);
    if (!coordinator.start() || !coordinator.toggleShift()) { return false; }
    clock.now = 11000;
    if (!coordinator.toggleShift() || factory.session.laps != 0) { return false; }
    clock.now = 76000;
    if (!coordinator.stopAndSave()) { return false; }
    return factory.session.laps == 1 && factory.session.stopLapCount == 1 &&
        factory.session.lastBoundaryMs == 10000;
}

(:test)
function saveRetryNeverDuplicatesDelayedShiftLap(logger as Test.Logger) as Lang.Boolean {
    var factory = new ShadowRecordingFactoryFake();
    factory.session.saveResult = false;
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(recorder, clock);
    if (!coordinator.start() || !coordinator.toggleShift()) { return false; }
    clock.now = 11000;
    if (coordinator.stopAndSave() || factory.session.laps != 1) { return false; }
    factory.session.saveResult = true;
    return coordinator.retrySave() && factory.session.laps == 1 &&
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
    return recorder.start() && recorder.stopAndSave() &&
        recorder.getState() == :saved && factory.session.saves == 1;
}

(:test)
function manualBoundaryWriteFailureDoesNotBlockShift(logger as Test.Logger) as Lang.Boolean {
    var factory = new FailingLapRecordingFactoryFake();
    var recorder = new SessionRecorder(factory);
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    var coordinator = new RecordingCoordinator(
        recorder, new ClockFake());
    coordinator.start();
    return coordinator.toggleShift() &&
        coordinator.getDashboard()[:shiftCount] == 1 &&
        coordinator.stopAndSave() && factory.session.saves == 1;
}

(:test)
function realShadowSessionStartsAndSaves(logger as Test.Logger) as Lang.Boolean {
    var recorder = new SessionRecorder(new SystemSessionFactory());
    recorder.setShadowWriterFactory(new SystemShadowWriterFactory());
    if (!recorder.start()) { return false; }
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
