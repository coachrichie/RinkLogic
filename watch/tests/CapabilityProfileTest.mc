using Toybox.Lang;
using Toybox.Test as Test;

(:test)
function reducedModeNeedsNoGyro(logger as Test.Logger) as Lang.Boolean {
    var profile = CapabilityProfile.fromFlags(true, false, true, true);
    return profile[:fullAnalysis] == false && profile[:position] == true;
}

(:test)
function fullModeRequiresHighRateAccelerationAndGyro(logger as Test.Logger) as Lang.Boolean {
    var profile = CapabilityProfile.fromFlags(true, true, false, false);
    return profile[:highRateAccel] == true && profile[:gyro] == true && profile[:fullAnalysis] == true;
}

(:test)
function capabilityProfilesAlwaysExposeTheCompatibilityKeys(logger as Test.Logger) as Lang.Boolean {
    var profile = CapabilityProfile.fromFlags(false, false, false, false);
    return profile.hasKey(:highRateAccel) &&
        profile.hasKey(:gyro) &&
        profile.hasKey(:position) &&
        profile.hasKey(:trainingEffect) &&
        profile.hasKey(:touch) &&
        profile.hasKey(:fullAnalysis);
}

(:test)
function hockeyModeConstantsKeepTheThreeRecordingModes(logger as Test.Logger) as Lang.Boolean {
    return HockeyMode.ICE == :ice &&
        HockeyMode.INLINE_INDOOR == :inlineIndoor &&
        HockeyMode.INLINE_OUTDOOR == :inlineOutdoor;
}

(:test)
function detectedProfileAlwaysIncludesEveryCompatibilityKey(logger as Test.Logger) as Lang.Boolean {
    var profile = CapabilityProfile.detect();
    return profile.hasKey(:highRateAccel) &&
        profile.hasKey(:gyro) &&
        profile.hasKey(:position) &&
        profile.hasKey(:trainingEffect) &&
        profile.hasKey(:touch) &&
        profile.hasKey(:fullAnalysis);
}

class SensorAdapterTestHelper {
    function ignoredSensorData(data) as Void {
    }

    function startsAndStopsAReducedProfile() as Lang.Boolean {
        var adapter = new SensorAdapter();
        adapter.start(method(:ignoredSensorData), CapabilityProfile.fromFlags(false, false, false, false));
        adapter.stop();
        return true;
    }

    function registersAndDeregistersAFullProfileTwice() as Lang.Boolean {
        var adapter = new SensorAdapter();
        var profile = CapabilityProfile.fromFlags(true, true, false, false);
        adapter.start(method(:ignoredSensorData), profile);
        adapter.stop();
        adapter.start(method(:ignoredSensorData), profile);
        adapter.stop();
        return true;
    }

    function registersAndDeregistersAReducedGyroProfileTwice() as Lang.Boolean {
        var adapter = new SensorAdapter();
        var profile = CapabilityProfile.fromFlags(true, false, false, false);
        adapter.start(method(:ignoredSensorData), profile);
        adapter.stop();
        adapter.start(method(:ignoredSensorData), profile);
        adapter.stop();
        return true;
    }
}

class HeartRateDataFake {
    var heartBeatIntervals;
    function initialize(values) { heartBeatIntervals = values; }
}

class SensorDataWithRrFake {
    var heartRateData;
    function initialize(values) { heartRateData = new HeartRateDataFake(values); }
}

(:test)
function sensorAdapterCanStartAndStopAReducedProfile(logger as Test.Logger) as Lang.Boolean {
    return new SensorAdapterTestHelper().startsAndStopsAReducedProfile();
}

(:test)
function sensorAdapterRegistersAndDeregistersAFullProfile(logger as Test.Logger) as Lang.Boolean {
    return new SensorAdapterTestHelper().registersAndDeregistersAFullProfileTwice();
}

(:test)
function sensorAdapterRegistersWithoutGyro(logger as Test.Logger) as Lang.Boolean {
    return new SensorAdapterTestHelper().registersAndDeregistersAReducedGyroProfileTwice();
}

(:test)
function sensorAdapterReadsLatestRrFromDocumentedHeartRateData(logger as Test.Logger) as Lang.Boolean {
    var sample = SensorAdapter.normalizeSample(new SensorDataWithRrFake([810, 805, 800]));
    return sample[:rrMs] == 800 && sample[:quality] == :rrOnly;
}

(:test)
function garminProfileImportNormalizesCompleteProfile(logger as Test.Logger) as Lang.Boolean {
    var snapshot = GarminProfileAdapter.normalizeProfile({
        :birthYear=>1983, :gender=>:male, :height=>181.0, :weight=>82500,
        :restingHeartRate=>52, :hrMax=>191, :hrZones=>[100, 120, 140, 160, 180, 191]
    }, 2026);
    return snapshot[:age] == 43 && snapshot[:gender] == :male &&
        snapshot[:heightCm] == 181 && snapshot[:weightKg] == 82.5 &&
        snapshot[:restingHr] == 52 && snapshot[:hrMax] == 191 &&
        snapshot[:hrZones].size() == 6 && snapshot[:availability][:weight] == true;
}

(:test)
function garminProfileImportRejectsInvalidValuesButKeepsValidData(logger as Test.Logger) as Lang.Boolean {
    var snapshot = GarminProfileAdapter.normalizeProfile({
        :birthYear=>1900, :height=>-1, :weight=>500, :restingHeartRate=>0,
        :hrMax=>301, :hrZones=>null
    }, 2026);
    return snapshot[:age] == null && snapshot[:heightCm] == null &&
        snapshot[:weightKg] == null && snapshot[:restingHr] == null &&
        snapshot[:hrMax] == null && snapshot[:availability][:age] == false;
}

(:test)
function playerProfileImportsGarminSnapshotWithoutOverwritingTestedHrMax(logger as Test.Logger) as Lang.Boolean {
    var local = PlayerProfile.forTest(43, 198, 191);
    var imported = local.withGarminSnapshot({:age=>44, :hrMax=>190, :weightKg=>82.5, :restingHr=>52});
    return imported.getAge() == 43 && imported.resolveHrMax() == 198 &&
        imported.getGarminSnapshot()[:weightKg] == 82.5 &&
        imported.getGarminSnapshot()[:restingHr] == 52;
}
