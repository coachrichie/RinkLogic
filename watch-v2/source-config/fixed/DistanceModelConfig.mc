using Toybox.Lang;

class DistanceModelConfig {
    function initialize() { }

    function mode() as Lang.Symbol {
        return :fixed;
    }

    function personalCalibrationFactor() as Lang.Float { return 1.0; }

    function calibrationSource() as Lang.Symbol { return :none; }
}
