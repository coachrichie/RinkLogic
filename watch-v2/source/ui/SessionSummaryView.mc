using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;

class SessionSummaryView extends WatchUi.View {
    private var mSummary;
    private var mPage = 0;

    function initialize(summary) {
        View.initialize();
        mSummary = summary == null ? {} : summary;
    }

    function getPage() as Lang.Number { return mPage; }

    function requestPage(direction) as Lang.Boolean {
        if (direction == WatchUi.SWIPE_RIGHT || direction == :previous) {
            mPage = (mPage + 2) % 3;
        } else {
            mPage = (mPage + 1) % 3;
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(0x12C986, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()*15/100, Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.SummaryTitle),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (mPage == 0) {
            drawMetric(dc, 32, Rez.Strings.SummaryDuration,
                formatDuration(value(:durationMs)));
            drawMetric(dc, 51, Rez.Strings.SummaryAverageHr,
                formatMetric(value(:averageHeartRate)));
            drawMetric(dc, 70, Rez.Strings.SummaryMaximumHr,
                formatMetric(value(:maximumHeartRate)));
        } else if (mPage == 1) {
            drawMetric(dc, 32, Rez.Strings.SummaryShiftCount,
                formatMetric(value(:shiftCount)));
            drawMetric(dc, 51, Rez.Strings.SummaryIceTime,
                formatDuration(value(:timeOnIceMs)));
            drawMetric(dc, 70, Rez.Strings.SummaryBenchTime,
                formatDuration(value(:benchTimeMs)));
        } else {
            drawMetric(dc, 32, Rez.Strings.SummaryAverageShift,
                formatDuration(value(:averageShiftMs)));
            drawMetric(dc, 51, Rez.Strings.SummaryLongestShift,
                formatDuration(value(:longestShiftMs)));
            drawMetric(dc, 70, Rez.Strings.SummaryAverageShiftHr,
                formatMetric(value(:averageShiftHeartRate)));
        }

        dc.setColor(0x687A97, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()*86/100, Graphics.FONT_XTINY,
            (mPage + 1).toString() + " / 3",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function value(key) {
        return mSummary.hasKey(key) ? mSummary[key] : null;
    }

    private function formatMetric(metric) as Lang.String {
        return metric == null ? "--" : metric.toString();
    }

    private function formatDuration(milliseconds) as Lang.String {
        if (milliseconds == null || milliseconds < 0) { return "--"; }
        var totalSeconds = milliseconds / 1000;
        var hours = totalSeconds / 3600;
        var minutes = (totalSeconds % 3600) / 60;
        var seconds = totalSeconds % 60;
        if (hours > 0) {
            return hours.format("%02d") + ":" + minutes.format("%02d") +
                ":" + seconds.format("%02d");
        }
        return minutes.format("%02d") + ":" + seconds.format("%02d");
    }

    private function drawMetric(dc as Graphics.Dc, yPercent as Lang.Number,
        label, metric as Lang.String) as Void {
        dc.setColor(0x8FA0BA, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()*yPercent/100,
            Graphics.FONT_XTINY, WatchUi.loadResource(label),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()*(yPercent+8)/100,
            Graphics.FONT_SMALL, metric,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class SessionSummaryInputDelegate extends WatchUi.InputDelegate {
    private var mView;
    function initialize(view) { InputDelegate.initialize(); mView = view; }

    function onSwipe(event as WatchUi.SwipeEvent) as Lang.Boolean {
        return mView.requestPage(event.getDirection());
    }

    function onTap(event) as Lang.Boolean { return mView.requestPage(:next); }

    function onKey(event as WatchUi.KeyEvent) as Lang.Boolean {
        var key = event.getKey();
        if (key == WatchUi.KEY_UP) { return mView.requestPage(:previous); }
        if (key == WatchUi.KEY_DOWN || key == WatchUi.KEY_ENTER) {
            return mView.requestPage(:next);
        }
        if (key == WatchUi.KEY_ESC) { System.exit(); return true; }
        return false;
    }
}
