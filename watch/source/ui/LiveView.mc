using Toybox.Activity;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Timer;
using Toybox.WatchUi;

class SystemClock {
    public function now() as Lang.Number {
        return System.getTimer();
    }
}

class LiveView extends WatchUi.View {
    private var mProfile = null;
    private var mHr = null;
    private var mHrTotal = 0.0;
    private var mHrCount = 0;
    private var mRrMs = null;
    private var mHrQuality = :missing;
    private var mZoneSeconds = [0, 0, 0, 0, 0, 0];
    private var mLastSampleAt = null;
    private var mLastSampleZone = null;
    private var mHighLoadStartedAt = null;
    private var mRecoveryMs = null;
    private var mLastHrAt = 0;
    private var mPage = 0;
    private var mEventSelection = 0;
    private var mEvents = [0, 0, 0];
    private var mRefreshTimer = null;
    private var mRound = new RoundLayout();

    public function setPlayerProfile(profile) as Void { mProfile = profile; }

    public function getDashboard() as Lang.Dictionary {
        var hr = mHr;
        if (mStarted && mClock.now() - mLastHrAt > 5000) { hr = null; }
        var maximum = mProfile == null ? PlayerProfile.defaultProfile().resolveHrMax() : mProfile.resolveHrMax();
        var percent = hr == null ? null : hr * 100 / maximum;
        var zone = null;
        if (percent != null) {
            zone = percent < 50 ? 0 : (percent < 60 ? 1 : (percent < 70 ? 2 : (percent < 80 ? 3 : (percent < 90 ? 4 : 5))));
        }
        return {:hr=>hr, :avgHr=>mHrCount == 0 ? null : (mHrTotal / mHrCount).toNumber(),
            :hrSampleCount=>mHrCount, :rrMs=>mRrMs, :hrQuality=>mHrQuality,
            :zoneSeconds=>mZoneSeconds, :recoveryMs=>mRecoveryMs,
            :zone=>zone, :hrPercent=>percent, :elapsedMs=>mStarted ? elapsedMs() : mStoppedDurationMs,
            :iceTimeMs=>mStarted ? currentIceTimeMs() : mStoppedIceTimeMs, :shifts=>mShiftCount,
            :onIce=>mOnIce, :recording=>mStarted, :page=>mPage,
            :hits=>mEvents[0], :passes=>mEvents[1], :shots=>mEvents[2]};
    }

    public function togglePage() as Void {
        mPage = 1 - mPage;
        mEventSelection = 0;
        WatchUi.requestUpdate();
    }

    public function moveLiveSelection(delta) as Void {
        if (mPage == 0) { togglePage(); }
        else { mEventSelection = (mEventSelection + delta + 5) % 5; WatchUi.requestUpdate(); }
    }

    public function activateSelection() as Void {
        if (mPage == 0 || mEventSelection == 3) { markShiftNow(); }
        else if (mEventSelection == 4) { togglePage(); }
        else { incrementEvent(mEventSelection); }
    }

    private function incrementEvent(index) as Void {
        if (mStarted && mEvents[index] < 65534) { mEvents[index] += 1; WatchUi.requestUpdate(); }
    }

    public function handleTap(point) as Lang.Boolean {
        if (!mStarted) { return false; }
        if (mRound.contains(point, 25, 19, 75, 28)) { togglePage(); }
        else if (mRound.contains(point, 20, 70, 80, 80)) { markShiftNow(); }
        else if (mRound.contains(point, 33, 83, 67, 92)) { requestStopConfirmation(); }
        else if (mPage == 1 && mRound.contains(point, 15, 29, 85, 39)) { incrementEvent(0); }
        else if (mPage == 1 && mRound.contains(point, 15, 41, 85, 51)) { incrementEvent(1); }
        else if (mPage == 1 && mRound.contains(point, 15, 53, 85, 63)) { incrementEvent(2); }
        else { return false; }
        return true;
    }

    function onShow() as Void {
        if (mRefreshTimer == null && mStarted) {
            mRefreshTimer = new Timer.Timer();
            mRefreshTimer.start(method(:refreshDisplay), 1000, true);
        }
    }

    function onHide() as Void {
        if (mRefreshTimer != null) { mRefreshTimer.stop(); mRefreshTimer = null; }
    }

