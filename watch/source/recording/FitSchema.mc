using Toybox.FitContributor;
using Toybox.Lang;

class FitSchema {
    public static const VERSION = 3;
    public static const MAX_RECORD_PAYLOAD_BYTES = 256;

    public static function getFields() as Lang.Array {
        return [
            // One-second record fields (26 bytes total).
            {:id=>1, :key=>:schemaVersion, :name=>"schema_version", :scope=>:record, :type=>:uint8, :unit=>"version", :bytes=>1},
            {:id=>2, :key=>:hockeyMode, :name=>"hockey_mode", :scope=>:record, :type=>:uint8, :unit=>"enum", :bytes=>1},
            {:id=>3, :key=>:shiftState, :name=>"shift_state", :scope=>:record, :type=>:uint8, :unit=>"enum", :bytes=>1},
            {:id=>4, :key=>:shiftSource, :name=>"shift_source", :scope=>:record, :type=>:uint8, :unit=>"enum", :bytes=>1},
            {:id=>5, :key=>:shiftConfidence, :name=>"shift_confidence", :scope=>:record, :type=>:uint8, :unit=>"percent", :bytes=>1},
            {:id=>6, :key=>:movementIntensity, :name=>"movement_intensity", :scope=>:record, :type=>:uint16, :unit=>"au_x100", :bytes=>2},
            {:id=>7, :key=>:qualityFlags, :name=>"quality_flags", :scope=>:record, :type=>:uint16, :unit=>"bitmask", :bytes=>2},
            {:id=>8, :key=>:hrSource, :name=>"hr_source", :scope=>:record, :type=>:uint8, :unit=>"enum", :bytes=>1},
            {:id=>9, :key=>:estimatedDistanceCm, :name=>"estimated_distance_cm", :scope=>:record, :type=>:uint32, :unit=>"cm", :bytes=>4},
            {:id=>10, :key=>:propulsionCount, :name=>"propulsion_count", :scope=>:record, :type=>:uint16, :unit=>"count", :bytes=>2},
            {:id=>11, :key=>:propulsionCadence, :name=>"propulsion_cadence", :scope=>:record, :type=>:uint16, :unit=>"pushes_per_min", :bytes=>2},
            {:id=>12, :key=>:strideLengthCm, :name=>"stride_length_cm", :scope=>:record, :type=>:uint16, :unit=>"cm", :bytes=>2},
            {:id=>13, :key=>:glidePushRatio, :name=>"glide_push_ratio", :scope=>:record, :type=>:uint16, :unit=>"ratio_x1000", :bytes=>2},
            {:id=>14, :key=>:impactMg, :name=>"impact_mg", :scope=>:record, :type=>:uint16, :unit=>"mg", :bytes=>2},
            {:id=>15, :key=>:sensorGapMs, :name=>"sensor_gap_ms", :scope=>:record, :type=>:uint16, :unit=>"ms", :bytes=>2},

            // One FIT lap is emitted for each manual or classified shift boundary.
            {:id=>16, :key=>:shiftIndex, :name=>"shift_index", :scope=>:lap, :type=>:uint16, :unit=>"count", :bytes=>2},
            {:id=>17, :key=>:shiftState, :name=>"lap_shift_state", :scope=>:lap, :type=>:uint8, :unit=>"enum", :bytes=>1},
            {:id=>18, :key=>:shiftTimestampMs, :name=>"shift_timestamp_ms", :scope=>:lap, :type=>:uint32, :unit=>"ms", :bytes=>4},
            {:id=>19, :key=>:shiftDurationMs, :name=>"shift_duration_ms", :scope=>:lap, :type=>:uint32, :unit=>"ms", :bytes=>4},
            {:id=>20, :key=>:shiftConfidence, :name=>"lap_shift_confidence", :scope=>:lap, :type=>:uint8, :unit=>"percent", :bytes=>1},
            {:id=>21, :key=>:shiftSource, :name=>"lap_shift_source", :scope=>:lap, :type=>:uint8, :unit=>"enum", :bytes=>1},
            {:id=>22, :key=>:movementIntensity, :name=>"lap_movement_intensity", :scope=>:lap, :type=>:uint16, :unit=>"au_x100", :bytes=>2},
            {:id=>23, :key=>:qualityFlags, :name=>"lap_quality_flags", :scope=>:lap, :type=>:uint16, :unit=>"bitmask", :bytes=>2},

            // Session summary fields.
            {:id=>24, :key=>:schemaVersion, :name=>"session_schema_version", :scope=>:session, :type=>:uint8, :unit=>"version", :bytes=>1},
            {:id=>25, :key=>:hockeyMode, :name=>"session_hockey_mode", :scope=>:session, :type=>:uint8, :unit=>"enum", :bytes=>1},
            {:id=>26, :key=>:shiftCount, :name=>"session_shift_count", :scope=>:session, :type=>:uint16, :unit=>"count", :bytes=>2},
            {:id=>27, :key=>:iceTimeMs, :name=>"session_ice_time_ms", :scope=>:session, :type=>:uint32, :unit=>"ms", :bytes=>4},
            {:id=>28, :key=>:benchTimeMs, :name=>"session_bench_time_ms", :scope=>:session, :type=>:uint32, :unit=>"ms", :bytes=>4},
            {:id=>29, :key=>:estimatedDistanceCm, :name=>"session_estimated_distance_cm", :scope=>:session, :type=>:uint32, :unit=>"cm", :bytes=>4},
            {:id=>30, :key=>:qualityFlags, :name=>"session_quality_flags", :scope=>:session, :type=>:uint16, :unit=>"bitmask", :bytes=>2},
            {:id=>31, :key=>:calibrationVersion, :name=>"calibration_version", :scope=>:session, :type=>:uint8, :unit=>"version", :bytes=>1},
            {:id=>32, :key=>:hits, :name=>"manual_hits", :scope=>:session, :type=>:uint16, :unit=>"count", :bytes=>2},
            {:id=>33, :key=>:passes, :name=>"manual_passes", :scope=>:session, :type=>:uint16, :unit=>"count", :bytes=>2},
            {:id=>34, :key=>:shots, :name=>"manual_shots", :scope=>:session, :type=>:uint16, :unit=>"count", :bytes=>2},
            {:id=>35, :key=>:hrSampleCount, :name=>"hr_sample_count", :scope=>:session, :type=>:uint32, :unit=>"count", :bytes=>4},
            {:id=>36, :key=>:recoveryMs, :name=>"hr_recovery_ms", :scope=>:session, :type=>:uint32, :unit=>"ms", :bytes=>4},
            {:id=>37, :key=>:hrZone0Seconds, :name=>"hr_zone0_seconds", :scope=>:session, :type=>:uint32, :unit=>"s", :bytes=>4},
            {:id=>38, :key=>:hrZone1Seconds, :name=>"hr_zone1_seconds", :scope=>:session, :type=>:uint32, :unit=>"s", :bytes=>4},
            {:id=>39, :key=>:hrZone2Seconds, :name=>"hr_zone2_seconds", :scope=>:session, :type=>:uint32, :unit=>"s", :bytes=>4},
            {:id=>40, :key=>:hrZone3Seconds, :name=>"hr_zone3_seconds", :scope=>:session, :type=>:uint32, :unit=>"s", :bytes=>4},
            {:id=>41, :key=>:hrZone4Seconds, :name=>"hr_zone4_seconds", :scope=>:session, :type=>:uint32, :unit=>"s", :bytes=>4},
            {:id=>42, :key=>:hrZone5Seconds, :name=>"hr_zone5_seconds", :scope=>:session, :type=>:uint32, :unit=>"s", :bytes=>4}
        ];
    }

