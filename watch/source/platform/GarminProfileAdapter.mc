using Toybox;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.UserProfile;

// Uses UserProfile.getHeartRateZones(), documented since API 1.2.6.  The
// app asks for the generic sport zones and treats their zone-5 ceiling as a
// profile HRmax only when the device returns a valid six-value array.
class GarminProfileAdapter {
    public static function readProfile() as Lang.Dictionary {
        var raw = {};
        var currentYear = Gregorian.info(Time.now(), Time.FORMAT_SHORT).year;
        try {
            if ((Toybox has :UserProfile) && (UserProfile has :getProfile)) {
                var profile = UserProfile.getProfile();
                if (profile != null) {
                    raw[:birthYear] = profile.birthYear;
                    raw[:gender] = profile.gender;
                    raw[:height] = profile.height;
                    raw[:weight] = profile.weight;
                    raw[:restingHeartRate] = profile.restingHeartRate;
                }
            }
            raw[:hrMax] = readHrMax();
            if ((Toybox has :UserProfile) && (UserProfile has :getHeartRateZones) &&
                (UserProfile has :HR_ZONE_SPORT_GENERIC)) {
                raw[:hrZones] = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
            }
        } catch (ex) {
        }
        return normalizeProfile(raw, currentYear);
    }

    public static function normalizeProfile(raw as Lang.Dictionary, currentYear as Lang.Number) as Lang.Dictionary {
        var availability = {:age=>false, :gender=>false, :height=>false, :weight=>false,
            :restingHr=>false, :hrMax=>false, :hrZones=>false};
        var snapshot = {:age=>null, :gender=>null, :heightCm=>null, :weightKg=>null,
            :restingHr=>null, :hrMax=>null, :hrZones=>null, :availability=>availability};
        if (raw == null) { return snapshot; }
        var birthYear = raw.hasKey(:birthYear) ? raw[:birthYear] : null;
        var age = birthYear == null ? null : currentYear - birthYear;
        if (age != null && age >= 10 && age <= 100) {
            snapshot[:age] = age;
            availability[:age] = true;
        }
        var gender = raw.hasKey(:gender) ? raw[:gender] : null;
        var height = raw.hasKey(:height) ? raw[:height] : null;
        var weight = raw.hasKey(:weight) ? raw[:weight] : null;
        var restingHr = raw.hasKey(:restingHeartRate) ? raw[:restingHeartRate] : null;
        var hrMax = raw.hasKey(:hrMax) ? raw[:hrMax] : null;
        if (gender != null) { snapshot[:gender] = gender; availability[:gender] = true; }
        if (validNumber(height, 80, 250)) { snapshot[:heightCm] = height.toNumber(); availability[:height] = true; }
        // UserProfile.Profile.weight is documented in grams.
        if (validNumber(weight, 25000, 300000)) { snapshot[:weightKg] = weight / 1000.0; availability[:weight] = true; }
        if (validNumber(restingHr, 25, 180)) { snapshot[:restingHr] = restingHr.toNumber(); availability[:restingHr] = true; }
        if (validNumber(hrMax, 80, 240)) { snapshot[:hrMax] = hrMax.toNumber(); availability[:hrMax] = true; }
        var zones = raw.hasKey(:hrZones) ? raw[:hrZones] : null;
        if (zones != null && zones.size() >= 6) { snapshot[:hrZones] = zones; availability[:hrZones] = true; }
        return snapshot;
    }

    private static function validNumber(value, minimum, maximum) as Lang.Boolean {
        try { return value != null && value >= minimum && value <= maximum; }
        catch (ex) { return false; }
    }

    public static function readHrMax() {
        if (!(Toybox has :UserProfile) || !(UserProfile has :getHeartRateZones) ||
            !(UserProfile has :HR_ZONE_SPORT_GENERIC)) {
            return null;
        }
        try {
            return maxFromZones(UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC));
        } catch (ex) {
            return null;
        }
    }

    public static function maxFromZones(zones) {
        if (zones == null || zones.size() < 6) {
            return null;
        }
        var candidate = zones[5];
        try {
            return candidate != null && candidate >= 80 && candidate <= 240 ? candidate : null;
        } catch (ex) {
            return null;
        }
    }
}
