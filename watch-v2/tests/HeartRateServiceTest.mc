using Toybox.Lang;
using Toybox.Test as Test;

class HrInfoFake {
    var heartRate;
    function initialize(value) { heartRate = value; }
}

(:test)
function validHeartRateIsForwarded(logger as Test.Logger) as Lang.Boolean {
    var sample = HeartRateService.normalize(new HrInfoFake(147));
    return sample[:heartRate] == 147 && sample[:quality] == :active;
}

(:test)
function invalidHeartRateBecomesMissing(logger as Test.Logger) as Lang.Boolean {
    var sample = HeartRateService.normalize(new HrInfoFake(0));
    return sample[:heartRate] == null && sample[:quality] == :missing;
}
