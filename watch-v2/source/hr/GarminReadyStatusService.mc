using Toybox.Lang;
using Toybox.System;

class GarminReadyStatusService {
    function snapshot() as Lang.Dictionary {
        var phoneConnected = false;
        try { phoneConnected = System.getDeviceSettings().phoneConnected; } catch (ex) { }
        return {:phoneConnected=>phoneConnected};
    }
}
