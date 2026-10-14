using Toybox.Lang;
using Toybox.Test as Test;

(:test)
function hockeyTimeFormatterHandlesMinuteBoundaries(logger as Test.Logger) as Lang.Boolean {
    return HockeyTimeFormatter.formatMinutes(null, 1).equals("--") &&
        HockeyTimeFormatter.formatMinutes(-1, 1).equals("--") &&
        HockeyTimeFormatter.formatMinutes(0, 1).equals("0.0 min") &&
        HockeyTimeFormatter.formatMinutes(59999, 1).equals("1.0 min") &&
        HockeyTimeFormatter.formatMinutes(60000, 1).equals("1.0 min") &&
        HockeyTimeFormatter.formatMinutes(50000, 2).equals("0.83 min") &&
        HockeyTimeFormatter.formatMinutes(3661000, 1).equals("61.0 min");
}
