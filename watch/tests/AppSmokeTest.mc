using Toybox.Test as Test;
using Toybox.Lang;

(:test)
function appNameIsStable(logger as Test.Logger) as Lang.Boolean {
    return ShiftSenseApp.APP_NAME.equals("ShiftSense Hockey");
}
