using Toybox.Lang;
using Toybox.Sensor;

class HeartRateService {
    private var mListener = null;
    private var mStarted = false;

    function start(listener as Lang.Method) as Lang.Boolean {
        if (mStarted) { return false; }
        mListener = listener;
        try {
            Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
            Sensor.enableSensorEvents(method(:onInfo));
            mStarted = true;
            return true;
        } catch (ex) {
            try {
                Sensor.enableSensorEvents(null);
                Sensor.setEnabledSensors([]);
            } catch (cleanupError) { }
            mListener = null;
            return false;
        }
    }

    function stop() as Void {
        if (mStarted) {
            try {
                Sensor.enableSensorEvents(null);
                Sensor.setEnabledSensors([]);
            } catch (ex) { }
        }
        mStarted = false;
        mListener = null;
    }

    function onInfo(info as Sensor.Info) as Void {
        if (mListener != null) { mListener.invoke(normalize(info)); }
    }

    static function normalize(info) as Lang.Dictionary {
        var value = null;
        try { if (info != null) { value = info.heartRate; } } catch (ex) { }
        if (value != null && value > 0 && value <= 255) {
            return {:heartRate=>value, :quality=>:active};
        }
        return {:heartRate=>null, :quality=>:missing};
    }
}
