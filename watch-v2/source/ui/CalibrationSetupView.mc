using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class CalibrationSetupView extends WatchUi.View {
    private var mTarget;
    private var mSport = :inline;
    private var mCondition = :skate_only;
    private var mDistanceCm = 2500;
    private var mRepetitions = 5;

    function initialize(target) {
        View.initialize();
        mTarget = target;
    }

    function configuration() as Lang.Dictionary {
        return {:sport=>mSport, :condition=>mCondition,
            :referenceDistanceCm=>mDistanceCm, :targetRepetitions=>mRepetitions};
    }

    function cycleSelection(direction) as Void {
        if (direction > 0) {
            if (mSport == :inline) { mSport = :ice; }
            else if (mCondition == :skate_only) { mCondition = :puck_stickhandling; }
            else if (mDistanceCm == 2000) { mDistanceCm = 2500; }
            else if (mDistanceCm == 2500) { mDistanceCm = 3000; }
        } else {
            if (mSport == :ice) { mSport = :inline; }
            else if (mCondition == :puck_stickhandling) { mCondition = :skate_only; }
            else if (mDistanceCm == 3000) { mDistanceCm = 2500; }
            else if (mDistanceCm == 2500) { mDistanceCm = 2000; }
        }
        WatchUi.requestUpdate();
    }

    function requestStart() as Void {
        mTarget.startCalibration(mSport, mCondition, mDistanceCm, mRepetitions);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var centerX = dc.getWidth() / 2;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(0xC8E5F4, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 42, Graphics.FONT_LARGE,
            WatchUi.loadResource(Rez.Strings.CalibrationTitle),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x8FA6C1, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 105, Graphics.FONT_SMALL,
            mSport == :ice ? "ICE" : "INLINE",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, 145, Graphics.FONT_SMALL,
            mCondition == :skate_only ? "SKATE ONLY" : "PUCK + STICK",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, 185, Graphics.FONT_SMALL,
            (mDistanceCm / 100).toString() + " m",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x20D49A, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(centerX - 90, 235, 180, 46);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 258, Graphics.FONT_SMALL, "START TEST",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x8092A9, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 325, Graphics.FONT_XTINY, "UP/DOWN: OPTIONS · SELECT: START",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class CalibrationSetupInputDelegate extends WatchUi.InputDelegate {
    private var mView;
    function initialize(view) { InputDelegate.initialize(); mView = view; }
    function onKey(event as WatchUi.KeyEvent) as Lang.Boolean {
        var key = event.getKey();
        if (key == WatchUi.KEY_ENTER) { mView.requestStart(); return true; }
        if (key == WatchUi.KEY_UP) { mView.cycleSelection(1); return true; }
        if (key == WatchUi.KEY_DOWN) { mView.cycleSelection(-1); return true; }
        if (key == WatchUi.KEY_ESC) { return false; }
        return false;
    }
    function onSwipe(event) as Lang.Boolean {
        mView.cycleSelection(event.getDirection() == WatchUi.SWIPE_RIGHT ? 1 : -1);
        return true;
    }
    function onTap(event) as Lang.Boolean { mView.requestStart(); return true; }
}
