using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Test as Test;
using Toybox.WatchUi;

class DialDcFake extends Graphics.Dc {
    var texts = [];
    var arcCount = 0;
    var circleCount = 0;
    var lineCount = 0;
    var arcDirections = [];
    var arcSpans = [];
    var arcWidths = [];
    var arcColors = [];
    var penWidth = 1;
    var foregroundColor = Graphics.COLOR_BLACK;
    var textColors = [];
    var textYs = [];
    var textFonts = [];
    var textJustifications = [];

    function getWidth() as Lang.Number { return 416; }
    function getHeight() as Lang.Number { return 416; }
    function getFontHeight(font as Graphics.FontType) as Lang.Number {
        if (font == Graphics.FONT_XTINY) { return 24; }
        if (font == Graphics.FONT_SMALL) { return 34; }
        if (font == Graphics.FONT_MEDIUM) { return 50; }
        if (font == Graphics.FONT_LARGE) { return 70; }
        return 24;
    }
    function setColor(foreground, background) as Void { foregroundColor = foreground; }
    function clear() as Void { }
    function drawText(x, y, font, value, justification) as Void {
        texts.add(value);
        textColors.add(foregroundColor);
        textYs.add(y);
        textFonts.add(font);
        textJustifications.add(justification);
    }
    function drawArc(x, y, radius, direction, startAngle, endAngle) as Void {
        arcCount += 1;
        arcDirections.add(direction);
        arcSpans.add(endAngle - startAngle);
        arcWidths.add(penWidth);
        arcColors.add(foregroundColor);
    }
    function fillCircle(x, y, radius) as Void { circleCount += 1; }
    function drawLine(x1, y1, x2, y2) as Void { lineCount += 1; }
    function setPenWidth(width) as Void { penWidth = width; }
}

class DirectionSwipeEventFake extends Toybox.WatchUi.SwipeEvent {
    private var mFakeSwipeDirection;
    function initialize(direction) { mFakeSwipeDirection = direction; }
    function getDirection() { return mFakeSwipeDirection; }
}

function dialContainsText(dc as DialDcFake, value as Lang.String) as Lang.Boolean {
    for (var i = 0; i < dc.texts.size(); i += 1) {
        if (dc.texts[i].equals(value)) { return true; }
    }
    return false;
}

(:test)
function primaryDialShowsShiftAverageInsteadOfSessionAverage(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    if (!coordinator.start() || !coordinator.toggleShift()) { return false; }
    coordinator.onHeartRate({:heartRate=>145});
    var dc = new DialDcFake();
    new LiveView(coordinator).onUpdate(dc);
    return dialContainsText(dc, "SHIFT AVG HR") && dialContainsText(dc, "145") &&
        !dialContainsText(dc, "AVG HR");
}

(:test)
function horizontalSwipeShowsSessionAverageWithoutChangingShift(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    if (!coordinator.start()) { return false; }
    coordinator.onHeartRate({:heartRate=>80});
    if (!coordinator.toggleShift()) { return false; }
    coordinator.onHeartRate({:heartRate=>160});
    var view = new LiveView(coordinator);
    var input = new LiveInputDelegate(view);
    if (!input.onSwipe(new DirectionSwipeEventFake(Toybox.WatchUi.SWIPE_LEFT))) {
        return false;
    }
    var dc = new DialDcFake();
    view.onUpdate(dc);
    return dialContainsText(dc, "AVG HR") && dialContainsText(dc, "120") &&
        dialContainsText(dc, "SHIFT AVG HR") && dialContainsText(dc, "160") &&
        coordinator.getDashboard()[:shiftCount] == 1 &&
        coordinator.getState() == :recording;
}

(:test)
function dialShowsExactTimeOnIceLabel(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    if (!coordinator.start()) { return false; }
    var dc = new DialDcFake();
    new LiveView(coordinator).onUpdate(dc);
    for (var i = 0; i < dc.texts.size(); i += 1) {
        if (dc.texts[i].equals("TIME ON ICE")) { return true; }
    }
    return false;
}

