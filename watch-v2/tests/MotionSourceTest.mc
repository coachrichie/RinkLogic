using Toybox.Lang;
using Toybox.Test as Test;

class MotionPortFake {
    var registered = 0;
    var unregistered = 0;
    var accelRate = 25;
    var gyroRate = 0;
    var lastOptions = null;
    function maxRate(type) { return type == :accelerometer ? accelRate : gyroRate; }
    function register(listener, options) {
        registered += 1;
        lastOptions = options;
        return true;
    }
    function unregister() { unregistered += 1; }
}

class MotionPortUnavailableFake extends MotionPortFake {
    function maxRate(type) { return 0; }
    function register(listener, options) { return false; }
}

class MotionListenerFake {
    var lastFeature = null;
    function onFeature(feature) as Void { lastFeature = feature; }
}

class MotionAxisDataFake {
    var x;
    var y;
    var z;
    var timestamp;
    function initialize(xValues, yValues, zValues, times) {
        x = xValues; y = yValues; z = zValues; timestamp = times;
    }
}

class MotionAxisDataWithoutTimestampFake {
    var x;
    var y;
    var z;
    function initialize(xValues, yValues, zValues) {
        x = xValues; y = yValues; z = zValues;
    }
}

class MotionSensorDataFake {
    var accelerometerData;
    var gyroscopeData;
    function initialize(accel, gyro) {
        accelerometerData = accel; gyroscopeData = gyro;
    }
}

class ThrowingPushDetectorFake {
    function push(batch, atMs) { throw new Lang.Exception(); }
    function reset() as Void { }
}

function motionFeatureWithBatch(batch) as Lang.Dictionary {
    return {:valid=>false, :motionMg=>null, :rotationDps=>null,
        :periodic=>false, :pushBatch=>batch};
}

(:test)
function coordinatorCountsHockeyPushesOnlyDuringManualShift(logger as Test.Logger) as Lang.Boolean {
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), clock);
    if (!coordinator.start() || !coordinator.toggleShift()) { return false; }
    clock.now = 2000;
    coordinator.onMotionFeature(motionFeatureWithBatch(detectorBatch(
        [0, 100, 200, 300, 400, 500, 600, 700, 800, 900], [100, 700])));
    clock.now = 3000;
    coordinator.onMotionFeature(motionFeatureWithBatch(detectorBatch(
        [1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900],
        [1300])));
    var onIce = coordinator.getDashboard();
    if (onIce[:shiftCount] != 1 || onIce[:totalPushes] != 3 ||
        onIce[:totalDistanceCm] != 375) { return false; }
    coordinator.toggleShift();
    clock.now = 4000;
    coordinator.onMotionFeature(motionFeatureWithBatch(detectorBatch(
        [2000, 2100, 2200, 2300, 2400, 2500, 2600, 2700, 2800, 2900],
        [2500])));
    var bench = coordinator.getDashboard();
    return bench[:shiftCount] == 1 && bench[:totalPushes] == 3 &&
        bench[:totalDistanceCm] == 375 && coordinator.stopAndSave();
}

(:test)
function delayedConfirmationFiltersEventsBeforeShiftStart(logger as Test.Logger) as Lang.Boolean {
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), clock);
    if (!coordinator.start()) { return false; }
    clock.now = 2000;
    coordinator.onMotionFeature(motionFeatureWithBatch(detectorBatch(
        [0, 100, 200, 300, 400, 500, 600, 700, 800, 900], [100, 700])));
    clock.now = 2500;
    coordinator.toggleShift();
    clock.now = 3000;
    coordinator.onMotionFeature(motionFeatureWithBatch(detectorBatch(
        [1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900],
        [1700])));
    var dashboard = coordinator.getDashboard();
    return dashboard[:totalPushes] == 1 &&
        dashboard[:totalDistanceCm] == 225 && coordinator.stopAndSave();
}

