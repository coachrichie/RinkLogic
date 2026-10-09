using Toybox;
using Toybox.Lang;
using Toybox.Sensor;

class SensorAdapter {
    hidden var mListening = false;
    hidden var mHeartRateEnabled = false;
    hidden var mListener = null;

    public function start(listener as Lang.Method, profile as Lang.Dictionary) as Lang.Boolean {
        mListener = listener;
        var useAccelerometer = profile[:highRateAccel] == true;
        var useGyroscope = profile[:gyro] == true;
        if (!(Toybox has :Sensor)) {
            return false;
        }
        try {
            // SENSOR_HEARTRATE uses Garmin's active source: wrist HR or a
            // paired external sensor such as H10. It is intentionally not
            // treated as a required prerequisite for a recording.
            if ((Sensor has :setEnabledSensors) && (Sensor has :SENSOR_HEARTRATE)) {
                Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
                mHeartRateEnabled = true;
                // SensorData batches carry motion/RR data; HR is delivered
                // separately as documented Sensor.Info events.
                if (Sensor has :enableSensorEvents) { Sensor.enableSensorEvents(method(:onInfo)); }
            }
            if (Sensor has :registerSensorDataListener) {
            var options = {
                :period => 1,
                :accelerometer => {
                    :enabled => useAccelerometer,
                    :sampleRate => 25,
                    :includeTimestamps => true
                },
                :gyroscope => {
                    :enabled => useGyroscope,
                    :sampleRate => 25,
                    :includeTimestamps => true
                },
                :heartBeatIntervals => {
                    :enabled => true
                }
            };
            Sensor.registerSensorDataListener(method(:onData), options);
            mListening = true;
            }
        } catch (ex) {
            // HR is optional. Keep a successfully enabled source available,
            // but never prevent ActivityRecording from starting.
        }
        return mHeartRateEnabled || mListening;
    }

    public function onInfo(info as Sensor.Info) as Void {
        if (mListener != null) { mListener.invoke(normalizeSample(info)); }
    }

    public function onData(data as Sensor.SensorData) as Void {
        if (mListener != null) { mListener.invoke(normalizeSample(data)); }
    }

    public static function normalizeSample(data) as Lang.Dictionary {
        if (data == null) { return {:quality=>:missing}; }
        var result = {};
        if (data has :heartRate) { result[:heartRate] = data.heartRate; }
        if ((data has :heartRateData) && data.heartRateData != null) {
            var intervals = data.heartRateData.heartBeatIntervals;
            if (intervals != null && intervals.size() > 0) {
                result[:rrMs] = intervals[intervals.size() - 1];
            }
        }
        if (data has :timestamp) { result[:timestampMs] = data.timestamp; }
        if (result.hasKey(:heartRate) && result[:heartRate] != null) { result[:quality] = :active; }
        else if (result.hasKey(:rrMs)) { result[:quality] = :rrOnly; }
        else { result[:quality] = :missing; }
        return result;
    }

    public function stop() as Void {
        if (mListening &&
            (Toybox has :Sensor) &&
            (Sensor has :unregisterSensorDataListener)) {
            Sensor.unregisterSensorDataListener();
        }
        if (mHeartRateEnabled && (Toybox has :Sensor) &&
            (Sensor has :setEnabledSensors)) {
            try {
                if (Sensor has :enableSensorEvents) { Sensor.enableSensorEvents(null); }
                Sensor.setEnabledSensors([]);
            } catch (ex) {
            }
        }
        mListening = false;
        mHeartRateEnabled = false;
        mListener = null;
    }
}