(:test)
function dialDrawsCircularLightFace(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    if (!coordinator.start()) { return false; }
    var dc = new DialDcFake();
    new LiveView(coordinator).onUpdate(dc);
    return dc.circleCount == 1;
}

(:test)
function dialShowsSixZoneRingSegments(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    if (!coordinator.start()) { return false; }
    var dc = new DialDcFake();
    new LiveView(coordinator).onUpdate(dc);
    return dc.arcCount == 6;
}

(:test)
function dialSeparatesPairedMetrics(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    if (!coordinator.start()) { return false; }
    var dc = new DialDcFake();
    new LiveView(coordinator).onUpdate(dc);
    return dc.lineCount >= 3;
}

(:test)
function dialDistinguishesBeforeFirstShiftFromBench(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    if (!coordinator.start()) { return false; }
    var dc = new DialDcFake();
    new LiveView(coordinator).onUpdate(dc);
    var beforeFirstShift = false;
    for (var i = 0; i < dc.texts.size(); i += 1) {
        if (dc.texts[i].equals("NO SHIFT") && dc.textColors[i] == 0x586A86) {
            beforeFirstShift = true;
        }
    }
    if (!beforeFirstShift || !coordinator.toggleShift() || !coordinator.toggleShift()) {
        return false;
    }
    dc = new DialDcFake();
    new LiveView(coordinator).onUpdate(dc);
    for (var j = 0; j < dc.texts.size(); j += 1) {
        if (dc.texts[j].equals("BENCH")) { return true; }
    }
    return false;
}

(:test)
function dialRingUsesSixShortNonOverlappingArcs(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    if (!coordinator.start()) { return false; }
    var dc = new DialDcFake();
    new LiveView(coordinator).onUpdate(dc);
    if (dc.arcCount != 6) { return false; }
    for (var i = 0; i < dc.arcCount; i += 1) {
        if (dc.arcDirections[i] != Graphics.ARC_COUNTER_CLOCKWISE ||
            dc.arcSpans[i] != 52) { return false; }
    }
    return true;
}

(:test)
function dialHighlightsFirstAndLastGarminZones(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    coordinator.setDataSources(new ProfileSourceFake(), new HeartRateSourceFake());
    if (!coordinator.start()) { return false; }
    coordinator.onHeartRate({:heartRate=>80, :quality=>:active});
    var dc = new DialDcFake();
    new LiveView(coordinator).onUpdate(dc);
    if (dc.arcWidths[0] != 16 || dc.arcWidths[5] != 6) { return false; }
    coordinator.onHeartRate({:heartRate=>190, :quality=>:active});
    dc = new DialDcFake();
    new LiveView(coordinator).onUpdate(dc);
    return dc.arcWidths[0] == 6 && dc.arcWidths[5] == 16;
}

(:test)
function dialEmphasizesCurrentZoneAndDimsOtherSegments(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    coordinator.setDataSources(new ProfileSourceFake(), new HeartRateSourceFake());
    if (!coordinator.start()) { return false; }
    coordinator.onHeartRate({:heartRate=>130, :quality=>:active});
    var dc = new DialDcFake();
    new LiveView(coordinator).onUpdate(dc);
    return dc.arcCount == 6 && dc.arcWidths[2] == 16 &&
        dc.arcColors[2] == 0xF6C246 && dc.arcWidths[0] == 6 &&
        dc.arcColors[0] == 0x0B386C;
}

(:test)
function dialColorsZoneLabelAndLivePulseToMatchRingHue(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    coordinator.setDataSources(new ProfileSourceFake(), new HeartRateSourceFake());
    if (!coordinator.start()) { return false; }
    coordinator.onHeartRate({:heartRate=>130, :quality=>:active});
    var dc = new DialDcFake();
    new LiveView(coordinator).onUpdate(dc);
    var zoneColor = null;
    var pulseColor = null;
    for (var i = 0; i < dc.texts.size(); i += 1) {
        if (dc.texts[i].equals("ZONE 2")) { zoneColor = dc.textColors[i]; }
        if (dc.texts[i].equals("130") && pulseColor == null) {
            pulseColor = dc.textColors[i];
        }
    }
    return zoneColor == 0x886200 && pulseColor == zoneColor;
}

