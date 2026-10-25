using Toybox.Lang;
using Toybox.Math;
using Toybox.Test as Test;

class CalibrationStoragePortFake {
    var legacyValue = null;
    var profilesValue = null;
    var throwGetKey = null;
    var throwSetKey = null;
    var throwDeleteKey = null;
    var corruptNextSetKey = null;
    var setCount = 0;
    var deleteCount = 0;

    function getValue(key) {
        if (throwGetKey != null && throwGetKey.equals(key)) {
            throw new Lang.Exception();
        }
        return key.equals("rinklogic.calibration.active.v1") ?
            legacyValue : profilesValue;
    }

    function setValue(key, next) as Void {
        setCount += 1;
        if (throwSetKey != null && throwSetKey.equals(key)) {
            throw new Lang.Exception();
        }
        if (corruptNextSetKey != null && corruptNextSetKey.equals(key)) {
            corruptNextSetKey = null;
            profilesValue = {"schemaVersion"=>99};
        } else {
            if (key.equals("rinklogic.calibration.active.v1")) {
                legacyValue = next;
            } else {
                profilesValue = next;
            }
        }
    }

    function deleteValue(key) as Void {
        deleteCount += 1;
        if (throwDeleteKey != null && throwDeleteKey.equals(key)) {
            throw new Lang.Exception();
        }
        if (key.equals("rinklogic.calibration.active.v1")) {
            legacyValue = null;
        } else {
            profilesValue = null;
        }
    }
}

function calibrationProfileCandidate(sport, factor) as Lang.Dictionary {
    return {:schemaVersion=>1, :sport=>sport, :factor=>factor,
        :source=>:local_known_distance, :referenceDistanceCm=>2500,
        :conditionMedians=>{:skate_only=>factor,
            :puck_stickhandling=>factor}, :validRepetitionCount=>10,
        :acceptedRuns=>[{:privateRaw=>true}]};
}

function compactCalibrationProfile(sport, factor) as Lang.Dictionary {
    return {"schemaVersion"=>1, "sport"=>sport == :ice ? "ice" : "inline",
        "factor"=>factor, "source"=>"local_known_distance",
        "referenceDistanceCm"=>2500, "skateOnlyMedian"=>factor,
        "puckStickhandlingMedian"=>factor};
}

(:test)
function calibrationProfileStoresIceAndInlineWithoutCrossLoading(logger as Test.Logger) as Lang.Boolean {
    var port = new CalibrationStoragePortFake();
    var store = new CalibrationProfileStore(port);
    if (!store.activate(calibrationProfileCandidate(:ice, 1.125)) ||
        !store.activate(calibrationProfileCandidate(:inline, 0.875))) { return false; }
    var ice = store.loadForSport(:ice);
    var inline = store.loadForSport(:inline);
    var states = store.statuses();
    if (ice == null || ice[:sport] != :ice || ice[:factor] != 1.125) { return false; }
    if (inline == null || inline[:sport] != :inline || inline[:factor] != 0.875) {
        return false;
    }
    if (!states[:ice] || !states[:inline] || port.profilesValue == null) {
        return false;
    }
    var storedIce = port.profilesValue["ice"];
    return storedIce != null && !storedIce.hasKey("acceptedRuns");
}

(:test)
function calibrationProfileCorruptSlotDoesNotInvalidateOtherSport(logger as Test.Logger) as Lang.Boolean {
    var port = new CalibrationStoragePortFake();
    port.profilesValue = {
        "schemaVersion"=>2,
        "ice"=>compactCalibrationProfile(:ice, 1.1),
        "inline"=>{"schemaVersion"=>99}
    };
    var store = new CalibrationProfileStore(port);
    var states = store.statuses();
    var ice = store.loadForSport(:ice);
    return ice != null && ice[:factor] == 1.1 && store.loadForSport(:inline) == null &&
        states[:ice] && !states[:inline];
}

(:test)
function calibrationProfileDeactivateAndRestoreTouchOnlySelectedSport(logger as Test.Logger) as Lang.Boolean {
    var port = new CalibrationStoragePortFake();
    var store = new CalibrationProfileStore(port);
    if (!store.activate(calibrationProfileCandidate(:ice, 1.1)) ||
        !store.activate(calibrationProfileCandidate(:inline, 0.9))) { return false; }
    var snapshot = store.snapshot(:ice);
    if (!store.deactivate(:ice) || store.loadForSport(:ice) != null ||
        store.loadForSport(:inline) == null) { return false; }
    if (!store.restore(:ice, snapshot)) { return false; }
    return store.loadForSport(:ice)[:factor] == 1.1 &&
        store.loadForSport(:inline)[:factor] == 0.9;
}

(:test)
function calibrationProfileMigratesLegacyOnlyAfterVerifiedReadback(logger as Test.Logger) as Lang.Boolean {
    var port = new CalibrationStoragePortFake();
    port.legacyValue = compactCalibrationProfile(:inline, 1.05);
    var store = new CalibrationProfileStore(port);
    var active = store.loadForSport(:inline);
    return active != null && active[:sport] == :inline && active[:factor] == 1.05 &&
        port.legacyValue == null && port.profilesValue != null &&
        port.setCount == 1 && port.deleteCount == 1;
}

(:test)
function calibrationProfileMigrationIsIdempotent(logger as Test.Logger) as Lang.Boolean {
    var port = new CalibrationStoragePortFake();
    port.legacyValue = compactCalibrationProfile(:ice, 1.02);
    var store = new CalibrationProfileStore(port);
    if (store.loadForSport(:ice) == null) { return false; }
    var writes = port.setCount;
    if (store.loadForSport(:ice) == null || store.statuses()[:ice] != true) { return false; }
    return port.setCount == writes && port.deleteCount == 1;
}

(:test)
function calibrationProfileMigrationRollbackKeepsLegacyOnWriteReadOrDeleteFailure(logger as Test.Logger) as Lang.Boolean {
    var failures = [:write, :readback, :delete];
    for (var i = 0; i < failures.size(); i += 1) {
        var port = new CalibrationStoragePortFake();
        port.legacyValue = compactCalibrationProfile(:ice, 1.0);
        if (failures[i] == :write) {
            port.throwSetKey = "rinklogic.calibration.profiles.v2";
        } else if (failures[i] == :readback) {
            port.corruptNextSetKey = "rinklogic.calibration.profiles.v2";
        } else {
            port.throwDeleteKey = "rinklogic.calibration.active.v1";
        }
        var active = (new CalibrationProfileStore(port)).loadForSport(:ice);
        if (active == null || active[:factor] != 1.0 ||
            port.legacyValue == null) { return false; }
        if (failures[i] == :delete &&
            port.profilesValue != null) { return false; }
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
    readPort.throwGetKey = "rinklogic.calibration.profiles.v2";
    if ((new CalibrationProfileStore(readPort)).loadForSport(:ice) != null) { return false; }
    var writePort = new CalibrationStoragePortFake();
    writePort.throwSetKey = "rinklogic.calibration.profiles.v2";
    if ((new CalibrationProfileStore(writePort)).activate(
        calibrationProfileCandidate(:ice, 1.0))) { return false; }
    var deletePort = new CalibrationStoragePortFake();
    deletePort.profilesValue = {
        "schemaVersion"=>2, "ice"=>compactCalibrationProfile(:ice, 1.0), "inline"=>null};
    deletePort.throwSetKey = "rinklogic.calibration.profiles.v2";
    return !(new CalibrationProfileStore(deletePort)).deactivate(:ice);
}
