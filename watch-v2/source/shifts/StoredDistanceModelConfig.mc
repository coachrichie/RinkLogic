using Toybox.Lang;

class StoredDistanceModelConfig {
    private var mBase;
    private var mProfileStore;
    private var mActive = null;
    private var mSelectedSport = null;

    function initialize(baseConfig, profileStore) {
        mBase = baseConfig;
        mProfileStore = profileStore;
    }

    function selectSport(sport) as Lang.Boolean {
        mActive = null;
        mSelectedSport = null;
        if (!CalibrationTypes.validSport(sport)) { return false; }
        mSelectedSport = sport;
        try {
            var loaded = mProfileStore == null ? null : mProfileStore.loadForSport(sport);
            if (validProfile(loaded) && loaded[:sport] == sport) {
                mActive = copyProfile(loaded);
            }
        } catch (ex) { mActive = null; }
        return true;
    }

    function selectedSport() { return mSelectedSport; }

    function mode() as Lang.Symbol {
        return mActive == null ? baselineMode() : :calibrated_profile_test;
    }

    function personalCalibrationFactor() as Lang.Float {
        return mActive == null ? 1.0 : mActive[:factor].toFloat();
    }

    function calibrationSource() as Lang.Symbol {
        return mActive == null ? :none : :local_known_distance;
    }

    function activeProfile() {
        return mActive == null ? null : copyProfile(mActive);
    }

    function baselineMode() as Lang.Symbol {
        try {
            var mode = mBase.mode();
            return mode == :profile_height ? :profile_height : :fixed;
        } catch (ex) { return :fixed; }
    }

    private function validProfile(profile) as Lang.Boolean {
        try {
            if (!(profile instanceof Lang.Dictionary) ||
                !profile.hasKey(:schemaVersion) || profile[:schemaVersion] != 1 ||
                !profile.hasKey(:sport) || !CalibrationTypes.validSport(profile[:sport]) ||
                !profile.hasKey(:factor) || !validFactor(profile[:factor]) ||
                !profile.hasKey(:source) || profile[:source] != :local_known_distance ||
                !profile.hasKey(:referenceDistanceCm) ||
                !CalibrationTypes.validReferenceDistance(profile[:referenceDistanceCm]) ||
                !profile.hasKey(:conditionMedians) ||
                !(profile[:conditionMedians] instanceof Lang.Dictionary) ||
                !profile[:conditionMedians].hasKey(:skate_only) ||
                !profile[:conditionMedians].hasKey(:puck_stickhandling) ||
                !validFactor(profile[:conditionMedians][:skate_only]) ||
                !validFactor(profile[:conditionMedians][:puck_stickhandling])) {
                return false;
            }
            return true;
        } catch (ex) { return false; }
    }

    private function validFactor(value) as Lang.Boolean {
        try {
            var factor = value.toFloat();
            return factor == factor && factor >= 0.50 && factor <= 1.50;
        } catch (ex) { return false; }
    }

    private function copyProfile(profile) as Lang.Dictionary {
        return {:schemaVersion=>profile[:schemaVersion], :sport=>profile[:sport],
            :factor=>profile[:factor].toFloat(), :source=>profile[:source],
            :referenceDistanceCm=>profile[:referenceDistanceCm],
            :conditionMedians=>{
                :skate_only=>profile[:conditionMedians][:skate_only].toFloat(),
                :puck_stickhandling=>
                    profile[:conditionMedians][:puck_stickhandling].toFloat()
            }};
    }
}
