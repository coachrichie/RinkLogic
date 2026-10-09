using Toybox.Lang;
using Toybox.Graphics;
using Toybox.Test as Test;

class ReadyStatusSourceFake {
    var phone = false;
    function snapshot() as Lang.Dictionary {
        return {:phoneConnected=>phone};
    }
}

(:test)
function readyStatusNeverInfersH10FromSensorName(logger as Test.Logger) as Lang.Boolean {
    var status = new GarminReadyStatusService().snapshot();
    return !status.hasKey(:h10Status);
}

class ReadyDcFake extends Graphics.Dc {
    var bitmapCount = 0;
    var texts = [];
    var textColors = [];
    var foregroundColor = Graphics.COLOR_BLACK;
    function getWidth() as Lang.Number { return 416; }
    function getHeight() as Lang.Number { return 416; }
    function setColor(foreground, background) as Void { foregroundColor = foreground; }
    function clear() as Void { }
    function drawBitmap(x, y, bitmap) as Void { bitmapCount += 1; }
    function drawText(x, y, font, value, justification) as Void {
        texts.add(value);
        textColors.add(foregroundColor);
    }
    function drawLine(x1, y1, x2, y2) as Void { }
    function fillCircle(x, y, radius) as Void { }
    function fillPolygon(points) as Void { }
    function fillRectangle(x, y, width, height) as Void { }
    function drawRoundedRectangle(x, y, width, height, radius) as Void { }
}

(:test)
function readyRendersHockeyAssetsAndStartAction(logger as Test.Logger) as Lang.Boolean {
    var ready = new ReadyView(new ReadyStartTargetFake(), new ReadyStatusSourceFake(),
        new HeartRateSourceFake(), new ClockFake());
    var dc = new ReadyDcFake();
    ready.onUpdate(dc);
    var hasReady = false;
    var hasStart = false;
    for (var i = 0; i < dc.texts.size(); i += 1) {
        if (dc.texts[i].equals("READY")) { hasReady = true; }
        if (dc.texts[i].equals("START")) { hasStart = true; }
    }
    return dc.bitmapCount == 2 && hasReady && hasStart;
}

(:test)
function readyColorsPhoneAndPulseIndependently(logger as Test.Logger) as Lang.Boolean {
    var status = new ReadyStatusSourceFake();
    status.phone = true;
    var ready = new ReadyView(new ReadyStartTargetFake(), status,
        new HeartRateSourceFake(), new ClockFake());
    var dc = new ReadyDcFake();
    ready.onUpdate(dc);
    var phoneColor = null;
    var pulseColor = null;
    for (var i = 0; i < dc.texts.size(); i += 1) {
        if (dc.texts[i].equals("PHONE")) { phoneColor = dc.textColors[i]; }
        if (dc.texts[i].equals("HR SIGNAL")) { pulseColor = dc.textColors[i]; }
    }
    return phoneColor == 0x20D49A && pulseColor == 0x8092A9;
}

(:test)
function readyLabelsPulseSourceAsUnknown(logger as Test.Logger) as Lang.Boolean {
    var ready = new ReadyView(new ReadyStartTargetFake(), new ReadyStatusSourceFake(),
        new HeartRateSourceFake(), new ClockFake());
    var dc = new ReadyDcFake();
    ready.onUpdate(dc);
    for (var i = 0; i < dc.texts.size(); i += 1) {
        if (dc.texts[i].equals("SOURCE UNKNOWN")) { return true; }
    }
    return false;
}

(:test)
function pulseSampleDoesNotClaimChestStrapConnection(logger as Test.Logger) as Lang.Boolean {
    var ready = new ReadyView(new ReadyStartTargetFake(), new ReadyStatusSourceFake(),
        new HeartRateSourceFake(), new ClockFake());
    ready.onHeartRate({:heartRate=>112, :quality=>:active});
    var dc = new ReadyDcFake();
    ready.onUpdate(dc);
    for (var i = 0; i < dc.texts.size(); i += 1) {
        if (dc.texts[i].equals("HR SIGNAL")) {
            return dc.textColors[i] == 0x3BA5FF;
        }
    }
    return false;
}

(:test)
function readyPhoneConnectionUpdatesIndependently(logger as Test.Logger) as Lang.Boolean {
    var status = new ReadyStatusSourceFake();
    var ready = new ReadyView(new ReadyStartTargetFake(), status,
        new HeartRateSourceFake(), new ClockFake());
    if (ready.getDisplayValues()[:phoneConnected]) { return false; }
    status.phone = true;
    return ready.getDisplayValues()[:phoneConnected];
}

(:test)
function readyPulseSignalExpiresAfterFiveSeconds(logger as Test.Logger) as Lang.Boolean {
    var clock = new ClockFake();
    var ready = new ReadyView(new ReadyStartTargetFake(), new ReadyStatusSourceFake(),
        new HeartRateSourceFake(), clock);
    ready.onHeartRate({:heartRate=>112, :quality=>:active});
    if (!ready.getDisplayValues()[:heartSignal]) { return false; }
    clock.now = 7001;
    return !ready.getDisplayValues()[:heartSignal];
}

(:test)
function readyReleasesHeartRateSensorBeforeRecording(logger as Test.Logger) as Lang.Boolean {
    var hr = new HeartRateSourceFake();
    var ready = new ReadyView(new ReadyStartTargetFake(), new ReadyStatusSourceFake(),
        hr, new ClockFake());
    ready.onShow();
    ready.onHide();
    return hr.startCalls == 1 && hr.stopCalls == 1;
}

(:test)
function readyStartReleasesSensorBeforeOpeningConfirmation(logger as Test.Logger) as Lang.Boolean {
    var hr = new HeartRateSourceFake();
    var target = new ReadyStartTargetFake();
    var ready = new ReadyView(target, new ReadyStatusSourceFake(), hr, new ClockFake());
    ready.onShow();
    ready.requestStart();
    return target.requests == 1 && hr.stopCalls == 1;
}

(:test)
function readyCalibrationActionReleasesSensor(logger as Test.Logger) as Lang.Boolean {
    var hr = new HeartRateSourceFake();
    var target = new ReadyStartTargetFake();
    var ready = new ReadyView(target, new ReadyStatusSourceFake(), hr, new ClockFake());
    ready.onShow();
    ready.requestCalibration();
    return target.calibrationRequests == 1 && hr.stopCalls == 1;
}
