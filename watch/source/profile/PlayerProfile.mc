using Toybox.Lang;

class PlayerProfile {
    public static const STORAGE_KEY = "shiftsense.player_profile.v1";
    private var mAge = null;
    private var mTestedHrMax = null;
    private var mGarminHrMax = null;
    private var mGarminSnapshot = null;

    public function initialize(age, testedHrMax, garminHrMax) {
        mAge = age;
        mTestedHrMax = testedHrMax;
        mGarminHrMax = garminHrMax;
    }

    public static function forTest(age, testedHrMax, garminHrMax) as PlayerProfile {
        return new PlayerProfile(age, testedHrMax, garminHrMax);
    }

    public static function defaultProfile() as PlayerProfile {
        return new PlayerProfile(30, null, null);
    }

    public function getAge() {
        return mAge;
    }

    public function getTestedHrMax() {
        return mTestedHrMax;
    }

    public function getGarminHrMax() {
        return mGarminHrMax;
    }

    public function withAge(age) as PlayerProfile {
        return new PlayerProfile(age, mTestedHrMax, mGarminHrMax);
    }

    public function withTestedHrMax(testedHrMax) as PlayerProfile {
        return new PlayerProfile(mAge, testedHrMax, mGarminHrMax);
    }

    public function withGarminHrMax(garminHrMax) as PlayerProfile {
        return new PlayerProfile(mAge, mTestedHrMax, garminHrMax);
    }

    public function withGarminSnapshot(snapshot) as PlayerProfile {
        var importedAge = snapshot != null && snapshot[:age] != null ? snapshot[:age] : mAge;
        var importedHrMax = snapshot != null && snapshot[:hrMax] != null ? snapshot[:hrMax] : mGarminHrMax;
        // A locally entered age and tested HRmax remain authoritative.
        var profile = new PlayerProfile(mTestedHrMax != null ? mAge : importedAge,
            mTestedHrMax, importedHrMax);
        profile.setGarminSnapshot(snapshot);
        return profile;
    }

    public function getGarminSnapshot() { return mGarminSnapshot; }
    public function setGarminSnapshot(snapshot) as Void { mGarminSnapshot = snapshot; }

    public function resolveHrMax() {
        if (mTestedHrMax != null) {
            return mTestedHrMax;
        }
        return mGarminHrMax != null ? mGarminHrMax : 220 - mAge;
    }

    public function getHrMaxSource() as Lang.Symbol {
        if (mTestedHrMax != null) {
            return :tested;
        }
        return mGarminHrMax != null ? :garmin : :ageBased;
    }

    public function validate() as Lang.Array {
        var errors = [];
        if (!isWithin(mAge, 10, 100)) {
            errors.add("age");
        }
        if (mTestedHrMax != null && !isWithin(mTestedHrMax, 80, 240)) {
            errors.add("testedHrMax");
        }
        if (mGarminHrMax != null && !isWithin(mGarminHrMax, 80, 240)) {
            errors.add("garminHrMax");
        }
        return errors;
    }

    public function serialize() as Lang.String {
        return "v2|" + mAge.toString() + "|" + optionalNumber(mTestedHrMax) + "|" +
            optionalNumber(mGarminHrMax);
    }

    public static function deserialize(value) {
        if (value == null || !(value instanceof Lang.String)) {
            return null;
        }
        try {
            var parts = ["", "", "", ""];
            var partIndex = 0;
            var characters = value.toCharArray();
            for (var index = 0; index < characters.size(); index += 1) {
                var character = characters[index].toString();
                if (character.equals("|")) {
                    partIndex += 1;
                    if (partIndex > 3) {
                        return null;
                    }
                } else {
                    parts[partIndex] = parts[partIndex] + character;
                }
            }
            if (partIndex != 3 || (!parts[0].equals("v1") && !parts[0].equals("v2"))) {
                return null;
            }
            var ageText = parts[1];
            var testedText = parts[2];
            var garminText = parts[3];
            var age = parseNumber(ageText);
            var tested = testedText.equals("") ? null : parseNumber(testedText);
            // V1 stored a fallback value in this column. Treating it as a
            // Garmin value preserves the user's former resolved HRmax during
            // the non-destructive local migration to V2.
            var garmin = garminText.equals("") ? null : parseNumber(garminText);
            if (age == null || (!testedText.equals("") && tested == null) ||
                (!garminText.equals("") && garmin == null)) {
                return null;
            }
            var profile = new PlayerProfile(age, tested, garmin);
            return profile.validate().size() == 0 ? profile : null;
        } catch (ex) {
            return null;
        }
    }

    private static function parseNumber(value) {
        try {
            if (value == null || value.length() == 0) {
                return null;
            }
            var number = 0;
            var characters = value.toCharArray();
            for (var index = 0; index < characters.size(); index += 1) {
                var digit = characters[index].toString().toNumber();
                if (digit == null || digit < 0 || digit > 9) {
                    return null;
                }
                number = (number * 10) + digit;
            }
            return number;
        } catch (ex) {
            return null;
        }
    }

    private function isWithin(value, minimum, maximum) as Lang.Boolean {
        if (value == null) {
            return false;
        }
        try {
            return value.toNumber() == value && value >= minimum && value <= maximum;
        } catch (ex) {
            return false;
        }
    }

    private function optionalNumber(value) as Lang.String {
        return value == null ? "" : value.toString();
    }
}
