using Toybox.Lang;

class CalibrationTypes {
    static function validSport(sport) as Lang.Boolean {
        return sport == :ice || sport == :inline;
    }

    static function validCondition(condition) as Lang.Boolean {
        return condition == :skate_only || condition == :puck_stickhandling;
    }
}
