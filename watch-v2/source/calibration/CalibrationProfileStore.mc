using Toybox.Lang;

class CalibrationProfileStore {
    const STORAGE_KEY = "rinklogic.calibration.active.v1";
    private var mPort;

    function initialize(port) { mPort = port; }

    function loadActive() {
        try { return parseStored(mPort.getValue(STORAGE_KEY)); }
        catch (ex) { return null; }
    }

    function activate(candidate) as Lang.Boolean {
        var compact = compactCandidate(candidate);
        if (compact == null) { return false; }
        var previous = null;
        try { previous = mPort.getValue(STORAGE_KEY); }
        catch (readEx) { return false; }
        try {
            mPort.setValue(STORAGE_KEY, compact);
            var readback = mPort.getValue(STORAGE_KEY);
            var active = parseStored(readback);
            if (active != null && matchesCompact(active, compact)) { return true; }
        } catch (writeEx) { }
        restore(previous);
        return false;
    }

    function deactivate() as Lang.Boolean {
        try {
            mPort.deleteValue(STORAGE_KEY);
            return mPort.getValue(STORAGE_KEY) == null;
        } catch (ex) { return false; }
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
                "sport"=>candidate[:sport] == :ice ? "ice" : "inline",
                "factor"=>candidate[:factor].toFloat(),
                "source"=>"local_known_distance",
                "referenceDistanceCm"=>candidate[:referenceDistanceCm],
                "skateOnlyMedian"=>candidate[:conditionMedians][:skate_only].toFloat(),
                "puckStickhandlingMedian"=>
                    candidate[:conditionMedians][:puck_stickhandling].toFloat()};
        } catch (ex) { return null; }
    }

    private function parseStored(raw) {
        try {
            if (!(raw instanceof Lang.Dictionary) ||
                !hasStoredKeys(raw) || raw["schemaVersion"] != 1 ||
                !(raw["sport"] instanceof Lang.String) ||
                !(raw["source"] instanceof Lang.String) ||
                !raw["source"].equals("local_known_distance") ||
                !CalibrationTypes.validReferenceDistance(raw["referenceDistanceCm"]) ||
                !validFactor(raw["factor"]) || !validFactor(raw["skateOnlyMedian"]) ||
                !validFactor(raw["puckStickhandlingMedian"])) { return null; }
            var sport = raw["sport"].equals("ice") ? :ice :
                (raw["sport"].equals("inline") ? :inline : null);
            if (sport == null) { return null; }
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

    private function restore(previous) as Void {
        try {
            if (previous == null) { mPort.deleteValue(STORAGE_KEY); }
            else { mPort.setValue(STORAGE_KEY, previous); }
        } catch (restoreEx) {
            try { mPort.deleteValue(STORAGE_KEY); } catch (deleteEx) { }
        }
    }
}
