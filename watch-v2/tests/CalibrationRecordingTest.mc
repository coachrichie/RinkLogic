using Toybox.Lang;
using Toybox.Test as Test;

(:test)
function calibrationManifestRowUsesExplicitUnitsAndStatus(logger as Test.Logger) as Lang.Boolean {
    var row = CalibrationManifest.row("session-1", 2, :inline,
        :puck_stickhandling, 2500, 9, :valid);
    return row[:sessionId].equals("session-1") && row[:repetition] == 2 &&
        row[:sport].equals("inline") && row[:condition].equals("puck_stickhandling") &&
        row[:referenceDistanceCm] == 2500 && row[:referencePushes] == 9 &&
        row[:markerStatus].equals("valid");
}
