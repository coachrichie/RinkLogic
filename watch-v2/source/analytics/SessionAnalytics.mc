using Toybox.Lang;

class SessionAnalytics {
    private var mStartedAt = null;
    private var mProfile = null;
    private var mBucketSecond = null;
    private var mBucketHeartRate = null;
    private var mBucketAtMs = null;
    private var mHeartRateTotal = 0;
    private var mHeartRateCount = 0;
    private var mMaximumHeartRate = null;
    private var mZoneSeconds = null;
    private var mOverNinetySeconds = null;
    private var mCurrentShift = null;
    private var mShifts;
    private var mSnapshot = null;

    function initialize() {
        mShifts = [{:index=>0, :startedAtMs=>0, :endedAtMs=>0,
            :durationMs=>0, :averageHeartRate=>null, :endHeartRate=>null,
            :endHeartRateAt=>null, :heartRateDrop30=>null,
            :heartRateDrop60=>null, :recoveryDistance30=>null,
            :recoveryDistance60=>null, :recoveryAborted=>false,
            :released=>false}].slice(0, 0);
    }

    function start(startedAtMs, profile) as Void {
        mStartedAt = startedAtMs;
        mProfile = profile;
        if (hasZoneModel()) {
            mZoneSeconds = [0, 0, 0, 0, 0];
        }
        if (validHrMax()) { mOverNinetySeconds = 0; }
    }

    function onHeartRate(atMs, bpm) as Void {
        if (mSnapshot != null || mStartedAt == null || atMs < mStartedAt ||
            bpm == null || bpm < 1 || bpm > 255) { return; }
        var second = (atMs - mStartedAt) / 1000;
        if (mBucketSecond != null && second != mBucketSecond) {
            flushBucket();
        }
        mBucketSecond = second;
        mBucketHeartRate = bpm;
        mBucketAtMs = atMs;
    }

    function onShiftStarted(atMs) as Void {
        if (mSnapshot != null || mStartedAt == null || atMs < mStartedAt ||
            mCurrentShift != null) { return; }
        flushBucket();
        abortPendingRecovery(atMs);
        mCurrentShift = {:startedAtMs=>atMs, :heartRateTotal=>0,
            :heartRateCount=>0, :lastHeartRate=>null, :lastHeartRateAt=>null};
    }

    function onShiftEnded(atMs) as Void {
        if (mSnapshot != null || mCurrentShift == null ||
            atMs <= mCurrentShift[:startedAtMs]) { return; }
        flushBucket();
        var duration = atMs - mCurrentShift[:startedAtMs];
        var fullSeconds = duration / 1000;
        var average = null;
        if (fullSeconds > 0 && mCurrentShift[:heartRateCount] * 100 >=
            fullSeconds * 70) {
            average = mCurrentShift[:heartRateTotal] /
                mCurrentShift[:heartRateCount];
        }
        var endHeartRate = null;
        var endHeartRateAt = null;
        if (mCurrentShift[:lastHeartRateAt] != null &&
            atMs - mCurrentShift[:lastHeartRateAt] <= 5000) {
            endHeartRate = mCurrentShift[:lastHeartRate];
            endHeartRateAt = mCurrentShift[:lastHeartRateAt];
        }
        mShifts.add({:index=>mShifts.size() + 1,
            :startedAtMs=>mCurrentShift[:startedAtMs], :endedAtMs=>atMs,
            :durationMs=>duration, :averageHeartRate=>average,
            :endHeartRate=>endHeartRate, :endHeartRateAt=>endHeartRateAt,
            :heartRateDrop30=>null, :heartRateDrop60=>null,
            :recoveryDistance30=>null, :recoveryDistance60=>null,
            :recoveryAborted=>false, :released=>false});
        mCurrentShift = null;
    }