    function refreshDisplay() as Void { WatchUi.requestUpdate(); }
    private var mController = null;
    private var mMode = null;
    private var mClock = null;
    private var mStartedAt = 0;
    private var mShiftStartedAt = 0;
    private var mShiftCount = 0;
    private var mIceTimeMs = 0;
    private var mOnIce = false;
    private var mStarted = false;
    private var mStartFailureMessage = "";
    private var mStoppedDurationMs = 0;
    private var mStoppedIceTimeMs = 0;
    private var mSensorAdapter = null;
    private var mCapabilityProfile = null;
    private var mRecordingAvailable = false;

    public function initialize(controller, mode, clock, sensorAdapter, capabilityProfile) {
        View.initialize();
        mController = controller;
        mMode = mode;
        mClock = clock == null ? new SystemClock() : clock;
        mSensorAdapter = sensorAdapter == null ? new SensorAdapter() : sensorAdapter;
        mCapabilityProfile = capabilityProfile == null ? CapabilityProfile.detect() : capabilityProfile;
    }

    public function startConfirmed() as Lang.Boolean {
        if (mStarted) {
            return false;
        }
        // Sensor setup precedes ActivityRecording. A missing/unavailable HR
        // source is optional and must not turn a playable recording into a
        // failed start.
        mSensorAdapter.start(method(:onSensorData), mCapabilityProfile);
        if (!mController.start(mMode)) {
            mStartFailureMessage = UiText.get(Rez.Strings.StartFailed);
            if (mController has :getStartFailureCode) {
                mStartFailureMessage += " [" + mController.getStartFailureCode() + "]";
            }
            // Keep the live UI usable even when Garmin rejects the FIT
            // session. Sensor metrics can still be collected and the visible
            // diagnostic identifies the recording-layer failure.
            mRecordingAvailable = false;
        } else {
            mRecordingAvailable = true;
        }
        if (mRecordingAvailable) { mStartFailureMessage = ""; }
        mStartedAt = mClock.now();
        mStarted = true;
        WatchUi.requestUpdate();
        return true;
    }

    public function markShiftNow() as Lang.Boolean {
        if (!mStarted) {
            return false;
        }
        var timestamp = elapsedMs();
        var nextState = mOnIce ? :bench : :shift;
        if (!mController.markShift(nextState, timestamp)) {
            return false;
        }
        if (mOnIce) {
            mIceTimeMs += timestamp - mShiftStartedAt;
        } else {
            mShiftCount += 1;
            mShiftStartedAt = timestamp;
        }
        mOnIce = !mOnIce;
        WatchUi.requestUpdate();
        return true;
    }

    public function getShiftCount() as Lang.Number { return mShiftCount; }
    public function getIceTimeMs() as Lang.Number { return currentIceTimeMs(); }
    public function getStartFailureMessage() as Lang.String { return mStartFailureMessage; }

    public function stopConfirmed() {
        if (!mStarted) {
            return null;
        }
        mStoppedDurationMs = elapsedMs();
        mStoppedIceTimeMs = currentIceTimeMs();
        var benchTime = mStoppedDurationMs - mStoppedIceTimeMs;
        if (mRecordingAvailable && (!mController.setSummaryMetrics({:iceTimeMs=>mStoppedIceTimeMs, :benchTimeMs=>benchTime,
            :hits=>mEvents[0], :passes=>mEvents[1], :shots=>mEvents[2],
            :hrSampleCount=>mHrCount, :recoveryMs=>mRecoveryMs == null ? 0 : mRecoveryMs,
            :hrZone0Seconds=>mZoneSeconds[0], :hrZone1Seconds=>mZoneSeconds[1],
            :hrZone2Seconds=>mZoneSeconds[2], :hrZone3Seconds=>mZoneSeconds[3],
            :hrZone4Seconds=>mZoneSeconds[4], :hrZone5Seconds=>mZoneSeconds[5]}) ||
            !mController.stop())) {
            return null;
        }
        mSensorAdapter.stop();
        mStarted = false;
        onHide();
        if (!mRecordingAvailable) {
            return new SummaryView(mStoppedDurationMs, mShiftCount, mStoppedIceTimeMs, getTrainingEffect());
        }
        var summary = retrySave();
        return summary != null ? summary : new SaveRecoveryView(self);
    }

