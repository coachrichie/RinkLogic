using Toybox.Lang;

class CalibrationProfileStore {
    const LEGACY_STORAGE_KEY = "rinklogic.calibration.active.v1";
    const STORAGE_KEY = "rinklogic.calibration.profiles.v2";
    private var mPort;

    function initialize(port) { mPort = port; }

    function loadForSport(sport) {
        if (!CalibrationTypes.validSport(sport)) { return null; }
        var profiles = readProfilesWithMigration();
        if (profiles == null) { return loadLegacyForSport(sport); }
        return parseStored(slotValue(profiles, sport), sport);
    }

    // Kept during the Beta 6 to Beta 7 transition. New callers must select a sport.
    function loadActive() {
        var ice = loadForSport(:ice);
        return ice != null ? ice : loadForSport(:inline);
    }

    function statuses() as Lang.Dictionary {
        return {:ice=>loadForSport(:ice) != null,
            :inline=>loadForSport(:inline) != null};
    }

    function activate(candidate) as Lang.Boolean {
        var compact = compactCandidate(candidate);
        if (compact == null) { return false; }
        var sport = candidate[:sport];
        var previous = rawProfiles();
        var profiles = validProfiles(previous) ? previous : emptyProfiles();
        var updated = copyProfiles(profiles);
        updated[sportKey(sport)] = compact;
        if (!writeAndVerify(updated, sport, compact)) {
            restoreProfiles(previous);
            return false;
        }
        return true;
    }

    function deactivate(sport) as Lang.Boolean {
        if (!CalibrationTypes.validSport(sport)) { return false; }
        var previous = rawProfiles();
        if (!validProfiles(previous)) { return false; }
        var updated = copyProfiles(previous);
        updated[sportKey(sport)] = null;
        try {
            mPort.setValue(STORAGE_KEY, updated);
            var readback = rawProfiles();
            if (validProfiles(readback) &&
                parseStored(slotValue(readback, sport), sport) == null) { return true; }
        } catch (ex) { }
        restoreProfiles(previous);
        return false;
    }

    function snapshot(sport) {
        if (!CalibrationTypes.validSport(sport)) { return null; }
        var active = loadForSport(sport);
        return active == null ? null : compactActive(active);
    }

    function restore(sport, snapshot) as Lang.Boolean {
        if (!CalibrationTypes.validSport(sport)) { return false; }
        if (snapshot == null) { return deactivate(sport); }
        var parsed = parseStored(snapshot, sport);
        if (parsed == null) { return false; }
        var candidate = {:schemaVersion=>1, :sport=>sport,
            :factor=>parsed[:factor], :source=>:local_known_distance,
            :referenceDistanceCm=>parsed[:referenceDistanceCm],
            :conditionMedians=>parsed[:conditionMedians],
            :validRepetitionCount=>10};
        return activate(candidate);
    }

    private function readProfilesWithMigration() {
        var current = rawProfiles();
        if (validProfiles(current)) { return current; }
        var legacyRaw = null;
        try { legacyRaw = mPort.getValue(LEGACY_STORAGE_KEY); }
        catch (legacyReadEx) { return null; }
        var legacy = parseStored(legacyRaw, null);
        if (legacy == null) { return null; }

        var migrated = emptyProfiles();
        migrated[sportKey(legacy[:sport])] = compactActive(legacy);
        try {
            mPort.setValue(STORAGE_KEY, migrated);
            var readback = rawProfiles();
            var migratedActive = validProfiles(readback) ?
                parseStored(slotValue(readback, legacy[:sport]), legacy[:sport]) : null;
            if (migratedActive == null ||
                !matchesCompact(migratedActive, migrated[sportKey(legacy[:sport])])) {
                restoreProfiles(current);
                return null;
            }
            try {
                mPort.deleteValue(LEGACY_STORAGE_KEY);
                if (mPort.getValue(LEGACY_STORAGE_KEY) == null) { return readback; }
            } catch (deleteEx) { }
        } catch (writeEx) { }
        restoreProfiles(current);
        return null;
    }

    private function loadLegacyForSport(sport) {
        try {
            var legacy = parseStored(mPort.getValue(LEGACY_STORAGE_KEY), sport);
            return legacy != null && legacy[:sport] == sport ? legacy : null;
        } catch (ex) { return null; }
    }

    private function rawProfiles() {
        try { return mPort.getValue(STORAGE_KEY); }
        catch (ex) { return null; }
    }

    private function validProfiles(raw) as Lang.Boolean {
        try {
            return raw instanceof Lang.Dictionary && raw.hasKey("schemaVersion") &&
                raw["schemaVersion"] == 2;
        } catch (ex) { return false; }
    }

    private function emptyProfiles() as Lang.Dictionary {
        return {"schemaVersion"=>2, "ice"=>null, "inline"=>null};
    }

    private function copyProfiles(raw) as Lang.Dictionary {
        return {"schemaVersion"=>2,
            "ice"=>raw.hasKey("ice") ? raw["ice"] : null,
            "inline"=>raw.hasKey("inline") ? raw["inline"] : null};
    }

    private function slotValue(profiles, sport) {
        var key = sportKey(sport);
        return profiles.hasKey(key) ? profiles[key] : null;
    }

    private function sportKey(sport) as Lang.String {
        return sport == :ice ? "ice" : "inline";
    }