(:test)
function failedPushAnalysisDoesNotStopHrShiftsOrSave(logger as Test.Logger) as Lang.Boolean {
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), clock);
    coordinator.setPushDetector(new ThrowingPushDetectorFake());
    if (!coordinator.start() || !coordinator.toggleShift()) { return false; }
    coordinator.onHeartRate({:heartRate=>155});
    coordinator.onMotionFeature(motionFeatureWithBatch(null));
    var dashboard = coordinator.getDashboard();
    return dashboard[:heartRate] == 155 && dashboard[:shiftCount] == 1 &&
        dashboard[:totalDistanceCm] == 0 && coordinator.stopAndSave();
}

(:test)
function rawPushBatchRetainsTimestamps(logger as Test.Logger) as Lang.Boolean {
    var port = new MotionPortFake();
    port.gyroRate = 10;
    var source = new MotionSource(port);
    var listener = new MotionListenerFake();
    if (!source.start(listener.method(:onFeature))) { return false; }
    var accel = new MotionAxisDataFake([0, 220, 0, 220, 0],
        [0, 0, 0, 0, 0], [1000, 1000, 1000, 1000, 1000],
        [100, 200, 300, 400, 500]);
    var gyro = new MotionAxisDataFake([0, 55], [0, 0], [0, 0], [190, 300]);
    source.onData(new MotionSensorDataFake(accel, gyro));
    source.stop();
    var feature = listener.lastFeature;
    if (feature == null || !feature.hasKey(:pushBatch) ||
        feature[:pushBatch] == null) { return false; }
    var batch = feature[:pushBatch];
    return port.registered == 1 && port.unregistered == 1 &&
        port.lastOptions[:accelerometer][:includeTimestamps] &&
        port.lastOptions[:gyroscope][:includeTimestamps] &&
        batch[:ax] == accel.x && batch[:gyroTimes] == gyro.timestamp &&
        batch[:accelTimes] == accel.timestamp && feature[:motionMg] != null;
}

(:test)
function missingAccelerationTimestampUsesEstimatedPushTimebase(logger as Test.Logger) as Lang.Boolean {
    var port = new MotionPortFake();
    port.gyroRate = 10;
    var source = new MotionSource(port);
    var listener = new MotionListenerFake();
    if (!source.start(listener.method(:onFeature))) { return false; }
    var accel = new MotionAxisDataWithoutTimestampFake(
        [0, 220, 0, 220, 0], [0, 0, 0, 0, 0],
        [1000, 1000, 1000, 1000, 1000]);
    var gyro = new MotionAxisDataFake([0, 55, 0, 55, 0],
        [0, 0, 0, 0, 0], [0, 0, 0, 0, 0],
        [100, 200, 300, 400, 500]);
    source.onData(new MotionSensorDataFake(accel, gyro));
    source.stop();
    var feature = listener.lastFeature;
    return feature != null && feature[:valid] &&
        feature[:motionMg] != null && feature[:pushBatch] != null &&
        feature[:pushBatch][:timebase] == :estimated &&
        feature[:pushBatch][:accelTimes].size() == 5 &&
        feature[:pushBatch][:gyroTimes].size() == 5;
}

(:test)
function missingGyroscopeTimestampUsesEstimatedPushTimebase(logger as Test.Logger) as Lang.Boolean {
    var port = new MotionPortFake();
    port.gyroRate = 10;
    var source = new MotionSource(port);
    var listener = new MotionListenerFake();
    if (!source.start(listener.method(:onFeature))) { return false; }
    var accel = new MotionAxisDataFake([0, 220, 0, 220, 0],
        [0, 0, 0, 0, 0], [1000, 1000, 1000, 1000, 1000],
        [100, 200, 300, 400, 500]);
    var gyro = new MotionAxisDataWithoutTimestampFake(
        [0, 55, 0, 55, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0]);
    source.onData(new MotionSensorDataFake(accel, gyro));
    source.stop();
    var feature = listener.lastFeature;
    return feature != null && feature[:valid] &&
        feature[:motionMg] != null && feature[:pushBatch] != null &&
        feature[:pushBatch][:timebase] == :estimated;
}