    public function retrySave() {
        if (!mController.save()) {
            return null;
        }
        return new SummaryView(mStoppedDurationMs, mShiftCount, mStoppedIceTimeMs, getTrainingEffect());
    }

    public function discardStopped() as Lang.Boolean {
        return mController.discard();
    }

    public function requestStopConfirmation() as Void {
        WatchUi.pushView(
            new WatchUi.Confirmation(UiText.get(Rez.Strings.ConfirmStop)),
            new StopConfirmationDelegate(self),
            WatchUi.SLIDE_IMMEDIATE
        );
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var data = getDashboard();
        mRound.background(dc);
        mRound.text(dc, (mStarted ? "REC  " : "STOP  ") + formatTime(data[:elapsedMs]), 50, 12, 58, false);
        mRound.button(dc, UiText.get(mPage == 0 ? Rez.Strings.EventPage : Rez.Strings.PerformancePage),
            25, 19, 75, 28, mPage == 1 && mEventSelection == 4);
        if (mPage == 0) {
            mRound.text(dc, "HR " + numberOrMissing(data[:hr]), 50, 35, 75, true);
            mRound.text(dc, "Z" + numberOrMissing(data[:zone]) + "  " + numberOrMissing(data[:hrPercent]) + "%  " +
                UiText.get(Rez.Strings.AvgHr) + " " + numberOrMissing(data[:avgHr]), 50, 46, 82, false);
            mRound.text(dc, UiText.get(Rez.Strings.SummaryShifts) + " " + mShiftCount, 50, 56, 75, false);
            mRound.text(dc, UiText.get(Rez.Strings.SummaryIceTime) + " " + formatTime(data[:iceTimeMs]), 50, 64, 70, false);
        } else {
            var labels = [Rez.Strings.Hits, Rez.Strings.Passes, Rez.Strings.Shots];
            for (var i = 0; i < 3; i += 1) {
                mRound.button(dc, UiText.get(labels[i]) + "  " + mEvents[i] + "  +", 15, 29+i*12, 85, 39+i*12, mEventSelection == i);
            }
            mRound.text(dc, UiText.get(Rez.Strings.ManualEvents), 50, 66, 65, false);
        }
        mRound.button(dc, UiText.get(mOnIce ? Rez.Strings.ToBench : Rez.Strings.ToIce), 20, 70, 80, 80,
            mPage == 0 || mEventSelection == 3);
        mRound.button(dc, UiText.get(Rez.Strings.StopAction), 33, 83, 67, 92, false);
    }

    private function numberOrMissing(value) as Lang.String { return value == null ? "--" : value.toString(); }
    private function formatTime(ms) as Lang.String {
        var seconds = ms / 1000;
        return (seconds / 60).format("%02d") + ":" + (seconds % 60).format("%02d");
    }

    private function elapsedMs() as Lang.Number {
        return mClock.now() - mStartedAt;
    }

    private function currentIceTimeMs() as Lang.Number {
        return mOnIce ? mIceTimeMs + (elapsedMs() - mShiftStartedAt) : mIceTimeMs;
    }

    private function getTrainingEffect() {
        if (!CapabilityProfile.detect()[:trainingEffect]) {
            return null;
        }
        try {
            var info = Activity.getActivityInfo();
            return info == null ? null : info.trainingEffect;
        } catch (ex) {
            return null;
        }
    }

