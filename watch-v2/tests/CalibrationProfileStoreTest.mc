using Toybox.Lang;
using Toybox.Math;
using Toybox.Test as Test;

class CalibrationStoragePortFake {
    var value = null;
    var throwGet = false;
    var throwSet = false;
    var throwDelete = false;
    var corruptNextSet = false;
    var setCount = 0;

    function getValue(key) {
        if (throwGet) { throw new Lang.Exception(); }
        return value;
    }
    function setValue(key, next) as Void {
        setCount += 1;
        if (throwSet) { throw new Lang.Exception(); }
        if (corruptNextSet) {
            corruptNextSet = false;
            value = {"schemaVersion"=>99};
        } else { value = next; }
    }
    function deleteValue(key) as Void {
        if (throwDelete) { throw new Lang.Exception(); }
        value = null;
    }
}

function calibrationProfileCandidate(sport, factor) as Lang.Dictionary {
    return {:schemaVersion=>1, :sport=>sport, :factor=>factor,
        :source=>:local_known_distance, :referenceDistanceCm=>2500,
        :conditionMedians=>{:skate_only=>factor,
            :puck_stickhandling=>factor}, :validRepetitionCount=>10,
        :acceptedRuns=>[{:privateRaw=>true}]};
}

(:test)
function calibrationProfileRoundTripsCompactStringStorage(logger as Test.Logger) as Lang.Boolean {
    var port = new CalibrationStoragePortFake();
    var store = new CalibrationProfileStore(port);
    if (!store.activate(calibrationProfileCandidate(:ice, 1.125))) { return false; }
    var active = store.loadActive();
    return active != null && active[:sport] == :ice && active[:factor] == 1.125 &&
        active[:source] == :local_known_distance &&
        active[:conditionMedians][:skate_only] == 1.125 &&
        port.value instanceof Lang.Dictionary && port.value["sport"].equals("ice") &&
        port.value["source"].equals("local_known_distance") &&
        !port.value.hasKey("acceptedRuns") && !port.value.hasKey("validRepetitionCount");
}

(:test)
function calibrationProfileReplacementAndDeactivationKeepOnlyOneProfile(logger as Test.Logger) as Lang.Boolean {
    var port = new CalibrationStoragePortFake();
    var store = new CalibrationProfileStore(port);
    if (!store.activate(calibrationProfileCandidate(:ice, 1.0)) ||
        !store.activate(calibrationProfileCandidate(:inline, 0.875))) { return false; }
    var active = store.loadActive();
    if (active == null || active[:sport] != :inline || active[:factor] != 0.875) {
        return false;
    }
    return store.deactivate() && store.loadActive() == null;
}

(:test)
function calibrationProfileRejectsEveryMissingPersistedKey(logger as Test.Logger) as Lang.Boolean {
    var keys = ["schemaVersion", "sport", "factor", "source",
        "referenceDistanceCm", "skateOnlyMedian", "puckStickhandlingMedian"];
    for (var missing = 0; missing < keys.size(); missing += 1) {
        var port = new CalibrationStoragePortFake();
        port.value = {"schemaVersion"=>1, "sport"=>"ice", "factor"=>1.0,
            "source"=>"local_known_distance", "referenceDistanceCm"=>2500,
            "skateOnlyMedian"=>1.0, "puckStickhandlingMedian"=>1.0};
        port.value.remove(keys[missing]);
        if ((new CalibrationProfileStore(port)).loadActive() != null) { return false; }
    }
    return true;
}

(:test)
function calibrationProfileRejectsUnsupportedOrMalformedStorage(logger as Test.Logger) as Lang.Boolean {
    var invalid = [
        {"schemaVersion"=>2, "sport"=>"ice", "factor"=>1.0,
            "source"=>"local_known_distance", "referenceDistanceCm"=>2500,
            "skateOnlyMedian"=>1.0, "puckStickhandlingMedian"=>1.0},
        {"schemaVersion"=>1, "sport"=>"run", "factor"=>1.0,
            "source"=>"local_known_distance", "referenceDistanceCm"=>2500,
            "skateOnlyMedian"=>1.0, "puckStickhandlingMedian"=>1.0},
        {"schemaVersion"=>1, "sport"=>"ice", "factor"=>1.51,
            "source"=>"local_known_distance", "referenceDistanceCm"=>2500,
            "skateOnlyMedian"=>1.0, "puckStickhandlingMedian"=>1.0},
        {"schemaVersion"=>1, "sport"=>"ice", "factor"=>Math.sqrt(-1.0),
            "source"=>"local_known_distance", "referenceDistanceCm"=>2500,
            "skateOnlyMedian"=>1.0, "puckStickhandlingMedian"=>1.0},
        {"schemaVersion"=>1, "sport"=>"ice", "factor"=>1.0,
            "source"=>"remote", "referenceDistanceCm"=>2500,
            "skateOnlyMedian"=>1.0, "puckStickhandlingMedian"=>1.0},
        {"schemaVersion"=>1, "sport"=>"ice", "factor"=>1.0,
            "source"=>"local_known_distance", "referenceDistanceCm"=>2100,
            "skateOnlyMedian"=>1.0, "puckStickhandlingMedian"=>1.0},
        {"schemaVersion"=>1, "sport"=>:ice, "factor"=>1.0,
            "source"=>"local_known_distance", "referenceDistanceCm"=>2500,
            "skateOnlyMedian"=>1.0, "puckStickhandlingMedian"=>1.0},
        [1, 2, 3]
    ];
    for (var i = 0; i < invalid.size(); i += 1) {
        var port = new CalibrationStoragePortFake();
        port.value = invalid[i];
        if ((new CalibrationProfileStore(port)).loadActive() != null) { return false; }
    }
    return true;
}

(:test)
function calibrationProfileRejectsMalformedCandidates(logger as Test.Logger) as Lang.Boolean {
    var invalid = [calibrationProfileCandidate(:run, 1.0),
        calibrationProfileCandidate(:ice, 0.49),
        calibrationProfileCandidate(:ice, 1.51),
        calibrationProfileCandidate(:ice, Math.sqrt(-1.0))];
    invalid.add({:schemaVersion=>1});
    invalid.add([1, 2]);
    for (var i = 0; i < invalid.size(); i += 1) {
        if ((new CalibrationProfileStore(new CalibrationStoragePortFake())).activate(invalid[i])) {
            return false;
        }
    }
    return true;
}

(:test)
function calibrationProfileStorageExceptionsFailClosed(logger as Test.Logger) as Lang.Boolean {
    var readPort = new CalibrationStoragePortFake();
    readPort.throwGet = true;
    if ((new CalibrationProfileStore(readPort)).loadActive() != null) { return false; }
    var writePort = new CalibrationStoragePortFake();
    writePort.throwSet = true;
    if ((new CalibrationProfileStore(writePort)).activate(
        calibrationProfileCandidate(:ice, 1.0))) { return false; }
    var deletePort = new CalibrationStoragePortFake();
    deletePort.throwDelete = true;
    return !(new CalibrationProfileStore(deletePort)).deactivate();
}

(:test)
function calibrationProfileFailedReplacementRestoresPriorValidProfile(logger as Test.Logger) as Lang.Boolean {
    var port = new CalibrationStoragePortFake();
    var store = new CalibrationProfileStore(port);
    if (!store.activate(calibrationProfileCandidate(:ice, 1.0))) { return false; }
    port.corruptNextSet = true;
    if (store.activate(calibrationProfileCandidate(:inline, 0.9))) { return false; }
    var active = store.loadActive();
    return active != null && active[:sport] == :ice && active[:factor] == 1.0;
}
