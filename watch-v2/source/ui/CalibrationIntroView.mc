using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class CalibrationIntroView extends WatchUi.View {
    private var mTarget;
    private var mSport;

    function initialize(target, sport) {
        View.initialize();
        mTarget = target;
        mSport = CalibrationTypes.validSport(sport) ? sport : null;
    }

    function sport() { return mSport; }

    function requestStart() as Lang.Boolean {
        if (mSport == null) { return false; }
        mTarget.startCalibration(mSport);
        return true;
    }

    function requestCancel() as Lang.Boolean {
        mTarget.confirmCancelCalibration();
        return true;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var centerX = dc.getWidth() / 2;
        var height = dc.getHeight();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(0xC8E5F4, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 14 / 100, Graphics.FONT_MEDIUM,
            WatchUi.loadResource(Rez.Strings.CalibrationTitle),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 30 / 100, Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.CalibrationCourse),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, height * 42 / 100, Graphics.FONT_SMALL,
            mSport == :inline ? WatchUi.loadResource(Rez.Strings.SportInline) :
                WatchUi.loadResource(Rez.Strings.SportIce),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, height * 55 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.CalibrationProtocol),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x20D49A, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 72 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.CalibrationIntroStart),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x8FA6C1, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 84 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.CalibrationUpperCancel),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class CalibrationIntroInputDelegate extends WatchUi.InputDelegate {
    private var mView;
    function initialize(view) { InputDelegate.initialize(); mView = view; }
    function onKey(event as WatchUi.KeyEvent) as Lang.Boolean {
        if (event.getKey() == WatchUi.KEY_ESC) { return mView.requestStart(); }
        if (event.getKey() == WatchUi.KEY_ENTER) { return mView.requestCancel(); }
        return false;
    }
    function onTap(event) as Lang.Boolean {
        var coordinates = event.getCoordinates();
        if (coordinates == null || coordinates.size() < 2) { return false; }
        var height = Toybox.System.getDeviceSettings().screenHeight;
        if (coordinates[1] >= height * 80 / 100) { return mView.requestCancel(); }
        if (coordinates[1] >= height * 60 / 100) { return mView.requestStart(); }
        return false;
    }
}
