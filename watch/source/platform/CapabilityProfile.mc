using Toybox;
using Toybox.Activity;
using Toybox.Lang;
using Toybox.Sensor;
using Toybox.System;

class CapabilityProfile {
    public static function detect() as Lang.Dictionary {
        var highRateAccel = false;
        var gyro = false;

        if ((Toybox has :Sensor) &&
            (Sensor has :registerSensorDataListener) &&
            (Sensor has :getMaxSampleRateForSensorType)) {
            highRateAccel = Sensor.getMaxSampleRateForSensorType(:accelerometer) >= 25;
            gyro = Sensor.getMaxSampleRateForSensorType(:gyroscope) >= 25;
        }

        var position = Toybox has :Position;
        var trainingEffect = (Toybox has :Activity) && (Activity has :getActivityInfo);
        var profile = fromFlags(highRateAccel, gyro, position, trainingEffect);

        if ((Toybox has :System) && (System has :getDeviceSettings)) {
            profile[:touch] = System.getDeviceSettings().isTouchScreen;
        }

        return profile;
    }

    public static function fromFlags(
        highRateAccel as Lang.Boolean,
        gyro as Lang.Boolean,
        position as Lang.Boolean,
        trainingEffect as Lang.Boolean
    ) as Lang.Dictionary {
        return {
            :highRateAccel => highRateAccel,
            :gyro => gyro,
            :position => position,
            :trainingEffect => trainingEffect,
            :touch => false,
            :fullAnalysis => highRateAccel && gyro
        };
    }
}