(:test)
function timestampFreeSensorPacketsProduceRhythmicPushes(logger as Test.Logger) as Lang.Boolean {
    var port = new MotionPortFake();
    port.gyroRate = 10;
    var source = new MotionSource(port);
    var listener = new MotionListenerFake();
    var detector = new PushDetector();
    if (!source.start(listener.method(:onFeature))) { return false; }
    var allValid = true;
    var lastResult = null;
    for (var second = 0; second < 3; second += 1) {
        var az = [1000, 1000, 1000, 1000, 1000,
            1000, 1000, 1000, 1000, 1000];
        var gz = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        az[2] = 1220;
        gz[2] = 60;
        source.onData(new MotionSensorDataFake(
            new MotionAxisDataWithoutTimestampFake(
                [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                [0, 0, 0, 0, 0, 0, 0, 0, 0, 0], az),
            new MotionAxisDataWithoutTimestampFake(
                [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                [0, 0, 0, 0, 0, 0, 0, 0, 0, 0], gz)));
        var feature = listener.lastFeature;
        if (feature == null || feature[:pushBatch] == null) { return false; }
        lastResult = detector.push(feature[:pushBatch],
            (second + 1) * 1000);
        if (!lastResult[:sensorValid]) { allValid = false; }
    }
    source.stop();
    return allValid && lastResult != null &&
        lastResult[:timebase] == :estimated &&
        lastResult[:events].size() == 3;
}

(:test)
function absentGyroYieldsNullPushBatchButValidMotion(logger as Test.Logger) as Lang.Boolean {
    var port = new MotionPortFake();
    var source = new MotionSource(port);
    var listener = new MotionListenerFake();
    if (!source.start(listener.method(:onFeature))) { return false; }
    var accel = new MotionAxisDataFake([0, 200, 0, 200, 0],
        [0, 0, 0, 0, 0], [1000, 1000, 1000, 1000, 1000],
        [100, 200, 300, 400, 500]);
    source.onData(new MotionSensorDataFake(accel, null));
    source.stop();
    var feature = listener.lastFeature;
    return port.registered == 1 && feature != null &&
        feature[:valid] && feature[:motionMg] != null &&
        feature.hasKey(:pushBatch) && feature[:pushBatch] == null;
}

(:test)
function absentGyroStillRegistersAcceleration(logger as Test.Logger) as Lang.Boolean {
    var port = new MotionPortFake();
    var source = new MotionSource(port);
    var listener = new MotionListenerFake();
    if (!source.start(listener.method(:onFeature))) { return false; }
    source.stop();
    return port.registered == 1 && port.unregistered == 1 &&
        port.lastOptions[:accelerometer][:sampleRate] == 10 &&
        !port.lastOptions.hasKey(:gyroscope);
}

(:test)
function failedMotionStartKeepsManualRecording(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    coordinator.setMotionSource(new MotionSource(new MotionPortUnavailableFake()));
    return coordinator.start() && coordinator.toggleShift() &&
        coordinator.getDashboard()[:shiftCount] == 1 &&
        coordinator.stopAndSave();
}

(:test)
function shadowProposalsNeverChangeLiveShiftCount(logger as Test.Logger) as Lang.Boolean {
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), clock);
    if (!coordinator.start()) { return false; }
    for (var i = 0; i < 10; i += 1) {
        clock.now = 1000 + i*1000;
        coordinator.onMotionFeature({:valid=>true, :motionMg=>220,
            :rotationDps=>40, :periodic=>true});
    }
    return coordinator.getDashboard()[:shiftCount] == 0 &&
        coordinator.getDashboard()[:timeOnIceMs] == 0 &&
        coordinator.stopAndSave();
}
