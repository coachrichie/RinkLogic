using Toybox.FitContributor;
using Toybox.Lang;

class SystemShadowWriterFactory {
    function create(session) { return new ShadowFitWriter(session); }
}

class ShadowFitWriter {
    private var mSession;
    private var mFields;
    private var mAllocated = false;

    function initialize(session) { mSession = session; mFields = {}; }

    function allocate() as Lang.Boolean {
        if (mAllocated) { return true; }
        if (mSession == null || !(mSession has :createField)) { return false; }
        try {
            if (!addField(51, "manual_boundary_ms", FitContributor.DATA_TYPE_UINT32, FitContributor.MESG_TYPE_LAP, "ms") ||
                !addField(52, "manual_boundary_state", FitContributor.DATA_TYPE_UINT8, FitContributor.MESG_TYPE_LAP, "enum") ||
                !addField(55, "auto_boundary_ms", FitContributor.DATA_TYPE_UINT32, FitContributor.MESG_TYPE_LAP, "ms") ||
                !addField(56, "auto_boundary_state", FitContributor.DATA_TYPE_UINT8, FitContributor.MESG_TYPE_LAP, "enum") ||
                !addField(62, "push_count_total", FitContributor.DATA_TYPE_UINT32, FitContributor.MESG_TYPE_RECORD, "pushes") ||
                !addField(63, "estimated_distance_cm_total", FitContributor.DATA_TYPE_UINT32, FitContributor.MESG_TYPE_RECORD, "cm") ||
                !addField(65, "shift_push_count", FitContributor.DATA_TYPE_UINT16, FitContributor.MESG_TYPE_LAP, "pushes") ||
                !addField(66, "shift_estimated_distance_cm", FitContributor.DATA_TYPE_UINT32, FitContributor.MESG_TYPE_LAP, "cm") ||
                !addField(71, "shift_short_push_count", FitContributor.DATA_TYPE_UINT16, FitContributor.MESG_TYPE_LAP, "pushes") ||
                !addField(72, "shift_motion_coverage_percent", FitContributor.DATA_TYPE_UINT8, FitContributor.MESG_TYPE_LAP, "percent") ||
                !addField(73, "summary_schema_version", FitContributor.DATA_TYPE_UINT8, FitContributor.MESG_TYPE_RECORD, "version") ||
                !addField(74, "shift_count", FitContributor.DATA_TYPE_UINT8, FitContributor.MESG_TYPE_SESSION, "shifts") ||
                !addField(75, "time_on_ice", FitContributor.DATA_TYPE_UINT16, FitContributor.MESG_TYPE_SESSION, "s") ||
                !addField(76, "bench_time", FitContributor.DATA_TYPE_UINT16, FitContributor.MESG_TYPE_SESSION, "s") ||
                !addField(77, "average_shift_duration", FitContributor.DATA_TYPE_UINT8, FitContributor.MESG_TYPE_SESSION, "s") ||
                !addField(78, "average_shift_heart_rate", FitContributor.DATA_TYPE_UINT8, FitContributor.MESG_TYPE_SESSION, "bpm") ||
                !addField(79, "heart_rate_zone_1_time", FitContributor.DATA_TYPE_UINT16, FitContributor.MESG_TYPE_SESSION, "s") ||
                !addField(80, "heart_rate_zone_2_time", FitContributor.DATA_TYPE_UINT16, FitContributor.MESG_TYPE_SESSION, "s") ||
                !addField(81, "heart_rate_zone_3_time", FitContributor.DATA_TYPE_UINT16, FitContributor.MESG_TYPE_SESSION, "s") ||
                !addField(82, "heart_rate_zone_4_time", FitContributor.DATA_TYPE_UINT16, FitContributor.MESG_TYPE_SESSION, "s") ||
                !addField(83, "heart_rate_zone_5_time", FitContributor.DATA_TYPE_UINT16, FitContributor.MESG_TYPE_SESSION, "s") ||
                !addField(84, "time_above_90_percent_hrmax", FitContributor.DATA_TYPE_UINT16, FitContributor.MESG_TYPE_SESSION, "s") ||
                !addField(85, "work_rest_ratio_tenths", FitContributor.DATA_TYPE_UINT8, FitContributor.MESG_TYPE_SESSION, "ratio_x10") ||
                !addField(86, "shift_density_per_hour", FitContributor.DATA_TYPE_UINT8, FitContributor.MESG_TYPE_SESSION, "shifts_per_hour") ||
                !addField(87, "shortest_shift_duration", FitContributor.DATA_TYPE_UINT8, FitContributor.MESG_TYPE_SESSION, "s") ||
                !addField(88, "longest_shift_duration", FitContributor.DATA_TYPE_UINT8, FitContributor.MESG_TYPE_SESSION, "s") ||
                !addField(89, "median_shift_duration", FitContributor.DATA_TYPE_UINT8, FitContributor.MESG_TYPE_SESSION, "s") ||
                !addField(93, "heart_rate_drop_30", FitContributor.DATA_TYPE_SINT16, FitContributor.MESG_TYPE_LAP, "bpm") ||
                !addField(94, "heart_rate_drop_60", FitContributor.DATA_TYPE_SINT16, FitContributor.MESG_TYPE_LAP, "bpm") ||
                !addField(95, "shift_average_heart_rate", FitContributor.DATA_TYPE_UINT8, FitContributor.MESG_TYPE_LAP, "bpm")) { return false; }
            mFields[73].setData(7);
            clearLapMetrics();
            mAllocated = true;
            return true;
        } catch (ex) { return false; }
    }