(:test)
function dialKeepsZoneClearOfMetricHeadings(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    coordinator.setDataSources(new ProfileSourceFake(), new HeartRateSourceFake());
    if (!coordinator.start()) { return false; }
    coordinator.onHeartRate({:heartRate=>80, :quality=>:active});
    var dc = new DialDcFake();
    new LiveView(coordinator).onUpdate(dc);
    var zoneBottom = null;
    var headingTop = null;
    for (var i = 0; i < dc.texts.size(); i += 1) {
        var height = dc.getFontHeight(dc.textFonts[i]);
        var top = dc.textYs[i];
        if ((dc.textJustifications[i] & Graphics.TEXT_JUSTIFY_VCENTER) != 0) {
            top -= height / 2;
        }
        if (dc.texts[i].equals("ZONE 0")) { zoneBottom = top + height; }
        if (dc.texts[i].equals("LIVE HR")) { headingTop = top; }
    }
    return zoneBottom != null && headingTop != null && zoneBottom + 4 <= headingTop;
}

(:test)
function dialKeepsElapsedClearOfSaveHint(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    if (!coordinator.start()) { return false; }
    var dc = new DialDcFake();
    new LiveView(coordinator).onUpdate(dc);
    var elapsedBottom = null;
    var hintTop = null;
    for (var i = 0; i < dc.texts.size(); i += 1) {
        var height = dc.getFontHeight(dc.textFonts[i]);
        var top = dc.textYs[i];
        if ((dc.textJustifications[i] & Graphics.TEXT_JUSTIFY_VCENTER) != 0) {
            top -= height / 2;
        }
        if (dc.texts[i].equals("00:00") && dc.textYs[i] >= dc.getHeight() * 70 / 100) {
            elapsedBottom = top + height;
        }
        if (dc.texts[i].equals("UPPER: SAVE")) { hintTop = top; }
    }
    return elapsedBottom != null && hintTop != null && elapsedBottom + 4 <= hintTop;
}

(:test)
function dialKeepsSensorWarningClearOfMetricHeadings(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    var heartRateSource = new HeartRateSourceFake();
    heartRateSource.startResult = false;
    coordinator.setDataSources(new ProfileSourceFake(), heartRateSource);
    if (!coordinator.start()) { return false; }
    var dc = new DialDcFake();
    new LiveView(coordinator).onUpdate(dc);
    var warningBottom = null;
    var headingTop = null;
    for (var i = 0; i < dc.texts.size(); i += 1) {
        var height = dc.getFontHeight(dc.textFonts[i]);
        var top = dc.textYs[i];
        if ((dc.textJustifications[i] & Graphics.TEXT_JUSTIFY_VCENTER) != 0) {
            top -= height / 2;
        }
        if (dc.texts[i].equals("HR sensor unavailable")) {
            warningBottom = top + height;
        }
        if (dc.texts[i].equals("LIVE HR")) { headingTop = top; }
    }
    return warningBottom != null && headingTop != null && warningBottom + 4 <= headingTop;
}

(:test)
function movementPageCyclesAfterOriginalTwoPages(logger as Test.Logger) as Lang.Boolean {
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), new ClockFake());
    if (!coordinator.start()) { return false; }
    var view = new LiveView(coordinator);
    var dc = new DialDcFake();
    view.onUpdate(dc);
    if (!dialContainsText(dc, "TIME ON ICE")) { return false; }
    view.requestPage(WatchUi.SWIPE_LEFT);
    dc = new DialDcFake();
    view.onUpdate(dc);
    if (!dialContainsText(dc, "AVG HR")) { return false; }
    view.requestPage(WatchUi.SWIPE_LEFT);
    dc = new DialDcFake();
    view.onUpdate(dc);
    if (!dialContainsText(dc, "PUSHES") ||
        !dialContainsText(dc, "CADENCE") ||
        !dialContainsText(dc, "SHIFT DISTANCE ≈") ||
        !dialContainsText(dc, "TOTAL ≈")) { return false; }
    view.requestPage(WatchUi.SWIPE_RIGHT);
    dc = new DialDcFake();
    view.onUpdate(dc);
    return dialContainsText(dc, "TIME ON ICE") &&
        !dialContainsText(dc, "PUSHES");
}

