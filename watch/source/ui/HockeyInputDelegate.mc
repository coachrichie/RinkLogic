using Toybox.Lang;
using Toybox.WatchUi;

class HockeyInputDelegate extends WatchUi.BehaviorDelegate {
    private var mTarget = null;

    public function initialize(target) {
        BehaviorDelegate.initialize();
        mTarget = target;
    }

    // The performance page selects the marker; the events page selects the
    // highlighted counter/action. Each button event performs one action.
    public function onSelect() as Lang.Boolean {
        if (mTarget has :activateSelection) { mTarget.activateSelection(); }
        else { mTarget.markShiftNow(); }
        return true;
    }

    // Coordinates route only to visible action regions.
    public function onTap(clickEvent) as Lang.Boolean {
        return mTarget.handleTap(clickEvent.getCoordinates());
    }

    public function onBack() as Lang.Boolean {
        mTarget.requestStopConfirmation();
        return true;
    }

    public function onHold(clickEvent) as Lang.Boolean {
        return false;
    }
    public function onNextPage() as Lang.Boolean { mTarget.moveLiveSelection(1); return true; }
    public function onPreviousPage() as Lang.Boolean { mTarget.moveLiveSelection(-1); return true; }
    public function onNextMode() as Lang.Boolean { return onNextPage(); }
    public function onPreviousMode() as Lang.Boolean { return onPreviousPage(); }
    public function onMenu() as Lang.Boolean { mTarget.togglePage(); return true; }
    public function onKey(keyEvent) as Lang.Boolean {
        if (keyEvent.getKey() == WatchUi.KEY_DOWN) { return onNextPage(); }
        if (keyEvent.getKey() == WatchUi.KEY_UP) { return onPreviousPage(); }
        return false;
    }
}