    private function addField(id, name, type, messageType, unit) as Lang.Boolean {
        var field = mSession.createField(name, id, type, {:mesgType=>messageType, :units=>unit});
        if (field == null) { return false; }
        mFields[id] = field;
        return true;
    }

    function writeSecond(feature, proposal, manualState, eventBits, sampleSeq, sampleAtMs, pushSnapshot) as Lang.Boolean {
        if (!mAllocated) { return false; }
        try {
            if (pushSnapshot != null) {
                mFields[62].setData(uint32(pushSnapshot[:totalPushes]));
                mFields[63].setData(uint32(pushSnapshot[:totalDistanceCm]));
            }
            return true;
        } catch (ex) { return false; }
    }

    function writeManualBoundary(elapsedMs, state, pushSummary) as Lang.Boolean {
        return writeLap(elapsedMs, state, pushSummary, null, null, null);
    }

    function writeShiftLap(summary, pushSummary) as Lang.Boolean {
        if (summary == null) { return false; }
        return writeLap(summary[:endedAtMs], :bench, pushSummary,
            summary[:heartRateDrop30], summary[:heartRateDrop60], summary[:averageHeartRate]);
    }

    private function writeLap(elapsedMs, state, pushSummary, drop30, drop60, averageHeartRate) as Lang.Boolean {
        if (!mAllocated || elapsedMs == null || elapsedMs < 0 || elapsedMs > 2147483647) { return false; }
        try {
            mFields[51].setData(elapsedMs);
            mFields[52].setData(stateCode(state));
            clearLapMetrics();
            if (state == :bench && pushSummary != null && pushSummary[:hasValidMotion] == true) {
                mFields[65].setData(uint16(pushSummary[:pushes]));
                mFields[66].setData(uint32(pushSummary[:distanceCm]));
                mFields[71].setData(uint16(pushSummary[:shortPushes]));
                mFields[72].setData(coverageOrMissing(pushSummary[:coveragePercent]));
            }
            mFields[93].setData(sint16OrMissing(drop30));
            mFields[94].setData(sint16OrMissing(drop60));
            mFields[95].setData(uint8OrMissing(averageHeartRate));
            var added = mSession.addLap();
            mFields[51].setData(0); mFields[52].setData(0); clearLapMetrics();
            return added;
        } catch (ex) {
            try { mFields[51].setData(0); mFields[52].setData(0); clearLapMetrics(); } catch (cleanupEx) { }
            return false;
        }
    }