    function finish(stoppedAtMs) {
        if (mSnapshot != null) { return mSnapshot; }
        if (mCurrentShift != null) { onShiftEnded(stoppedAtMs); }
        flushBucket();
        var duration = mStartedAt == null ? 0 : stoppedAtMs - mStartedAt;
        if (duration < 0) { duration = 0; }
        var iceTime = 0;
        var durations = [0];
        durations.remove(0);
        var shiftHeartRateTotal = 0;
        var shiftHeartRateCount = 0;
        var rankedSeed = {:averageHeartRate=>0, :durationMs=>0,
            :startedAtMs=>0};
        var ranked = [rankedSeed];
        ranked.remove(rankedSeed);
        for (var i = 0; i < mShifts.size(); i += 1) {
            var shift = mShifts[i];
            iceTime += shift[:durationMs];
            durations.add(shift[:durationMs]);
            if (shift[:averageHeartRate] != null) {
                shiftHeartRateTotal += shift[:averageHeartRate];
                shiftHeartRateCount += 1;
                ranked.add(shift);
            }
        }
        sortNumbers(durations);
        sortRankedShifts(ranked);
        var topHeartRates = [0];
        topHeartRates.remove(0);
        var topIndices = [0];
        topIndices.remove(0);
        var topCount = ranked.size() < 3 ? ranked.size() : 3;
        for (var top = 0; top < topCount; top += 1) {
            topHeartRates.add(ranked[top][:averageHeartRate]);
            topIndices.add(ranked[top][:index]);
        }
        var shiftCount = mShifts.size();
        var benchTime = duration - iceTime;
        if (benchTime < 0) { benchTime = 0; }
        var median = null;
        var shortest = null;
        var longest = null;
        if (shiftCount > 0) {
            var middle = shiftCount / 2;
            shortest = durations[0];
            longest = durations[shiftCount - 1];
            if (shiftCount % 2 == 1) { median = durations[middle]; }
            else { median = (durations[middle - 1] + durations[middle]) / 2; }
        }
        mSnapshot = {
            :durationMs=>duration,
            :averageHeartRate=>mHeartRateCount == 0 ? null :
                mHeartRateTotal / mHeartRateCount,
            :maximumHeartRate=>mMaximumHeartRate,
            :shiftCount=>shiftCount,
            :timeOnIceMs=>iceTime,
            :benchTimeMs=>benchTime,
            :averageShiftMs=>shiftCount == 0 ? null : iceTime / shiftCount,
            :longestShiftMs=>longest,
            :shortestShiftMs=>shortest,
            :medianShiftMs=>median,
            :averageShiftHeartRate=>shiftHeartRateCount == 0 ? null :
                shiftHeartRateTotal / shiftHeartRateCount,
            :zoneSeconds=>mZoneSeconds,
            :overNinetySeconds=>mOverNinetySeconds,
            :workRestTenths=>benchTime == 0 ? null : iceTime * 10 / benchTime,
            :shiftDensityPerHour=>duration == 0 ? null :
                (shiftCount * 3600000 + duration / 2) / duration,
            :topShiftHeartRates=>topHeartRates,
            :topShiftIndices=>topIndices
        };
        return mSnapshot;
    }

    function snapshot() { return mSnapshot; }

    function drainReadyShiftLaps(atMs) as Lang.Array {
        var seed = {:index=>0, :endedAtMs=>0, :durationMs=>0,
            :averageHeartRate=>null, :heartRateDrop30=>null,
            :heartRateDrop60=>null};
        var ready = [seed];
        ready.remove(seed);
        for (var i = 0; i < mShifts.size(); i += 1) {
            var shift = mShifts[i];
            if (shift[:released] == true) { continue; }
            if (shift[:recoveryAborted] == true || mSnapshot != null ||
                atMs >= shift[:endedAtMs] + 65000) {
                ready.add({:index=>shift[:index],
                    :endedAtMs=>shift[:endedAtMs],
                    :durationMs=>shift[:durationMs],
                    :averageHeartRate=>shift[:averageHeartRate],
                    :heartRateDrop30=>shift[:heartRateDrop30],
                    :heartRateDrop60=>shift[:heartRateDrop60]});
                shift[:released] = true;
            }
        }
        return ready;
    }

    private function flushBucket() as Void {
        if (mBucketSecond == null || mBucketHeartRate == null) { return; }
        var bpm = mBucketHeartRate;
        mHeartRateTotal += bpm;
        mHeartRateCount += 1;
        if (mMaximumHeartRate == null || bpm > mMaximumHeartRate) {
            mMaximumHeartRate = bpm;
        }
        var zone = zoneFor(bpm);
        if (mZoneSeconds != null && zone >= 1 && zone <= 5) {
            mZoneSeconds[zone - 1] += 1;
        }
        if (mOverNinetySeconds != null && bpm * 100 >= mProfile[:hrMax] * 90) {
            mOverNinetySeconds += 1;
        }
        if (mCurrentShift != null) {
            mCurrentShift[:heartRateTotal] += bpm;
            mCurrentShift[:heartRateCount] += 1;
            mCurrentShift[:lastHeartRate] = bpm;
            mCurrentShift[:lastHeartRateAt] = mBucketAtMs;
        }
        updateRecovery(mBucketAtMs, bpm);
        mBucketSecond = null;
        mBucketHeartRate = null;
        mBucketAtMs = null;
    }

