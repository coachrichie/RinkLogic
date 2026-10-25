using Toybox.Lang;
using Toybox.Test as Test;

class SportPreferenceStoragePortFake {
    var value = null;
    var throwGet = false;
    var throwSet = false;
    var setCount = 0;

    function getValue(key) {
        if (throwGet) { throw new Lang.Exception(); }
        return value;
    }

    function setValue(key, next) as Void {
        setCount += 1;
        if (throwSet) { throw new Lang.Exception(); }
        value = next;
    }

    function deleteValue(key) as Void { value = null; }
}

(:test)
function sportPreferenceDefaultsToIceAndRoundTripsOnlyValidSports(logger as Test.Logger) as Lang.Boolean {
    var port = new SportPreferenceStoragePortFake();
    var store = new SportPreferenceStore(port);
    if (store.load() != :ice || !store.save(:inline) || store.load() != :inline ||
        !store.save(:ice) || store.load() != :ice) { return false; }
    var writes = port.setCount;
    return !store.save(:run) && port.setCount == writes;
}

(:test)
function sportPreferenceInvalidOrUnavailableStorageFallsBackToIce(logger as Test.Logger) as Lang.Boolean {
    var textPort = new SportPreferenceStoragePortFake();
    textPort.value = "run";
    if ((new SportPreferenceStore(textPort)).load() != :ice) { return false; }
    var symbolPort = new SportPreferenceStoragePortFake();
    symbolPort.value = :inline;
    if ((new SportPreferenceStore(symbolPort)).load() != :ice) { return false; }
    var numberPort = new SportPreferenceStoragePortFake();
    numberPort.value = 42;
    if ((new SportPreferenceStore(numberPort)).load() != :ice) { return false; }
    var dictionaryPort = new SportPreferenceStoragePortFake();
    dictionaryPort.value = {"sport"=>"inline"};
    if ((new SportPreferenceStore(dictionaryPort)).load() != :ice) { return false; }
    var failing = new SportPreferenceStoragePortFake();
    failing.throwGet = true;
    return (new SportPreferenceStore(failing)).load() == :ice;
}

(:test)
function sportPreferenceWriteFailureReturnsFalseWithoutChangingSelection(logger as Test.Logger) as Lang.Boolean {
    var port = new SportPreferenceStoragePortFake();
    var store = new SportPreferenceStore(port);
    if (!store.save(:inline)) { return false; }
    port.throwSet = true;
    return !store.save(:ice) && store.load() == :inline;
}
