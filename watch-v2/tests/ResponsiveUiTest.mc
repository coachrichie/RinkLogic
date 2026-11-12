using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Test as Test;

class ResponsiveDcFake extends Graphics.Dc {
    private var mFakeWidth;
    private var mFakeHeight;
    var textY = [];
    var rectangles = [];
    function initialize(width, height) { mFakeWidth = width; mFakeHeight = height; }
    function getWidth() as Lang.Number { return mFakeWidth; }
    function getHeight() as Lang.Number { return mFakeHeight; }
    function setColor(foreground, background) as Void { }
    function clear() as Void { }
    function drawBitmap(x, y, bitmap) as Void { }
    function drawText(x, y, font, value, justification) as Void { textY.add(y); }
    function drawLine(x1, y1, x2, y2) as Void { }
    function fillCircle(x, y, radius) as Void { }
    function fillPolygon(points) as Void { }
    function drawRoundedRectangle(x, y, width, height, radius) as Void { }
    function fillRectangle(x, y, width, height) as Void {
        rectangles.add([x, y, width, height]);
    }
    function contentFits() as Lang.Boolean {
        for (var i = 0; i < textY.size(); i += 1) {
            if (textY[i] < 0 || textY[i] >= mFakeHeight) { return false; }
        }
        for (var j = 0; j < rectangles.size(); j += 1) {
            var box = rectangles[j];
            if (box[0] < 0 || box[1] < 0 || box[0] + box[2] > mFakeWidth ||
                box[1] + box[3] > mFakeHeight) { return false; }
        }
        return true;
    }
}

(:test)
function responsiveLaunchAndCalibrationViewsStayInsideRoundDisplays(logger as Test.Logger) as Lang.Boolean {
    var sizes = [218, 240, 260, 280, 360, 390, 416, 454, 466];
    for (var i = 0; i < sizes.size(); i += 1) {
        var size = sizes[i];
        var views = [];
        views.add(new ReadyView(new ReadyStartTargetFake(), new ReadyStatusSourceFake(),
            new HeartRateSourceFake(), new ClockFake()));
        views.add(new StartMenuView(new CalibrationTargetFake()));
        views.add(new SportSelectionView(new CalibrationTargetFake(), :training, :ice));
        views.add(new CalibrationIntroView(new CalibrationTargetFake(), :ice));
        var controller = new CalibrationController();
        if (!controller.configure(:ice)) { return false; }
        views.add(new CalibrationRunView(new CalibrationTargetFake(), controller));
        views.add(new CalibrationSummaryView(new CalibrationTargetFake(),
            calibrationProfileCandidate(:ice, 1.0)));
        for (var j = 0; j < views.size(); j += 1) {
            var dc = new ResponsiveDcFake(size, size);
            views[j].onUpdate(dc);
            if (!dc.contentFits()) { return false; }
        }
    }
    return true;
}
