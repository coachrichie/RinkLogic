using Toybox.Lang;
using Toybox.Test as Test;

(:test)
function testedHrMaxWins(logger as Test.Logger) as Lang.Boolean {
    var profile = PlayerProfile.forTest(42, 188, 181);
    return profile.resolveHrMax() == 188;
}

(:test)
function garminHrMaxIsUsedWhenNoTestedValueExists(logger as Test.Logger) as Lang.Boolean {
    var profile = PlayerProfile.forTest(42, null, 181);
    return profile.resolveHrMax() == 181;
}

(:test)
function invalidProfileExplainsTheBadAge(logger as Test.Logger) as Lang.Boolean {
    var profile = PlayerProfile.forTest(9, 188, 181);
    return profile.validate().size() == 1 && profile.validate()[0].equals("age");
}

(:test)
function serialisedProfileRoundTripsWithoutLosingHrPriority(logger as Test.Logger) as Lang.Boolean {
    var original = PlayerProfile.forTest(42, 188, 181);
    var restored = PlayerProfile.deserialize(original.serialize());
    return restored != null && restored.resolveHrMax() == 188 &&
        restored.validate().size() == 0;
}

(:test)
function malformedStoredProfileIsRejected(logger as Test.Logger) as Lang.Boolean {
    return PlayerProfile.deserialize("not-a-profile") == null;
}

(:test)
function changingAgeKeepsTheTestedAndGarminHrMaxValues(logger as Test.Logger) as Lang.Boolean {
    var profile = PlayerProfile.forTest(42, 188, 181).withAge(43);
    return profile.getAge() == 43 && profile.resolveHrMax() == 188 &&
        profile.serialize().equals("v2|43|188|181");
}

(:test)
function garminHrMaxWinsWhenNoTestedValueExists(logger as Test.Logger) as Lang.Boolean {
    var profile = PlayerProfile.forTest(42, null, 181);
    return profile.resolveHrMax() == 181 && profile.getHrMaxSource() == :garmin;
}

(:test)
function ageBasedHrMaxIsUsedOnlyWhenTestedAndGarminValuesAreAbsent(logger as Test.Logger) as Lang.Boolean {
    var profile = PlayerProfile.forTest(42, null, null);
    return profile.resolveHrMax() == 178 && profile.getHrMaxSource() == :ageBased;
}

(:test)
function invalidGarminHrMaxIsReportedSeparately(logger as Test.Logger) as Lang.Boolean {
    var profile = PlayerProfile.forTest(42, null, 241);
    return profile.validate().size() == 1 && profile.validate()[0].equals("garminHrMax");
}

(:test)
function testedHrMaxCanBeEditedWithoutReplacingGarminProfileValue(logger as Test.Logger) as Lang.Boolean {
    var profile = PlayerProfile.forTest(42, null, 181).withTestedHrMax(190);
    return profile.resolveHrMax() == 190 && profile.getHrMaxSource() == :tested &&
        profile.getGarminHrMax() == 181;
}

(:test)
function garminAdapterUsesTheHighestConfiguredZoneAsHrMax(logger as Test.Logger) as Lang.Boolean {
    return GarminProfileAdapter.maxFromZones([100, 120, 140, 160, 175, 188]) == 188 &&
        GarminProfileAdapter.maxFromZones([100, 120]) == null;
}
