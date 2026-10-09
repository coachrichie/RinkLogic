using Toybox.Lang;

class CalibrationManifest {
    static function row(sessionId, repetition, sport, condition,
                        referenceDistanceCm, referencePushes, markerStatus) as Lang.Dictionary {
        return {:sessionId=>sessionId, :repetition=>repetition,
            :sport=>sport.toString(), :condition=>condition.toString(),
            :referenceDistanceCm=>referenceDistanceCm,
            :referencePushes=>referencePushes,
            :markerStatus=>markerStatus.toString()};
    }
}
