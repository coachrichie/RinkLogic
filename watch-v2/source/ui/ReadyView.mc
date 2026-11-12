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
    private var mCalibrationStatuses = {:ice=>false, :inline=>false};

    function initialize(target, statusSource, heartRateSource, clock) {
        View.initialize();
        mTarget = target;
        mStatusSource = statusSource;
        mHeartRateSource = heartRateSource;
        mClock = clock;
    }

    function requestContinue() as Void {
        onHide();
        mTarget.requestContinue();
    }

    function setCalibrationStatuses(statuses) as Void {
        try {
            mCalibrationStatuses = {:ice=>statuses[:ice] == true,
                :inline=>statuses[:inline] == true};
        } catch (ex) {
            mCalibrationStatuses = {:ice=>false, :inline=>false};
        }
    }

    // Transitional adapter used until the application routing is switched to both slots.
    function setCalibrationProfile(profile) as Void {
        mCalibrationStatuses = {:ice=>profile != null && profile[:sport] == :ice,
            :inline=>profile != null && profile[:sport] == :inline};
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

        var compact = height < 300;
        var phoneX = width * 30 / 100;
        var heartX = width * 70 / 100;
        var iconY = height * 62 / 100;
        dc.setColor(status[:phoneConnected] ? active : inactive, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(phoneX - 10, iconY - 14, 20, 28, 3);
        dc.drawLine(phoneX - 3, iconY + 10, phoneX + 3, iconY + 10);
        var statusY = height * (compact ? 68 : 69) / 100;
        dc.drawText(phoneX, statusY, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.PhoneStatus),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(status[:heartSignal] ? pulseAvailable : inactive, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(heartX - 6, iconY - 5, 7);
        dc.fillCircle(heartX + 6, iconY - 5, 7);
        dc.fillPolygon([[heartX - 13, iconY - 4], [heartX + 13, iconY - 4],
            [heartX, iconY + 15]]);
        dc.drawText(heartX, statusY, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.HrSignalStatus),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(inactive, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * (compact ? 74 : 75) / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.PulseSourceUnknown),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0xB6C6D8, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * (compact ? 80 : 81) / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.SportIce) + " " +
                (mCalibrationStatuses[:ice] ? "✓" : "—") + " · " +
                WatchUi.loadResource(Rez.Strings.SportInline) + " " +
                (mCalibrationStatuses[:inline] ? "✓" : "—"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        var maximumButtonWidth = compact ? 130 : (width < 390 ? 180 : 200);
        var buttonWidth = width - 18 < maximumButtonWidth ? width - 18 : maximumButtonWidth;
        var buttonHeight = height * 10 / 100 < 40 ? height * 10 / 100 : 40;
        var buttonY = height * (compact ? 85 : 87) / 100;
        dc.setColor(0x0D6CC1, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(centerX - buttonWidth / 2, buttonY,
            buttonWidth, buttonHeight);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, buttonY + buttonHeight / 2, Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.ReadyContinue),
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
        if (event.getKey() == WatchUi.KEY_ENTER) { mView.requestContinue(); return true; }
        return false;
    }

    function onTap(event as WatchUi.ClickEvent) as Lang.Boolean {
        var coordinates = event.getCoordinates();
        if (coordinates == null || coordinates.size() < 2) { return false; }
        var settings = Toybox.System.getDeviceSettings();
        var centerX = settings.screenWidth / 2;
        var compact = settings.screenHeight < 300;
        var startY = settings.screenHeight * (compact ? 85 : 87) / 100;
        var buttonHeight = settings.screenHeight * 10 / 100 < 40 ?
            settings.screenHeight * 10 / 100 : 40;
        var maximumButtonWidth = compact ? 130 :
            (settings.screenWidth < 390 ? 180 : 200);
        var buttonWidth = settings.screenWidth - 18 < maximumButtonWidth ?
            settings.screenWidth - 18 : maximumButtonWidth;
        if (coordinates[1] < startY || coordinates[1] > startY + buttonHeight) {
            return false;
        }
        if (coordinates[0] >= centerX - buttonWidth / 2 &&
            coordinates[0] <= centerX + buttonWidth / 2) {
            mView.requestContinue();
            return true;
        }
        return false;
    }
}
