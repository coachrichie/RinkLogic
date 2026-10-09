using Toybox.Lang;
using Toybox.Test as Test;

(:test)
function shortMotionBatchIsInvalid(logger as Test.Logger) as Lang.Boolean {
    return !MotionFeatures.fromArrays([0], [0], [1000],
        null, null, null)[:valid];
}

(:test)
function steadyGravityHasLowMotion(logger as Test.Logger) as Lang.Boolean {
    var f = MotionFeatures.fromArrays([0,0,0,0,0],
        [0,0,0,0,0], [1000,1000,1000,1000,1000],
        null, null, null);
    return f[:valid] && f[:motionMg] == 0 &&
        f[:rotationDps] == null && !f[:periodic];
}

(:test)
function repeatedAccelerationHasHigherMotion(logger as Test.Logger) as Lang.Boolean {
    var f = MotionFeatures.fromArrays([0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0],
        [1000,1300,1000,1300,1000,1300,1000,1300],
        [0.0,40.0,0.0,40.0,0.0,40.0,0.0,40.0],
        [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0],
        [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]);
    return f[:valid] && f[:motionMg] >= 140 &&
        f[:rotationDps] >= 15 && f[:periodic];
}

(:test)
function nullMotionSampleIsInvalid(logger as Test.Logger) as Lang.Boolean {
    return !MotionFeatures.fromArrays([0,0,null,0,0],
        [0,0,0,0,0], [1000,1000,1000,1000,1000],
        null, null, null)[:valid];
}
