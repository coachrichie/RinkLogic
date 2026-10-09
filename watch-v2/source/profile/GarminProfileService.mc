using Toybox;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.UserProfile;

class GarminProfileService {
    function read() as Lang.Dictionary {
        var raw = {};
        try {
            var profile = UserProfile.getProfile();
            if (profile != null) {
                raw[:birthYear] = profile.birthYear;
                raw[:weightGrams] = profile.weight;
                raw[:heightCm] = profile.height;
                raw[:restingHr] = profile.restingHeartRate;
            }
        } catch (ex) { }
        try {
            var zones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
            if (zones != null && zones.size() >= 6) {
                raw[:hrMax] = zones[5];
                raw[:hrZones] = zones;
            }
        } catch (ex) { }
        return normalize(raw, Gregorian.info(Time.now(), Time.FORMAT_SHORT).year);
    }

    static function normalize(raw as Lang.Dictionary, currentYear as Lang.Number) as Lang.Dictionary {
        var available = {:age=>false, :weightKg=>false, :heightCm=>false,
            :restingHr=>false, :hrMax=>false, :hrZones=>false};
        var result = {:age=>null, :weightKg=>null, :heightCm=>null,
            :restingHr=>null, :hrMax=>null, :hrZones=>null, :available=>available};
        if (raw == null) { return result; }
        var birthYear = raw.hasKey(:birthYear) ? raw[:birthYear] : null;
        var age = birthYear == null ? null : currentYear - birthYear;
        if (valid(age, 10, 100)) { result[:age] = age; available[:age] = true; }
        var grams = raw.hasKey(:weightGrams) ? raw[:weightGrams] : null;
        if (valid(grams, 25000, 300000)) { result[:weightKg] = grams / 1000.0; available[:weightKg] = true; }
        var height = raw.hasKey(:heightCm) ? raw[:heightCm] : null;
        if (valid(height, 80, 250)) { result[:heightCm] = height; available[:heightCm] = true; }
        var resting = raw.hasKey(:restingHr) ? raw[:restingHr] : null;
        if (valid(resting, 25, 180)) { result[:restingHr] = resting; available[:restingHr] = true; }
        var maximum = raw.hasKey(:hrMax) ? raw[:hrMax] : null;
        if (valid(maximum, 80, 240)) { result[:hrMax] = maximum; available[:hrMax] = true; }
        var zones = raw.hasKey(:hrZones) ? raw[:hrZones] : null;
        if (zones != null && zones.size() >= 6) { result[:hrZones] = zones; available[:hrZones] = true; }
        return result;
    }

    private static function valid(value, lower, upper) as Lang.Boolean {
        try { return value != null && value >= lower && value <= upper; }
        catch (ex) { return false; }
    }
}
