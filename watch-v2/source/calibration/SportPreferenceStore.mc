using Toybox.Lang;

class SportPreferenceStore {
    const STORAGE_KEY = "rinklogic.training.lastSport.v1";
    private var mPort;

    function initialize(port) { mPort = port; }

    function load() as Lang.Symbol {
        try {
            var raw = mPort.getValue(STORAGE_KEY);
            if (raw instanceof Lang.String && raw.equals("inline")) { return :inline; }
            if (raw instanceof Lang.String && raw.equals("ice")) { return :ice; }
        } catch (ex) { }
        return :ice;
    }

    function save(sport) as Lang.Boolean {
        if (!CalibrationTypes.validSport(sport)) { return false; }
        var previous = null;
        try { previous = mPort.getValue(STORAGE_KEY); }
        catch (readEx) { return false; }
        var encoded = sport == :ice ? "ice" : "inline";
        try {
            mPort.setValue(STORAGE_KEY, encoded);
            var readback = mPort.getValue(STORAGE_KEY);
            if (readback instanceof Lang.String && readback.equals(encoded)) { return true; }
        } catch (writeEx) { }
        try {
            if (previous == null) { mPort.deleteValue(STORAGE_KEY); }
            else { mPort.setValue(STORAGE_KEY, previous); }
        } catch (restoreEx) { }
        return false;
    }
}