    private function writeAndVerify(profiles, sport, compact) as Lang.Boolean {
        try {
            mPort.setValue(STORAGE_KEY, profiles);
            var readback = rawProfiles();
            if (!validProfiles(readback)) { return false; }
            var active = parseStored(slotValue(readback, sport), sport);
            return active != null && matchesCompact(active, compact);
        } catch (ex) { return false; }
    }

    private function restoreProfiles(previous) as Void {
        try {
            if (previous == null) { mPort.deleteValue(STORAGE_KEY); }
            else { mPort.setValue(STORAGE_KEY, previous); }
        } catch (restoreEx) { }
    }

    private function compactCandidate(candidate) {
        try {
            if (!(candidate instanceof Lang.Dictionary) ||
                !candidate.hasKey(:schemaVersion) || candidate[:schemaVersion] != 1 ||
                !candidate.hasKey(:sport) || !CalibrationTypes.validSport(candidate[:sport]) ||
                !candidate.hasKey(:source) || candidate[:source] != :local_known_distance ||
                !candidate.hasKey(:factor) || !validFactor(candidate[:factor]) ||
                !candidate.hasKey(:referenceDistanceCm) ||
                !CalibrationTypes.validReferenceDistance(candidate[:referenceDistanceCm]) ||
                !candidate.hasKey(:conditionMedians) ||
                !(candidate[:conditionMedians] instanceof Lang.Dictionary) ||
                !candidate[:conditionMedians].hasKey(:skate_only) ||
                !candidate[:conditionMedians].hasKey(:puck_stickhandling) ||
                !validFactor(candidate[:conditionMedians][:skate_only]) ||
                !validFactor(candidate[:conditionMedians][:puck_stickhandling]) ||
                !candidate.hasKey(:validRepetitionCount) ||
                candidate[:validRepetitionCount] != 10) { return null; }
            return {"schemaVersion"=>1,
                "sport"=>sportKey(candidate[:sport]),
                "factor"=>candidate[:factor].toFloat(),
                "source"=>"local_known_distance",
                "referenceDistanceCm"=>candidate[:referenceDistanceCm],
                "skateOnlyMedian"=>candidate[:conditionMedians][:skate_only].toFloat(),
                "puckStickhandlingMedian"=>
                    candidate[:conditionMedians][:puck_stickhandling].toFloat()};
        } catch (ex) { return null; }
    }

    private function compactActive(active) as Lang.Dictionary {
        return {"schemaVersion"=>1, "sport"=>sportKey(active[:sport]),
            "factor"=>active[:factor].toFloat(), "source"=>"local_known_distance",
            "referenceDistanceCm"=>active[:referenceDistanceCm],
            "skateOnlyMedian"=>active[:conditionMedians][:skate_only].toFloat(),
            "puckStickhandlingMedian"=>
                active[:conditionMedians][:puck_stickhandling].toFloat()};
    }

    private function parseStored(raw, expectedSport) {
        try {
            if (!(raw instanceof Lang.Dictionary) || !hasStoredKeys(raw) ||
                raw["schemaVersion"] != 1 || !(raw["sport"] instanceof Lang.String) ||
                !(raw["source"] instanceof Lang.String) ||
                !raw["source"].equals("local_known_distance") ||
                !CalibrationTypes.validReferenceDistance(raw["referenceDistanceCm"]) ||
                !validFactor(raw["factor"]) || !validFactor(raw["skateOnlyMedian"]) ||
                !validFactor(raw["puckStickhandlingMedian"])) { return null; }
            var sport = raw["sport"].equals("ice") ? :ice :
                (raw["sport"].equals("inline") ? :inline : null);
            if (sport == null || (expectedSport != null && sport != expectedSport)) {
                return null;
            }
            return {:schemaVersion=>1, :sport=>sport,
                :factor=>raw["factor"].toFloat(), :source=>:local_known_distance,
                :referenceDistanceCm=>raw["referenceDistanceCm"],
                :conditionMedians=>{
                    :skate_only=>raw["skateOnlyMedian"].toFloat(),
                    :puck_stickhandling=>raw["puckStickhandlingMedian"].toFloat()
                }};
        } catch (ex) { return null; }
    }

    private function hasStoredKeys(raw) as Lang.Boolean {
        var keys = ["schemaVersion", "sport", "factor", "source",
            "referenceDistanceCm", "skateOnlyMedian", "puckStickhandlingMedian"];
        for (var i = 0; i < keys.size(); i += 1) {
            if (!raw.hasKey(keys[i])) { return false; }
        }
        return true;
    }

    private function validFactor(value) as Lang.Boolean {
        try {
            if (!(value instanceof Lang.Number) && !(value instanceof Lang.Float) &&
                !(value instanceof Lang.Long) && !(value instanceof Lang.Double)) {
                return false;
            }
            var factor = value.toFloat();
            return factor == factor && factor >= 0.50 && factor <= 1.50;
        } catch (ex) { return false; }
    }

    private function matchesCompact(active, compact) as Lang.Boolean {
        return active[:schemaVersion] == compact["schemaVersion"] &&
            active[:sport] == (compact["sport"].equals("ice") ? :ice : :inline) &&
            active[:factor] == compact["factor"] &&
            active[:referenceDistanceCm] == compact["referenceDistanceCm"] &&
            active[:conditionMedians][:skate_only] == compact["skateOnlyMedian"] &&
            active[:conditionMedians][:puck_stickhandling] ==
                compact["puckStickhandlingMedian"];
    }
}
