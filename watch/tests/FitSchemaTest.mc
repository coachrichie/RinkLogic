using Toybox.Lang;
using Toybox.Test as Test;

(:test)
function versionThreePreservesExistingIdsAndAddsHrSummaries(logger as Test.Logger) as Lang.Boolean {
    return FitSchema.VERSION == 3 &&
        FitSchema.getFields().size() == 42 &&
        FitSchema.hasOnlyUniqueIds() &&
        FitSchema.usesStableIdRange(1, 42);
}

(:test)
function recordFieldsStayWithinTheFitRecordBudget(logger as Test.Logger) as Lang.Boolean {
    return FitSchema.getRecordPayloadBytes() <= 256 &&
        FitSchema.getRecordPayloadBytes() == 26;
}

(:test)
function fieldMetadataIncludesRequiredUnitsAndMessageScopes(logger as Test.Logger) as Lang.Boolean {
    var fields = FitSchema.getFields();
    var mode = fields[2 - 1];
    var shiftState = fields[3 - 1];
    var confidence = fields[5 - 1];
    var intensity = fields[6 - 1];
    var quality = fields[7 - 1];
    return mode[:scope] == :record && mode[:unit].equals("enum") &&
        shiftState[:scope] == :record &&
        confidence[:unit].equals("percent") &&
        intensity[:unit].equals("au_x100") &&
        quality[:unit].equals("bitmask");
}

(:test)
function fitSchemaContainsHrSummaryFieldsAfterExistingRegistry(logger as Test.Logger) as Lang.Boolean {
    var fields = FitSchema.getFields();
    return fields.size() == 42 && fields[34][:key] == :hrSampleCount &&
        fields[35][:key] == :recoveryMs && fields[41][:key] == :hrZone5Seconds;
}
