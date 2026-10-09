using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;

// Drawing and hit testing share the same scaled, inset rectangles.
class RoundLayout {
    var width;
    var height;
    function initialize() {
        var settings = System.getDeviceSettings();
        width = settings.screenWidth;
        height = settings.screenHeight;
    }
    function update(dc) { width = dc.getWidth(); height = dc.getHeight(); }
    function contains(point, left, top, right, bottom) as Lang.Boolean {
        return point[0] >= width * left / 100 && point[0] < width * right / 100 &&
            point[1] >= height * top / 100 && point[1] < height * bottom / 100;
    }
    function background(dc) {
        update(dc);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
    }
    function text(dc, value, centerX, centerY, maxWidth, large) {
        var font = large ? Graphics.FONT_MEDIUM : Graphics.FONT_SMALL;
        if (dc.getTextWidthInPixels(value, font) > width * maxWidth / 100) {
            font = Graphics.FONT_XTINY;
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width * centerX / 100, height * centerY / 100, font, value,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
    function button(dc, value, left, top, right, bottom, selected) {
        dc.setColor(selected ? Graphics.COLOR_BLUE : Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(width * left / 100, height * top / 100,
            width * (right-left) / 100, height * (bottom-top) / 100);
        text(dc, value, (left+right)/2, (top+bottom)/2, right-left-4, false);
    }
}
