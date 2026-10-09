using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Timer;
using Toybox.WatchUi;

class ReadyView extends WatchUi.View {
    private var mTarget;
    private var mStatusSource;
    private var mHeartRateSource;
    private var mClock;
    private var mHeartRateSourceStarted = false;
    private var mHeartRateAt = null;
    private var mTimer = null;
    private var mBackground = null;
    private var mLogo = null;

    function initialize(target, statusSource, heartRateSource, clock) {
        View.initialize();
        mTarget = target;
        mStatusSource = statusSource;
        mHeartRateSource = heartRateSource;
        mClock = clock;
    }

    function requestStart() as Void {
        onHide();
        mTarget.requestStart();
    }

    function requestCalibration() as Void {
        onHide();
        mTarget.requestCalibration();
    }

    function onShow() as Void {
        mHeartRateAt = null;
        mHeartRateSourceStarted = mHeartRateSource.start(method(:onHeartRate));
        mTimer = new Timer.Timer();
        mTimer.start(method(:refresh), 1000, true);
    }

    function onHide() as Void {
        if (mTimer != null) { mTimer.stop(); mTimer = null; }
        if (mHeartRateSourceStarted) {
            mHeartRateSource.stop();
            mHeartRateSourceStarted = false;
        }
        mBackground = null;
        mLogo = null;
    }

    function refresh() as Void { WatchUi.requestUpdate(); }

    function onHeartRate(sample) as Void {
        if (sample != null && sample.hasKey(:heartRate) && sample[:heartRate] != null &&
            sample[:heartRate] > 0 && sample[:heartRate] <= 255) {
            mHeartRateAt = mClock.nowMs();
        } else {
            mHeartRateAt = null;
        }
        WatchUi.requestUpdate();
    }

    function getDisplayValues() as Lang.Dictionary {
        var status = mStatusSource.snapshot();
        return {
            :phoneConnected=>status[:phoneConnected],
            :heartSignal=>mHeartRateAt != null && mClock.nowMs() - mHeartRateAt <= 5000
        };
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var status = getDisplayValues();
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var active = 0x20D49A;
        var pulseAvailable = 0x3BA5FF;
        var inactive = 0x8092A9;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        if (mBackground == null) {
            mBackground = WatchUi.loadResource(Rez.Drawables.ReadyBackground);
        }
        if (mLogo == null) { mLogo = WatchUi.loadResource(Rez.Drawables.ReadyLogo); }
        dc.drawBitmap(centerX - 208, height / 2 - 208, mBackground);
        dc.drawBitmap(centerX - 44, height * 8 / 100, mLogo);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 47 / 100, Graphics.FONT_LARGE,
            WatchUi.loadResource(Rez.Strings.ReadyTitle),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0xC8E5F4, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 56 / 100, Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.AppName),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var phoneX = width * 36 / 100;
        var heartX = width * 64 / 100;
        var iconY = height * 64 / 100;
        dc.setColor(status[:phoneConnected] ? active : inactive, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(phoneX - 10, iconY - 14, 20, 28, 3);
        dc.drawLine(phoneX - 3, iconY + 10, phoneX + 3, iconY + 10);
        dc.drawText(phoneX, height * 71 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.PhoneStatus),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(status[:heartSignal] ? pulseAvailable : inactive, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(heartX - 6, iconY - 5, 7);
        dc.fillCircle(heartX + 6, iconY - 5, 7);
        dc.fillPolygon([[heartX - 13, iconY - 4], [heartX + 13, iconY - 4],
            [heartX, iconY + 15]]);
        dc.drawText(heartX, height * 71 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.HrSignalStatus),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0xB6C6D8, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 79 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.PulseSourceUnknown),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x0D6CC1, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(centerX - 76, height * 85 / 100, 152, 40);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 85 / 100 + 20, Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.ReadyStart),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0xB6C6D8, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 77 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.CalibrationAction),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class ReadyInputDelegate extends WatchUi.InputDelegate {
    private var mView;

    function initialize(view) {
        InputDelegate.initialize();
        mView = view;
    }

    function onKey(event as WatchUi.KeyEvent) as Lang.Boolean {
        if (event.getKey() != WatchUi.KEY_ENTER) { return false; }
        mView.requestStart();
        return true;
    }

    function onTap(event as WatchUi.ClickEvent) as Lang.Boolean {
        var coordinates = event.getCoordinates();
        var settings = Toybox.System.getDeviceSettings();
        var centerX = settings.screenWidth / 2;
        var startY = settings.screenHeight * 85 / 100;
        var calibrationY = settings.screenHeight * 77 / 100;
        if (coordinates[0] >= centerX - 100 && coordinates[0] <= centerX + 100 &&
            coordinates[1] >= calibrationY - 18 && coordinates[1] <= calibrationY + 18) {
            mView.requestCalibration();
            return true;
        }
        if (coordinates[0] < centerX - 76 || coordinates[0] > centerX + 76 ||
            coordinates[1] < startY || coordinates[1] > startY + 40) { return false; }
        mView.requestStart();
        return true;
    }
}