    public function onSensorData(data) as Void {
        // enableSensorEvents supplies Sensor.Info. Raw SensorData batches do
        // not contain heartRate and must not invalidate the current HR.
        if (!mStarted || data == null) { return; }
        var isDictionary = data instanceof Lang.Dictionary;
        if (isDictionary && data.hasKey(:rrMs)) { mRrMs = data[:rrMs]; }
        else if (!isDictionary && (data has :rrMs)) { mRrMs = data.rrMs; }
        if (isDictionary && data.hasKey(:quality)) { mHrQuality = data[:quality]; }
        else if (!isDictionary && (data has :quality)) { mHrQuality = data.quality; }
        var hasHr = isDictionary ? data.hasKey(:heartRate) : (data has :heartRate);
        if (!hasHr) { WatchUi.requestUpdate(); return; }
        var hr = isDictionary ? data[:heartRate] : data.heartRate;
        try {
            if (hr == null || hr <= 0 || hr > 255) { mHr = null; }
            else {
                mHr = hr.toNumber();
                var sampleAt = data has :timestampMs ? data[:timestampMs] : mClock.now();
                if (mLastSampleAt != null && mLastSampleZone != null && sampleAt >= mLastSampleAt) {
                    mZoneSeconds[mLastSampleZone] += (sampleAt - mLastSampleAt) / 1000;
                }
                var maximum = mProfile == null ? PlayerProfile.defaultProfile().resolveHrMax() : mProfile.resolveHrMax();
                var percent = mHr * 100 / maximum;
                var zone = percent < 50 ? 0 : (percent < 60 ? 1 : (percent < 70 ? 2 : (percent < 80 ? 3 : (percent < 90 ? 4 : 5))));
                if (percent >= 80 && mHighLoadStartedAt == null) { mHighLoadStartedAt = sampleAt; }
                if (percent < 60 && mHighLoadStartedAt != null && mRecoveryMs == null) {
                    mRecoveryMs = sampleAt - mHighLoadStartedAt;
                }
                mLastSampleAt = sampleAt;
                mLastSampleZone = zone;
                mLastHrAt = mClock.now(); mHrTotal += mHr; mHrCount += 1;
            }
        } catch (ex) { mHr = null; }
        WatchUi.requestUpdate();
    }
}

class StopConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    private var mLive = null;

    public function initialize(live) {
        ConfirmationDelegate.initialize();
        mLive = live;
    }

    public function onResponse(response) as Lang.Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            var summary = mLive.stopConfirmed();
            if (summary != null) {
                var delegate = summary instanceof SaveRecoveryView ? new SaveRecoveryDelegate(summary) : null;
                WatchUi.pushView(summary, delegate, WatchUi.SLIDE_LEFT);
            }
        }
        return true;
    }
}

class SaveRecoveryView extends WatchUi.View {
    private var mLive = null;

    public function initialize(live) {
        View.initialize();
        mLive = live;
    }

    public function getMessage() as Lang.String {
        return UiText.get(Rez.Strings.SaveFailed);
    }

    public function retrySave() {
        return mLive.retrySave();
    }

    public function discardSession() as Lang.Boolean {
        return mLive.discardStopped();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var x = dc.getWidth() / 2;
        dc.drawText(x, 48, Graphics.FONT_SMALL, getMessage(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x, 82, Graphics.FONT_SMALL, UiText.get(Rez.Strings.RetrySave),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x, dc.getHeight() - 24, Graphics.FONT_SMALL, UiText.get(Rez.Strings.DiscardSession),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class SaveRecoveryDelegate extends WatchUi.BehaviorDelegate {
    private var mRecovery = null;

    public function initialize(recovery) {
        BehaviorDelegate.initialize();
        mRecovery = recovery;
    }

    public function onSelect() as Lang.Boolean {
        var summary = mRecovery.retrySave();
        if (summary != null) {
            WatchUi.pushView(summary, null, WatchUi.SLIDE_LEFT);
        } else {
            WatchUi.requestUpdate();
        }
        return true;
    }

    public function onBack() as Lang.Boolean {
        WatchUi.pushView(
            new WatchUi.Confirmation(UiText.get(Rez.Strings.ConfirmDiscard)),
            new DiscardConfirmationDelegate(mRecovery),
            WatchUi.SLIDE_IMMEDIATE
        );
        return true;
    }
}

class DiscardConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    private var mRecovery = null;

    public function initialize(recovery) {
        ConfirmationDelegate.initialize();
        mRecovery = recovery;
    }

    public function onResponse(response) as Lang.Boolean {
        if (response == WatchUi.CONFIRM_YES && mRecovery.discardSession()) {
            WatchUi.pushView(new StatusView(UiText.get(Rez.Strings.SessionDiscarded)), null, WatchUi.SLIDE_LEFT);
        }
        return true;
    }
}

class StatusView extends WatchUi.View {
    private var mMessage = "";

    public function initialize(message as Lang.String) {
        View.initialize();
        mMessage = message;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var layout = new RoundLayout();
        layout.background(dc);
        layout.text(dc, mMessage, 50, 45, 85, false);
        layout.text(dc, UiText.get(Rez.Strings.BackToRetry), 50, 62, 72, false);
    }
}
