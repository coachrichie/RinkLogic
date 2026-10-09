using Toybox.Lang;
using Toybox.Sensor;

class SystemMotionPort {
    function maxRate(type as Lang.Symbol) as Lang.Number {
        if (!(Sensor has :getMaxSampleRateForSensorType)) { return 0; }
        try { return Sensor.getMaxSampleRateForSensorType(type); }
        catch (ex) { return 0; }
    }

    function register(listener, options) as Lang.Boolean {
        if (!(Sensor has :registerSensorDataListener)) { return false; }
        Sensor.registerSensorDataListener(listener, options);
        return true;
    }

    function unregister() as Void {
        if (Sensor has :unregisterSensorDataListener) {
            Sensor.unregisterSensorDataListener();
        }
    }
}

class MotionSource {
    private var mPort;
    private var mListener = null;
    private var mRegistered = false;
    private var mAccelRate = 0;
    private var mGyroRate = 0;

    function initialize(port) { mPort = port; }

    function start(listener as Lang.Method) as Lang.Boolean {
        if (mRegistered) { return true; }
        var accelRate = 0;
        var gyroRate = 0;
        try {
            accelRate = mPort.maxRate(:accelerometer);
            gyroRate = mPort.maxRate(:gyroscope);
        } catch (ex) { return false; }
        if (accelRate == null || accelRate <= 0) { return false; }
        if (accelRate > 10) { accelRate = 10; }
        if (gyroRate != null && gyroRate > 10) { gyroRate = 10; }
        mAccelRate = accelRate;
        mGyroRate = gyroRate;
        var options = {
            :period=>1,
            :accelerometer=>{:enabled=>true, :sampleRate=>accelRate,
                :includeTimestamps=>true}
        };
        if (gyroRate != null && gyroRate > 0) {
            options[:gyroscope] = {:enabled=>true, :sampleRate=>gyroRate,
                :includeTimestamps=>true};
        }
        mListener = listener;
        try {
            if (!mPort.register(method(:onData), options)) {
                mListener = null;
                return false;
            }
            mRegistered = true;
            return true;
        } catch (ex) {
            try { mPort.unregister(); } catch (cleanupEx) { }
            mListener = null;
            mRegistered = false;
            return false;
        }
    }

    function onData(data) as Void {
        if (!mRegistered || mListener == null) { return; }
        var feature = {:valid=>false, :motionMg=>null,
            :rotationDps=>null, :periodic=>false, :pushBatch=>null};
        try {
            if (data != null && data.accelerometerData != null) {
                var accel = data.accelerometerData;
                var gyro = data.gyroscopeData;
                feature = MotionFeatures.fromArrays(accel.x, accel.y, accel.z,
                    gyro == null ? null : gyro.x,
                    gyro == null ? null : gyro.y,
                    gyro == null ? null : gyro.z);
                feature[:pushBatch] = null;
                var accelTimes = null;
                var gyroTimes = null;
                if (accel has :timestamp) { accelTimes = accel.timestamp; }
                if (gyro != null && (gyro has :timestamp)) {
                    gyroTimes = gyro.timestamp;
                }
                var timebase = :measured;
                if (gyro != null && (accelTimes == null || gyroTimes == null)) {
                    accelTimes = estimatedTimes(accel.x, mAccelRate);
                    gyroTimes = estimatedTimes(gyro.x, mGyroRate);
                    timebase = :estimated;
                }
                if (gyro != null && accel.x != null && accel.y != null &&
                    accel.z != null && accelTimes != null &&
                    gyro.x != null && gyro.y != null && gyro.z != null &&
                    gyroTimes != null) {
                    feature[:pushBatch] = {:ax=>accel.x, :ay=>accel.y,
                        :az=>accel.z, :gx=>gyro.x, :gy=>gyro.y,
                        :gz=>gyro.z, :accelTimes=>accelTimes,
                        :gyroTimes=>gyroTimes, :timebase=>timebase};
                }
            }
        } catch (ex) { }
        try { mListener.invoke(feature); } catch (callbackEx) { }
    }

    private function estimatedTimes(values, rate) {
        if (values == null || rate == null || rate <= 0 ||
            values.size() < 5 || values.size() > rate + 1) { return null; }
        var interval = (1000.0 / rate).toNumber();
        var times = [];
        for (var i = 0; i < values.size(); i += 1) {
            times.add((i - values.size() + 1) * interval);
        }
        return times;
    }

    function stop() as Void {
        if (mRegistered) {
            try { mPort.unregister(); } catch (ex) { }
        }
        mRegistered = false;
        mListener = null;
        mAccelRate = 0;
        mGyroRate = 0;
    }
}
