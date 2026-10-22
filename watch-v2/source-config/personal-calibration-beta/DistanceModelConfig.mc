using Toybox.Lang;

class PersonalCalibrationBaselineConfig {
    function initialize() { }
    function mode() as Lang.Symbol { return :profile_height; }
    function personalCalibrationFactor() as Lang.Float { return 1.0; }
    function calibrationSource() as Lang.Symbol { return :none; }
}

class DistanceModelConfig extends StoredDistanceModelConfig {
    function initialize() {
        StoredDistanceModelConfig.initialize(
            new PersonalCalibrationBaselineConfig(),
            new CalibrationProfileStore(new ApplicationCalibrationStoragePort()));
    }
}
