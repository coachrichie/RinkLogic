using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Timer;
using Toybox.WatchUi;

class LiveView extends WatchUi.View {
    private var mCoordinator;
    private var mTimer = null;
    private var mPage = 0;

    function initialize(coordinator) {
        View.initialize();
        mCoordinator = coordinator;
    }

    function onShow() as Void {
        mTimer = new Timer.Timer();
        mTimer.start(method(:refresh), 1000, true);
    }

    function onHide() as Void {
        if (mTimer != null) { mTimer.stop(); mTimer = null; }
    }

    function refresh() as Void { WatchUi.requestUpdate(); }

    function elapsedText() as Lang.String {
        return formatDuration(mCoordinator.getElapsedMs());
    }

    private function formatDuration(milliseconds) as Lang.String {
        if (milliseconds == null) { return "--"; }
        var totalSeconds = milliseconds / 1000;
        var minutes = totalSeconds / 60;
        var seconds = totalSeconds % 60;
        return minutes.format("%02d") + ":" + seconds.format("%02d");
    }

    function getDisplayValues() as Lang.Dictionary {
        var data = mCoordinator.getDashboard();
        var shiftPushes = data[:shiftPushes];
        var shiftDistance = data[:shiftDistanceCm];
        if (!data[:hasValidMotion]) {
            shiftPushes = null;
            shiftDistance = null;
        }
        var totalDistance = data[:totalDistanceCm];
        if (data[:shiftCount] > 0 && !data[:hasValidMotion] &&
            data[:totalPushes] == 0) {
            totalDistance = null;
        }
        return {
            :heartRate=>formatMetric(data[:heartRate]),
            :averageHeartRate=>formatMetric(data[:averageHeartRate]),
            :shiftAverageHeartRate=>formatMetric(data[:shiftAverageHeartRate]),
            :hrZone=>formatMetric(data[:hrZone]),
            :zoneText=>"ZONE " + formatMetric(data[:hrZone]),
            :shiftCount=>formatMetric(data[:shiftCount]),
            :lastShift=>formatDuration(data[:lastShiftMs]),
            :averageShift=>formatDuration(data[:averageShiftMs]),
            :timeOnIce=>formatDuration(data[:timeOnIceMs]),
            :pushes=>formatMetric(shiftPushes),
            :cadence=>formatMetric(data[:cadencePerMin]),
            :shiftDistance=>formatDistance(shiftDistance, data[:timebase]),
            :totalDistance=>formatDistance(totalDistance, data[:totalTimebase]),
            :partial=>data[:partial] == true,
            :elapsed=>formatDuration(data[:elapsedMs])
        };
    }

    private function formatMetric(value) as Lang.String {
        return value == null ? "--" : value.toString();
    }

    private function formatDistance(centimetres, timebase) as Lang.String {
        if (centimetres == null) { return "--"; }
        var tenths = (centimetres + 5) / 10;
        var prefix = timebase == :estimated ? "~" : "";
        return prefix + (tenths / 10).toString() + "." +
            (tenths % 10).toString() + " m";
    }

    function requestStop() as Lang.Boolean {
        var saved = mCoordinator.stopAndSave();
        if (saved) {
            var summaryView = new SessionSummaryView(mCoordinator.getSessionSummary());
            WatchUi.switchToView(summaryView, new SessionSummaryInputDelegate(summaryView),
                WatchUi.SLIDE_IMMEDIATE);
        } else {
            var errorView = new ErrorView(mCoordinator.getErrorCode(), mCoordinator);
            WatchUi.switchToView(errorView, new ErrorInputDelegate(errorView), WatchUi.SLIDE_IMMEDIATE);
        }
        return true;
    }

    function requestShift() as Lang.Boolean {
        if (!mCoordinator.toggleShift()) { return false; }
        WatchUi.requestUpdate();
        return true;
    }