    public static function isCore(id) as Lang.Boolean {
        return id <= 3 || (id >= 16 && id <= 18) ||
            (id >= 24 && id <= 28) || (id >= 32 && id <= 34);
    }

    public static function hasOnlyUniqueIds() as Lang.Boolean {
        var ids = {};
        var fields = getFields();
        for (var index = 0; index < fields.size(); index += 1) {
            var field = fields[index];
            if (ids.hasKey(field[:id])) {
                return false;
            }
            ids[field[:id]] = true;
        }
        return true;
    }

    public static function usesStableIdRange(firstId as Lang.Number, lastId as Lang.Number) as Lang.Boolean {
        var ids = {};
        var fields = getFields();
        for (var index = 0; index < fields.size(); index += 1) {
            var field = fields[index];
            ids[field[:id]] = true;
        }
        for (var id = firstId; id <= lastId; id += 1) {
            if (!ids.hasKey(id)) {
                return false;
            }
        }
        return getFields().size() == ((lastId - firstId) + 1);
    }

    public static function getRecordPayloadBytes() as Lang.Number {
        var bytes = 0;
        var fields = getFields();
        for (var index = 0; index < fields.size(); index += 1) {
            var field = fields[index];
            if (field[:scope] == :record) {
                bytes += field[:bytes];
            }
        }
        return bytes;
    }

    public static function typeFor(fieldType as Lang.Symbol) {
        if (fieldType == :uint8) { return FitContributor.DATA_TYPE_UINT8; }
        if (fieldType == :uint16) { return FitContributor.DATA_TYPE_UINT16; }
        return FitContributor.DATA_TYPE_UINT32;
    }

    public static function messageTypeFor(scope as Lang.Symbol) {
        if (scope == :lap) { return FitContributor.MESG_TYPE_LAP; }
        if (scope == :session) { return FitContributor.MESG_TYPE_SESSION; }
        return FitContributor.MESG_TYPE_RECORD;
    }

    // Monkey C Number is signed 32-bit on the first compatibility wave. A
    // UINT32 developer field therefore accepts the largest lossless value the
    // runtime can represent; larger values must be split or scaled by callers.
    public static function valueIsInRange(definition as Lang.Dictionary, value) as Lang.Boolean {
        if (value == null) {
            return false;
        }
        try {
            var integerValue = value.toNumber();
            if (integerValue != value || integerValue < 0) {
                return false;
            }
            if (definition[:type] == :uint8) {
                return integerValue <= 255;
            }
            if (definition[:type] == :uint16) {
                return integerValue <= 65535;
            }
            return integerValue <= 2147483647;
        } catch (ex) {
            return false;
        }
    }
}
