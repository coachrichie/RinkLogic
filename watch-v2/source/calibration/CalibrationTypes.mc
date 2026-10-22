using Toybox.Lang;

class CalibrationTypes {
    static function validSport(sport) as Lang.Boolean {
        return sport == :ice || sport == :inline;
    }

    static function validCondition(condition) as Lang.Boolean {
        return condition == :skate_only || condition == :puck_stickhandling;
    }

    static function validReferenceDistance(referenceDistanceCm) as Lang.Boolean {
        return referenceDistanceCm == 2000 || referenceDistanceCm == 2200 ||
            referenceDistanceCm == 2500 || referenceDistanceCm == 3000;
    }

    static function validTimebase(timebase) as Lang.Boolean {
        return timebase == :measured || timebase == :estimated;
    }

    static function conditionForIndex(index) {
        if (index == null || index < 0 || index >= 10) { return null; }
        return index < 5 ? :skate_only : :puck_stickhandling;
    }

    static function paceForIndex(index) {
        if (index == null || index < 0 || index >= 10) { return null; }
        var sequence = [:slow, :fast, :normal, :slow, :fast];
        return sequence[index % 5];
    }
}
