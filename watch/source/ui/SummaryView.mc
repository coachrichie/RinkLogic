using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class UiText {
    public static function get(resource) as Lang.String {
        return WatchUi.loadResource(resource) as Lang.String;
    }
}

class SummaryView extends WatchUi.View {
    private var mDurationMs = 0;
    private var mShiftCount = 0;
    private var mIceTimeMs = 0;
    private var mTrainingEffect = null;

    public function initialize(durationMs, shiftCount, iceTimeMs, trainingEffect) {
        View.initialize();
        mDurationMs = durationMs;
        mShiftCount = shiftCount;
        mIceTimeMs = iceTimeMs;
        mTrainingEffect = trainingEffect;
    }

    public function getDurationMs() as Lang.Number { return mDurationMs; }
    public function getShiftCount() as Lang.Number { return mShiftCount; }
    public function getIceTimeMs() as Lang.Number { return mIceTimeMs; }
    public function getAnalysisLabel() as Lang.String { return UiText.get(Rez.Strings.AnalysisAfterSave); }

    function onUpdate(dc as Graphics.Dc) as Void {
        drawBackground(dc);
        var x = dc.getWidth() / 2;
        drawLine(dc, UiText.get(Rez.Strings.SummaryTitle), x, 24, Graphics.FONT_SMALL);
        drawLine(dc, UiText.get(Rez.Strings.SummaryDuration) + ": " + formatDuration(mDurationMs), x, 58, Graphics.FONT_SMALL);
        drawLine(dc, UiText.get(Rez.Strings.SummaryShifts) + ": " + mShiftCount.toString(), x, 84, Graphics.FONT_SMALL);
        drawLine(dc, UiText.get(Rez.Strings.SummaryIceTime) + ": " + formatDuration(mIceTimeMs), x, 110, Graphics.FONT_SMALL);
        if (mTrainingEffect != null) {
            drawLine(dc, UiText.get(Rez.Strings.TrainingEffect) + ": " + mTrainingEffect.format("%.1f"), x, 136, Graphics.FONT_SMALL);
        }
        drawLine(dc, getAnalysisLabel(), x, dc.getHeight() - 24, Graphics.FONT_SMALL);
    }

    private function drawBackground(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    private function drawLine(dc as Graphics.Dc, text as Lang.String, x as Lang.Number, y as Lang.Number, font) as Void {
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function formatDuration(milliseconds as Lang.Number) as Lang.String {
        var totalSeconds = milliseconds / 1000;
        var minutes = totalSeconds / 60;
        var seconds = totalSeconds % 60;
        return minutes.format("%02d") + ":" + seconds.format("%02d");
    }
}
