using Toybox.Lang;

class DistanceModelConfig {
    function initialize() { }

    function mode() as Lang.Symbol { return :calibrated_profile_test; }

    function personalCalibrationFactor() as Lang.Float {
        return (220.0 / 292.5).toFloat();
    }

    function calibrationSource() as Lang.Symbol {
        return :local_known_distance;
    }
}