    function writeAutoBoundary(elapsedMs, state) as Lang.Boolean {
        if (!mAllocated || elapsedMs == null || elapsedMs < 0 || elapsedMs > 2147483647) { return false; }
        try {
            clearLapMetrics();
            mFields[55].setData(elapsedMs); mFields[56].setData(stateCode(state));
            var added = mSession.addLap();
            mFields[55].setData(0); mFields[56].setData(0); clearLapMetrics();
            return added;
        } catch (ex) { return false; }
    }

    function writeActivitySummary(summary) as Lang.Boolean {
        if (!mAllocated || summary == null) { return false; }
        try {
            mFields[74].setData(uint8OrMissing(summary[:shiftCount]));
            mFields[75].setData(millisecondsOrMissing(summary[:timeOnIceMs]));
            mFields[76].setData(millisecondsOrMissing(summary[:benchTimeMs]));
            mFields[77].setData(millisecondsUint8OrMissing(summary[:averageShiftMs]));
            mFields[78].setData(uint8OrMissing(summary[:averageShiftHeartRate]));
            var zones = summary[:zoneSeconds];
            for (var i = 0; i < 5; i += 1) {
                var zoneValue = zones == null || zones.size() <= i ? null : zones[i];
                mFields[79 + i].setData(uint16StrictOrMissing(zoneValue));
            }
            mFields[84].setData(uint16StrictOrMissing(summary[:overNinetySeconds]));
            mFields[85].setData(uint8OrMissing(summary[:workRestTenths]));
            mFields[86].setData(uint8OrMissing(summary[:shiftDensityPerHour]));
            mFields[87].setData(millisecondsUint8OrMissing(summary[:shortestShiftMs]));
            mFields[88].setData(millisecondsUint8OrMissing(summary[:longestShiftMs]));
            mFields[89].setData(millisecondsUint8OrMissing(summary[:medianShiftMs]));
            return true;
        } catch (ex) { return false; }
    }

    private function uint8OrMissing(value) as Lang.Number {
        if (value == null || value < 0 || value > 254) { return 255; }
        return value.toNumber();
    }
    private function uint16StrictOrMissing(value) as Lang.Number {
        if (value == null || value < 0 || value > 65534) { return 65535; }
        return value.toNumber();
    }
    private function millisecondsOrMissing(value) as Lang.Number {
        if (value == null || value < 0) { return 65535; }
        return uint16StrictOrMissing(value / 1000);
    }
    private function millisecondsUint8OrMissing(value) as Lang.Number {
        if (value == null || value < 0) { return 255; }
        return uint8OrMissing(value / 1000);
    }
    private function sint16OrMissing(value) as Lang.Number {
        if (value == null || value < -32768 || value > 32766) { return 32767; }
        return value.toNumber();
    }
    private function uint16OrMissing(value) as Lang.Number {
        if (value == null || value < 0) { return 65535; }
        if (value > 65534) { return 65534; }
        return value.toNumber();
    }
    private function uint16(value) as Lang.Number {
        if (value == null || value < 0) { return 0; }
        if (value > 65534) { return 65534; }
        return value.toNumber();
    }
    private function uint32(value) as Lang.Number {
        if (value == null || value < 0) { return 0; }
        if (value > 2147483647) { return 2147483647; }
        return value.toNumber();
    }
    private function coverageOrMissing(value) as Lang.Number {
        if (value == null || value < 0 || value > 100) { return 255; }
        return value.toNumber();
    }
    private function clearLapMetrics() as Void {
        mFields[65].setData(65535); mFields[66].setData(4294967295l);
        mFields[71].setData(65535); mFields[72].setData(255);
        mFields[93].setData(32767); mFields[94].setData(32767);
        mFields[95].setData(255);
    }
    private function stateCode(state) as Lang.Number {
        if (state == :on_ice) { return 1; }
        if (state == :bench) { return 2; }
        if (state == :uncertain) { return 3; }
        return 0;
    }
}
