using Toybox.Lang;
using Toybox.System;

class AppClock {
    function nowMs() as Lang.Number { return System.getTimer(); }
}