    function requestPage(direction) as Lang.Boolean {
        if (direction == WatchUi.SWIPE_LEFT || direction == WatchUi.SWIPE_RIGHT) {
            mPage = (mPage + 1) % 3;
            WatchUi.requestUpdate();
        }
        return true;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var display = getDisplayValues();
        var data = mCoordinator.getDashboard();
        var width = dc.getWidth();
        var height = dc.getHeight();
        var size = width < height ? width : height;
        var centerX = width / 2;
        var dark = 0x152847;
        var zoneColor = zoneTextColor(data[:hrZone]);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var radius = size * 43 / 100;
        dc.setColor(0xE8EEFA, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, height / 2, radius);
        drawZoneRing(dc, width, height, data[:hrZone]);
        dc.setColor(0xB8C5DB, Graphics.COLOR_TRANSPARENT);
        if (mPage == 0) {
            dc.drawLine(centerX, height * 27 / 100, centerX, height * 70 / 100);
            dc.drawLine(width * 18 / 100, height * 40 / 100,
                width * 82 / 100, height * 40 / 100);
            dc.drawLine(width * 13 / 100, height * 55 / 100,
                width * 87 / 100, height * 55 / 100);
            dc.drawLine(width * 16 / 100, height * 70 / 100,
                width * 84 / 100, height * 70 / 100);
        } else if (mPage == 1) {
            dc.drawLine(centerX, height * 27 / 100, centerX, height * 40 / 100);
            dc.drawLine(width * 18 / 100, height * 40 / 100,
                width * 82 / 100, height * 40 / 100);
            dc.drawLine(width * 16 / 100, height * 70 / 100,
                width * 84 / 100, height * 70 / 100);
        } else {
            dc.drawLine(centerX, height * 28 / 100, centerX, height * 44 / 100);
            dc.drawLine(width * 18 / 100, height * 44 / 100,
                width * 82 / 100, height * 44 / 100);
            dc.drawLine(width * 18 / 100, height * 58 / 100,
                width * 82 / 100, height * 58 / 100);
            dc.drawLine(width * 16 / 100, height * 70 / 100,
                width * 84 / 100, height * 70 / 100);
        }

        var shiftLabel = Rez.Strings.NoShiftShort;
        var shiftColor = 0x586A86;
        if (data[:onIce]) {
            shiftLabel = Rez.Strings.OnIceShort;
            shiftColor = 0x079669;
        } else if (data[:shiftCount] > 0) {
            shiftLabel = Rez.Strings.BenchShort;
            shiftColor = 0x7750BD;
        }
        dc.setColor(shiftColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 12 / 100, Graphics.FONT_SMALL,
            WatchUi.loadResource(shiftLabel),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        if (mPage == 2 && display[:partial]) {
            dc.setColor(0xB65B22, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height * 21 / 100, Graphics.FONT_XTINY,
                WatchUi.loadResource(Rez.Strings.PartialDataLabel),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else if (!data[:sensorAvailable]) {
            dc.setColor(0xB65B22, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height * 21 / 100, Graphics.FONT_XTINY,
                WatchUi.loadResource(Rez.Strings.HrSensorUnavailable),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.setColor(zoneColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height * 21 / 100, Graphics.FONT_XTINY,
                display[:zoneText], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        if (mPage == 0) {
            drawMetric(dc, 31, 29, Rez.Strings.LiveHrLabel, display[:heartRate], zoneColor);
            drawMetric(dc, 69, 29, Rez.Strings.ShiftAvgHrLabel,
                display[:shiftAverageHeartRate], dark);
            drawMetric(dc, 31, 44, Rez.Strings.ShiftCountLabel, display[:shiftCount], 0x078A70);
            drawMetric(dc, 69, 44, Rez.Strings.LastShiftLabel, display[:lastShift], dark);
            drawMetric(dc, 31, 59, Rez.Strings.AvgShiftLabel, display[:averageShift], dark);
            drawMetric(dc, 69, 59, Rez.Strings.TimeOnIceLabel, display[:timeOnIce], 0x126BC1);
        } else if (mPage == 1) {
            drawMetric(dc, 31, 29, Rez.Strings.LiveHrLabel, display[:heartRate], zoneColor);
            drawMetric(dc, 69, 29, Rez.Strings.AvgHrLabel,
                display[:averageHeartRate], dark);
            drawMetric(dc, 50, 50, Rez.Strings.ShiftAvgHrLabel,
                display[:shiftAverageHeartRate], dark);
        } else {
            drawMetric(dc, 31, 30, Rez.Strings.PushCountLabel,
                display[:pushes], 0x078A70);
            drawMetric(dc, 69, 30, Rez.Strings.CadenceLabel,
                display[:cadence], dark);
            drawDistanceMetric(dc, 45, Rez.Strings.ShiftDistanceLabel,
                display[:shiftDistance], 0x126BC1);
            drawDistanceMetric(dc, 59, Rez.Strings.TotalDistanceLabel,
                display[:totalDistance], dark);
        }

        var footerTop = height * 71 / 100;
        var elapsedHeight = dc.getFontHeight(Graphics.FONT_MEDIUM);
        var hintHeight = dc.getFontHeight(Graphics.FONT_XTINY);
        var footerGap = height / 100;
        dc.setColor(dark, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, footerTop + elapsedHeight / 2, Graphics.FONT_MEDIUM,
            display[:elapsed], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x687A97, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, footerTop + elapsedHeight + footerGap + hintHeight / 2,
            Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.UpperSaveHint),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function zoneTextColor(zone) as Lang.Number {
        var colors = [0x125CAF, 0x087953, 0x886200,
            0x995017, 0xB2344A, 0x71399F];
        if (zone == null || zone < 0 || zone >= colors.size()) { return 0x152847; }
        return colors[zone];
    }

    private function drawZoneRing(dc as Graphics.Dc, width as Lang.Number,
        height as Lang.Number, zone) as Void {
        var size = width < height ? width : height;
        var radius = size * 46 / 100;
        var colors = [0x1477E6, 0x12C986, 0xF6C246,
            0xF18A42, 0xE85668, 0xA44FEB];
        var dimColors = [0x0B386C, 0x0A6045, 0x725D24,
            0x713E22, 0x6B2835, 0x4D2872];
        for (var i = 0; i < colors.size(); i += 1) {
            var active = zone != null && zone == i;
            dc.setPenWidth(active ? 16 : 6);
            dc.setColor(active ? colors[i] : dimColors[i], Graphics.COLOR_TRANSPARENT);
            dc.drawArc(width / 2, height / 2, radius,
                Graphics.ARC_COUNTER_CLOCKWISE, i * 60 + 4, i * 60 + 56);
        }
        dc.setPenWidth(1);
    }

    private function drawMetric(dc as Graphics.Dc, xPercent as Lang.Number,
        yPercent as Lang.Number, label, value as Lang.String, valueColor) as Void {
        dc.setColor(0x586A86, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()*xPercent/100, dc.getHeight()*yPercent/100,
            Graphics.FONT_XTINY, WatchUi.loadResource(label),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(valueColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()*xPercent/100, dc.getHeight()*(yPercent+7)/100,
            Graphics.FONT_SMALL, value,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawDistanceMetric(dc as Graphics.Dc, yPercent as Lang.Number,
        label, value as Lang.String, valueColor) as Void {
        dc.setColor(0x586A86, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()*yPercent/100,
            Graphics.FONT_XTINY, WatchUi.loadResource(label),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(valueColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()*(yPercent+7)/100,
            Graphics.FONT_XTINY, value,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class LiveInputDelegate extends WatchUi.InputDelegate {
    private var mView;
    function initialize(view) { InputDelegate.initialize(); mView = view; }
    function onKey(keyEvent as WatchUi.KeyEvent) as Lang.Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_ESC) { return mView.requestShift(); }
        if (key == WatchUi.KEY_ENTER) { return mView.requestStop(); }
        return false;
    }
    function onTap(event) as Lang.Boolean { return true; }
    function onSwipe(event) as Lang.Boolean { return mView.requestPage(event.getDirection()); }
}