    private function updateRecovery(atMs, bpm) as Void {
        for (var i = 0; i < mShifts.size(); i += 1) {
            var shift = mShifts[i];
            if (shift[:released] == true || shift[:recoveryAborted] == true ||
                shift[:endHeartRate] == null || atMs < shift[:endedAtMs]) {
                continue;
            }
            updateRecoveryTarget(shift, atMs, bpm, 30000,
                :recoveryDistance30, :heartRateDrop30);
            updateRecoveryTarget(shift, atMs, bpm, 60000,
                :recoveryDistance60, :heartRateDrop60);
        }
    }

    private function updateRecoveryTarget(shift, atMs, bpm, offset,
                                          distanceKey, valueKey) as Void {
        var distance = absolute(atMs - (shift[:endedAtMs] + offset));
        if (distance <= 5000 && (shift[distanceKey] == null ||
            distance < shift[distanceKey])) {
            shift[distanceKey] = distance;
            shift[valueKey] = shift[:endHeartRate] - bpm;
        }
    }

    private function abortPendingRecovery(atMs) as Void {
        for (var i = 0; i < mShifts.size(); i += 1) {
            var shift = mShifts[i];
            if (shift[:released] == false && atMs < shift[:endedAtMs] + 65000) {
                shift[:recoveryAborted] = true;
            }
        }
    }

    private function absolute(value) as Lang.Number {
        return value < 0 ? -value : value;
    }

    private function hasZoneModel() as Lang.Boolean {
        return validBoundaries() || validHrMax();
    }

    private function validHrMax() as Lang.Boolean {
        return mProfile != null && mProfile.hasKey(:hrMax) &&
            mProfile[:hrMax] != null && mProfile[:hrMax] >= 80 &&
            mProfile[:hrMax] <= 240;
    }

    private function validBoundaries() as Lang.Boolean {
        if (mProfile == null || !mProfile.hasKey(:hrZones) ||
            mProfile[:hrZones] == null || mProfile[:hrZones].size() < 6) {
            return false;
        }
        var boundaries = mProfile[:hrZones];
        if (boundaries[0] < 25 || boundaries[5] > 240) { return false; }
        for (var i = 1; i <= 5; i += 1) {
            if (boundaries[i] <= boundaries[i - 1]) { return false; }
        }
        return true;
    }

    private function zoneFor(bpm) as Lang.Number {
        if (validBoundaries()) {
            var boundaries = mProfile[:hrZones];
            if (bpm < boundaries[0]) { return 0; }
            for (var i = 1; i <= 5; i += 1) {
                if (bpm <= boundaries[i]) { return i; }
            }
            return 5;
        }
        if (!validHrMax()) { return 0; }
        var percent = bpm * 100 / mProfile[:hrMax];
        if (percent >= 90) { return 5; }
        if (percent >= 80) { return 4; }
        if (percent >= 70) { return 3; }
        if (percent >= 60) { return 2; }
        if (percent >= 50) { return 1; }
        return 0;
    }

    private function sortNumbers(values) as Void {
        for (var i = 0; i < values.size(); i += 1) {
            for (var j = i + 1; j < values.size(); j += 1) {
                if (values[j] < values[i]) {
                    var swap = values[i];
                    values[i] = values[j];
                    values[j] = swap;
                }
            }
        }
    }

    private function sortRankedShifts(values) as Void {
        for (var i = 0; i < values.size(); i += 1) {
            for (var j = i + 1; j < values.size(); j += 1) {
                if (ranksBefore(values[j], values[i])) {
                    var swap = values[i];
                    values[i] = values[j];
                    values[j] = swap;
                }
            }
        }
    }

    private function ranksBefore(left, right) as Lang.Boolean {
        if (left[:averageHeartRate] != right[:averageHeartRate]) {
            return left[:averageHeartRate] > right[:averageHeartRate];
        }
        if (left[:durationMs] != right[:durationMs]) {
            return left[:durationMs] > right[:durationMs];
        }
        return left[:startedAtMs] < right[:startedAtMs];
    }
}