(:test)
function movementPageSeparatesNoShiftFromValidZero(logger as Test.Logger) as Lang.Boolean {
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), clock);
    if (!coordinator.start()) { return false; }
    var view = new LiveView(coordinator);
    view.requestPage(WatchUi.SWIPE_LEFT);
    view.requestPage(WatchUi.SWIPE_LEFT);
    var dc = new DialDcFake();
    view.onUpdate(dc);
    if (!dialContainsText(dc, "--")) { return false; }
    if (!coordinator.toggleShift()) { return false; }
    clock.now = 6000;
    // The real estimator receives a valid zero-push interval after the shift begins.
    var estimator = new DistanceEstimator();
    estimator.beginShift(0);
    estimator.observe(distanceResult(5000, [], 0, true, false));
    coordinator.setDistanceEstimator(estimator);
    dc = new DialDcFake();
    view.onUpdate(dc);
    return dialContainsText(dc, "0") && dialContainsText(dc, "0.0 m") &&
        !dialContainsText(dc, "PARTIAL DATA");
}

(:test)
function movementPageRetainsLastShiftAndShowsEstimatedDistance(logger as Test.Logger) as Lang.Boolean {
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), clock);
    if (!coordinator.start() || !coordinator.toggleShift()) { return false; }
    var estimator = new DistanceEstimator();
    estimator.beginShift(0);
    var times = [100, 700, 1300, 1900, 2500, 3100];
    for (var i = 0; i < times.size(); i += 1) {
        estimator.observe(distanceResult(times[i],
            [pushAt(times[i], i == 0)], times[i] - 100, true, false));
    }
    coordinator.setDistanceEstimator(estimator);
    clock.now = 4200;
    if (!coordinator.toggleShift()) { return false; }
    var view = new LiveView(coordinator);
    view.requestPage(WatchUi.SWIPE_LEFT);
    view.requestPage(WatchUi.SWIPE_LEFT);
    var dc = new DialDcFake();
    view.onUpdate(dc);
    return dialContainsText(dc, "BENCH") && dialContainsText(dc, "6") &&
        dialContainsText(dc, "9.5 m") && dialContainsText(dc, "PARTIAL DATA") &&
        dialContainsText(dc, "UPPER: SAVE");
}

(:test)
function movementPageKeepsPhysicalShiftAndSaveButtons(logger as Test.Logger) as Lang.Boolean {
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), clock);
    if (!coordinator.start()) { return false; }
    var view = new LiveView(coordinator);
    view.requestPage(WatchUi.SWIPE_LEFT);
    view.requestPage(WatchUi.SWIPE_LEFT);
    var input = new LiveInputDelegate(view);
    if (!input.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ESC)) ||
        !coordinator.getDashboard()[:onIce]) { return false; }
    return input.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ENTER)) &&
        coordinator.getState() == :saved;
}

(:test)
function estimatedSensorTimebaseMarksLiveDistanceAsApproximate(logger as Test.Logger) as Lang.Boolean {
    var clock = new ClockFake();
    var coordinator = new RecordingCoordinator(
        new SessionRecorder(new RecordingFactoryFake()), clock);
    if (!coordinator.start() || !coordinator.toggleShift()) { return false; }
    var estimator = new DistanceEstimator();
    estimator.beginShift(0);
    var result = distanceResult(1000, [pushAt(300, true)],
        100, true, false);
    result[:timebase] = :estimated;
    estimator.observe(result);
    coordinator.setDistanceEstimator(estimator);
    var view = new LiveView(coordinator);
    view.requestPage(WatchUi.SWIPE_LEFT);
    view.requestPage(WatchUi.SWIPE_LEFT);
    var dc = new DialDcFake();
    view.onUpdate(dc);
    return dialContainsText(dc, "~1.3 m");
}
