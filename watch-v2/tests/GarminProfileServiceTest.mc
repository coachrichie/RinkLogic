using Toybox.Lang;
using Toybox.Test as Test;

(:test)
function profileNormalizesDocumentedGarminUnits(logger as Test.Logger) as Lang.Boolean {
    var result = GarminProfileService.normalize({
        :birthYear=>1983, :weightGrams=>82500, :heightCm=>181,
        :restingHr=>52, :hrMax=>191
    }, 2026);
    return result[:age] == 43 && result[:weightKg] == 82.5 &&
        result[:heightCm] == 181 && result[:restingHr] == 52 && result[:hrMax] == 191;
}

(:test)
function missingHrMaxRemainsUnavailable(logger as Test.Logger) as Lang.Boolean {
    var result = GarminProfileService.normalize({:birthYear=>1983}, 2026);
    return result[:hrMax] == null && result[:available][:hrMax] == false;
}

(:test)
function profileRejectsInvalidRawValues(logger as Test.Logger) as Lang.Boolean {
    var result = GarminProfileService.normalize({
        :birthYear=>2025, :weightGrams=>82, :heightCm=>500,
        :restingHr=>0, :hrMax=>300
    }, 2026);
    return result[:age] == null && result[:weightKg] == null &&
        result[:heightCm] == null && result[:restingHr] == null && result[:hrMax] == null;
}
