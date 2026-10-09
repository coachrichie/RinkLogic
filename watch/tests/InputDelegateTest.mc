using Toybox.Lang;
using Toybox.Test as Test;

class MarkerTargetFake {
    var mMarkerCount = 0;
    var mResult = true;

    function markShiftNow() as Lang.Boolean {
        mMarkerCount += 1;
        return mResult;
    }
}

(:test)
function selectCreatesExactlyOneMarkerInTheSameInputEvent(logger as Test.Logger) as Lang.Boolean {
    var target = new MarkerTargetFake();
    var delegate = new HockeyInputDelegate(target);
    var handled = delegate.onSelect();
    return handled && target.mMarkerCount == 1;
}

(:test)
function failedMarkerIsHandledWithoutASecondAttempt(logger as Test.Logger) as Lang.Boolean {
    var target = new MarkerTargetFake();
    target.mResult = false;
    var delegate = new HockeyInputDelegate(target);
    var handled = delegate.onSelect();
    return handled && target.mMarkerCount == 1;
}
