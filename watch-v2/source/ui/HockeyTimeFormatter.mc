using Toybox.Lang;

class HockeyTimeFormatter {
    static function formatMinutes(milliseconds, decimalPlaces) as Lang.String {
        if (milliseconds == null || milliseconds < 0) { return "--"; }

        var precision = decimalPlaces == 2 ? 2 : 1;
        var scale = precision == 2 ? 100 : 10;
        var wholeMinutes = milliseconds / 60000;
        var remainderMs = milliseconds % 60000;
        var fractional = (remainderMs * scale + 30000) / 60000;
        if (fractional >= scale) {
            wholeMinutes += 1;
            fractional = 0;
        }

        var fractionText = precision == 2 ?
            fractional.format("%02d") : fractional.toString();
        return wholeMinutes.toString() + "." + fractionText + " min";
    }
}
