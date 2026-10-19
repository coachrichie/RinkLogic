using Toybox.Lang;
using Toybox.Test as Test;
using Toybox.WatchUi;

function completeSummary() as Lang.Dictionary {
    return {
        :durationMs=>3661000,
        :averageHeartRate=>150,
        :maximumHeartRate=>190,
        :shiftCount=>12,
        :timeOnIceMs=>600000,
        :benchTimeMs=>3061000,
        :averageShiftMs=>50000,
        :longestShiftMs=>80000,
        :averageShiftHeartRate=>165
    };
}

(:test)
function sessionSummaryRendersAllThreePages(logger as Test.Logger) as Lang.Boolean {
    var view = new SessionSummaryView(completeSummary());
    var dc = new DialDcFake();
    view.onUpdate(dc);
    if (!dialContainsText(dc, "61.0 min") || !dialContainsText(dc, "150") ||
        !dialContainsText(dc, "190")) { return false; }
    view.requestPage(WatchUi.SWIPE_LEFT);
    dc = new DialDcFake();
    view.onUpdate(dc);
    if (!dialContainsText(dc, "12") || !dialContainsText(dc, "10.0 min") ||
        !dialContainsText(dc, "51.0 min")) { return false; }
    view.requestPage(WatchUi.SWIPE_LEFT);
    dc = new DialDcFake();
    view.onUpdate(dc);
    return dialContainsText(dc, "0.83 min") && dialContainsText(dc, "1.33 min") &&
        dialContainsText(dc, "165");
}

(:test)
function sessionSummaryUsesMissingMarker(logger as Test.Logger) as Lang.Boolean {
    var view = new SessionSummaryView({
        :durationMs=>0, :averageHeartRate=>null, :maximumHeartRate=>null,
        :shiftCount=>0, :timeOnIceMs=>0, :benchTimeMs=>0,
        :averageShiftMs=>null, :longestShiftMs=>null,
        :averageShiftHeartRate=>null
    });
    var dc = new DialDcFake();
    view.onUpdate(dc);
    return dialContainsText(dc, "0.0 min") && dialContainsText(dc, "--");
}

(:test)
function sessionSummaryNavigationWrapsBothDirections(logger as Test.Logger) as Lang.Boolean {
    var view = new SessionSummaryView(completeSummary());
    var input = new SessionSummaryInputDelegate(view);
    if (view.getPage() != 0 ||
        !input.onSwipe(new DirectionSwipeEventFake(WatchUi.SWIPE_RIGHT)) ||
        view.getPage() != 2) { return false; }
    if (!input.onKey(new PhysicalKeyEventFake(WatchUi.KEY_DOWN)) ||
        view.getPage() != 0) { return false; }
    return input.onKey(new PhysicalKeyEventFake(WatchUi.KEY_UP)) &&
        view.getPage() == 2;
}
