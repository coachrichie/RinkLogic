using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class ModeView extends WatchUi.View {
    private var mController = null;
    private var mSelection = 0;
    private var mStartRequestCount = 0;
    private var mPlayerProfile = null;
    private var mRound = new RoundLayout();

    public function initialize(controller) {
        View.initialize();
        mController = controller;
    }

    public function moveSelection(delta as Lang.Number) as Void {
        mSelection = (mSelection + delta + 3) % 3;
        WatchUi.requestUpdate();
    }

    public function getSelectedMode() as Lang.Symbol {
        return selectedMode();
    }
    public function getSelectionIndex() as Lang.Number { return mSelection; }
    public function getStartRequestCount() as Lang.Number { return mStartRequestCount; }
    public function setPlayerProfile(profile) { mPlayerProfile = profile; }

    public function requestStartConfirmation() as Void {
        mStartRequestCount += 1;
        var live = new LiveView(mController, selectedMode(), new SystemClock(), null, null);
        live.setPlayerProfile(mPlayerProfile);
        // Venu 2 Plus can keep a Confirmation view visible after the response
        // callback. Start directly and replace the mode screen so the live UI
        // is always reached after selecting Start Recording.
        if (live.startConfirmed()) {
            WatchUi.switchToView(live, new HockeyInputDelegate(live), WatchUi.SLIDE_LEFT);
        } else {
            WatchUi.switchToView(new StatusView(live.getStartFailureMessage()), new StartFailureDelegate(), WatchUi.SLIDE_LEFT);
        }
    }

    public function handleTap(point) as Lang.Boolean {
        if (mRound.contains(point, 15, 25, 85, 37)) { mSelection = 0; }
        else if (mRound.contains(point, 15, 39, 85, 51)) { mSelection = 1; }
        else if (mRound.contains(point, 25, 60, 75, 72)) { requestStartConfirmation(); }
        else { return false; }
        WatchUi.requestUpdate();
        return true;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        mRound.background(dc);
        mRound.text(dc, UiText.get(Rez.Strings.ModeTitle), 50, 14, 65, false);
        for (var i = 0; i < 2; i += 1) {
            mRound.button(dc, labelFor(i), 15, 25 + i * 14, 85, 37 + i * 14, mSelection == i);
        }
        mRound.button(dc, UiText.get(Rez.Strings.StartAction), 25, 60, 75, 72, mSelection == 2);
        mRound.text(dc, UiText.get(Rez.Strings.ModeHint), 50, 89, 50, false);
    }

    private function selectedMode() as Lang.Symbol {
        return mSelection == 0 ? HockeyMode.ICE : HockeyMode.INLINE_INDOOR;
    }

    private function labelFor(index as Lang.Number) as Lang.String {
        var prefix = index == mSelection ? "> " : "  ";
        if (index == 0) { return prefix + UiText.get(Rez.Strings.ModeIce); }
        if (index == 1) { return prefix + UiText.get(Rez.Strings.ModeInlineIndoor); }
        return prefix + UiText.get(Rez.Strings.ModeInlineIndoor);
    }

}

class ModeInputDelegate extends WatchUi.BehaviorDelegate {
    private var mView = null;

    public function initialize(view) {
        BehaviorDelegate.initialize();
        mView = view;
    }

    public function onSelect() as Lang.Boolean {
        if (mView.getSelectionIndex() == 2) { mView.requestStartConfirmation(); }
        return true;
    }

    public function onNextMode() as Lang.Boolean {
        mView.moveSelection(1);
        return true;
    }

    public function onPreviousMode() as Lang.Boolean {
        mView.moveSelection(-1);
        return true;
    }

    public function onNextPage() as Lang.Boolean { return onNextMode(); }
    public function onPreviousPage() as Lang.Boolean { return onPreviousMode(); }

    public function onKey(keyEvent) as Lang.Boolean {
        if (keyEvent.getKey() == WatchUi.KEY_DOWN) {
            mView.moveSelection(1);
            return true;
        }
        if (keyEvent.getKey() == WatchUi.KEY_UP) {
            mView.moveSelection(-1);
            return true;
        }
        return false;
    }

    public function onTap(clickEvent) as Lang.Boolean {
        return mView.handleTap(clickEvent.getCoordinates());
    }
}

class StartConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    private var mLive = null;

    public function initialize(live) {
        ConfirmationDelegate.initialize();
        mLive = live;
    }

    public function onResponse(response) as Lang.Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            if (mLive.startConfirmed()) {
                // Replace the modal confirmation instead of pushing behind it.
                // On Venu 2 Plus the confirmation can remain visible when a
                // normal pushView is issued from onResponse().
                WatchUi.switchToView(mLive, new HockeyInputDelegate(mLive), WatchUi.SLIDE_LEFT);
            } else {
                WatchUi.switchToView(new StatusView(mLive.getStartFailureMessage()), new StartFailureDelegate(), WatchUi.SLIDE_LEFT);
            }
        }
        return true;
    }
}

class StartFailureDelegate extends WatchUi.BehaviorDelegate {
    function initialize() { BehaviorDelegate.initialize(); }
    function onBack() as Lang.Boolean { WatchUi.popView(WatchUi.SLIDE_RIGHT); return true; }
}
