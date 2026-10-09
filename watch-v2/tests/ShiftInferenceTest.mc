using Toybox.Lang;
using Toybox.Test as Test;

(:test)
function oneActiveSecondDoesNotStartShift(logger as Test.Logger) as Lang.Boolean {
    var detector = new ShiftInference();
    return detector.push({:valid=>true, :motionMg=>200,
        :rotationDps=>40, :periodic=>true}, 1000) == null &&
        detector.state() == :no_shift;
}

(:test)
function sustainedMotionCreatesOneProposal(logger as Test.Logger) as Lang.Boolean {
    var detector = new ShiftInference();
    var hits = 0;
    for (var i = 0; i < 10; i += 1) {
        if (detector.push({:valid=>true, :motionMg=>220,
            :rotationDps=>40, :periodic=>true}, i*1000) != null) { hits += 1; }
    }
    return hits == 1 && detector.state() == :on_ice;
}

(:test)
function sensorGapCannotCreateBenchProposal(logger as Test.Logger) as Lang.Boolean {
    var detector = new ShiftInference();
    for (var i = 0; i < 10; i += 1) {
        detector.push({:valid=>true, :motionMg=>220,
            :rotationDps=>40, :periodic=>true}, i*1000);
    }
    for (var j = 10; j < 30; j += 1) {
        if (detector.push({:valid=>false}, j*1000) != null) { return false; }
    }
    return detector.state() == :uncertain;
}

(:test)
function briefMotionOnBenchDoesNotStartShift(logger as Test.Logger) as Lang.Boolean {
    var detector = new ShiftInference();
    for (var i = 0; i < 10; i += 1) {
        detector.push({:valid=>true, :motionMg=>220,
            :rotationDps=>40, :periodic=>true}, i*1000);
    }
    for (var j = 10; j < 30; j += 1) {
        detector.push({:valid=>true, :motionMg=>20,
            :rotationDps=>5, :periodic=>false}, j*1000);
    }
    if (detector.state() != :bench) { return false; }
    for (var k = 30; k < 32; k += 1) {
        if (detector.push({:valid=>true, :motionMg=>220,
            :rotationDps=>40, :periodic=>true}, k*1000) != null) { return false; }
    }
    return detector.state() == :bench;
}

(:test)
function proposalUsesEstimatedMovementOnset(logger as Test.Logger) as Lang.Boolean {
    var detector = new ShiftInference();
    var iceAt = null;
    var benchAt = null;
    for (var i = 0; i < 10; i += 1) {
        var ice = detector.push({:valid=>true, :motionMg=>220,
            :rotationDps=>40, :periodic=>true}, i*1000);
        if (ice != null) { iceAt = ice[:atMs]; }
    }
    for (var j = 10; j < 25; j += 1) {
        var bench = detector.push({:valid=>true, :motionMg=>20,
            :rotationDps=>5, :periodic=>false}, j*1000);
        if (bench != null) { benchAt = bench[:atMs]; }
    }
    return iceAt == 0 && benchAt == 10000;
}
