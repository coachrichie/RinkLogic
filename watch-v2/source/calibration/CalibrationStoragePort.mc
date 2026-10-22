using Toybox.Application.Storage;

class ApplicationCalibrationStoragePort {
    function initialize() { }
    function getValue(key) { return Storage.getValue(key); }
    function setValue(key, value) as Void { Storage.setValue(key, value); }
    function deleteValue(key) as Void { Storage.deleteValue(key); }
}
