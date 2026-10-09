using Toybox.Lang;
using Toybox.WatchUi;

class StartConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    private var mTarget;
    private var mHandled = false;

    function initialize(target) {
        ConfirmationDelegate.initialize();
        mTarget = target;
    }

    function onResponse(response) as Lang.Boolean {
        if (mHandled) { return true; }
        mHandled = true;
        if (response == WatchUi.CONFIRM_YES) { mTarget.scheduleConfirmedStart(); }
        return true;
    }
}
