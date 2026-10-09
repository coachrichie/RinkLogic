using Toybox.Lang;
using Toybox.Math;

class MotionFeatures {
    static function fromArrays(ax as Lang.Array or Null, ay as Lang.Array or Null,
        az as Lang.Array or Null, gx as Lang.Array or Null,
        gy as Lang.Array or Null, gz as Lang.Array or Null) as Lang.Dictionary {
        if (ax == null || ay == null || az == null) { return invalid(); }
        var count = ax.size();
        if (ay.size() < count) { count = ay.size(); }
        if (az.size() < count) { count = az.size(); }
        if (count < 5) { return invalid(); }

        var movement = 0.0;
        var rotation = 0.0;
        var peaks = 0;
        var previousDynamic = 0.0;
        var hasGyro = gx != null && gy != null && gz != null;
        if (hasGyro) {
            hasGyro = gx.size() >= count && gy.size() >= count && gz.size() >= count;
        }
        for (var i = 0; i < count; i += 1) {
            if (ax[i] == null || ay[i] == null || az[i] == null) { return invalid(); }
            var x = ax[i] as Lang.Number;
            var y = ay[i] as Lang.Number;
            var z = az[i] as Lang.Number;
            if (x < -16000 || x > 16000 || y < -16000 || y > 16000 ||
                z < -16000 || z > 16000) { return invalid(); }
            var magnitude = Math.sqrt(x*x + y*y + z*z);
            var dynamic = magnitude - 1000.0;
            if (dynamic < 0) { dynamic = -dynamic; }
            movement += dynamic;
            if (dynamic >= 150 && previousDynamic < 150) { peaks += 1; }
            previousDynamic = dynamic;
            if (hasGyro) {
                if (gx[i] == null || gy[i] == null || gz[i] == null) {
                    hasGyro = false;
                } else {
                    var rx = gx[i] as Lang.Float;
                    var ry = gy[i] as Lang.Float;
                    var rz = gz[i] as Lang.Float;
                    rotation += Math.sqrt(rx*rx + ry*ry + rz*rz);
                }
            }
        }
        return {:valid=>true, :motionMg=>(movement/count).toNumber(),
            :rotationDps=>hasGyro ? (rotation/count).toNumber() : null,
            :periodic=>peaks >= 2};
    }

    private static function invalid() as Lang.Dictionary {
        return {:valid=>false, :motionMg=>null,
            :rotationDps=>null, :periodic=>false};
    }
}
