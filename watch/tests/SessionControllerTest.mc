using Toybox.Lang;
using Toybox.Test as Test;

class FakeFitField {
    var mValue = null;
    var mSession = null;
    var mId = 0;

    function initialize(session, fieldId) {
        mSession = session;
        mId = fieldId;
    }

    function setData(value) as Void {
        if (mSession.mFailSetDataId == mId && mSession.mFailSetDataValue == value) {
            throw new Lang.Exception();
        }
        mValue = value;
    }
}

class FakeFitSession {
    var mStartResult = true;
    var mStopResult = true;
    var mSaveResult = true;
    var mDiscardResult = true;
    var mLapResult = true;
    var mCreateCount = 0;
    var mLaps = 0;
    var mStartCalls = 0;
    var mStopCalls = 0;
    var mDiscardCalls = 0;
    var mFailAtCreateCount = 0;
    var mFailId = 0;
    var mCreatedIds = [];
    var mCreatedTypes = [];
    var mCreatedOptions = [];
    var mCreatedFields = new [34];
    var mStartRecordSnapshot = [];
    var mFailSetDataId = 0;
    var mFailSetDataValue = null;

    function createSession(options) {
        return self;
    }

    function createField(name, fieldId, type, options) {
        mCreateCount += 1;
        mCreatedIds.add(fieldId);
        mCreatedTypes.add(type);
        mCreatedOptions.add(options);
        if (mFailAtCreateCount == mCreateCount || mFailId == fieldId) {
            return null;
        }
        var field = new FakeFitField(self, fieldId);
        mCreatedFields[fieldId - 1] = field;
        return field;
    }

    function start() as Lang.Boolean {
        mStartCalls += 1;
        if (mCreatedFields[0] != null && mCreatedFields[1] != null && mCreatedFields[2] != null) {
            mStartRecordSnapshot = [mCreatedFields[0].mValue, mCreatedFields[1].mValue, mCreatedFields[2].mValue];
        }
        return mStartResult;
    }
    function stop() as Lang.Boolean { mStopCalls += 1; return mStopResult; }
    function save() as Lang.Boolean { return mSaveResult; }
    function discard() as Lang.Boolean {
        mDiscardCalls += 1;
        return mDiscardResult;
    }
    function addLap() as Lang.Boolean {
        if (mLapResult) { mLaps += 1; }
        return mLapResult;
    }
}

class NoCreateFieldFitSession {
    var mStartCalls = 0;
    var mStopCalls = 0;
    var mDiscardCalls = 0;

    function createSession(options) { return self; }
    function start() as Lang.Boolean { mStartCalls += 1; return true; }
    function stop() as Lang.Boolean { mStopCalls += 1; return true; }
    function discard() as Lang.Boolean { mDiscardCalls += 1; return true; }
}

class FreshRetryFitFactory {
    var mFirstSession = null;
    var mSecondSession = null;
    var mCreateSessionCalls = 0;

    function initialize() {
        mFirstSession = new FakeFitSession();
        mFirstSession.mFailAtCreateCount = 1;
        mSecondSession = new FakeFitSession();
    }

    function createSession(options) {
        mCreateSessionCalls += 1;
        return mCreateSessionCalls == 1 ? mFirstSession : mSecondSession;
    }
}

(:test)
function sessionCannotSaveBeforeStop(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    var controller = new SessionController(fake);
    controller.start(:ice);
    return controller.save() == false && controller.getState() == :recording;
}

(:test)
function sessionAllowsOnlyTheDocumentedLifecycle(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    var controller = new SessionController(fake);
    return controller.start(:ice) && controller.getState() == :recording &&
        controller.stop() && controller.getState() == :stopped &&
        controller.save() && controller.getState() == :saved &&
        controller.start(:ice) == false;
}

(:test)
function failedStopKeepsTheRecordingRecoverable(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    fake.mStopResult = false;
    var controller = new SessionController(fake);
    controller.start(:ice);
    return controller.stop() == false && controller.getState() == :recording;
}

(:test)
function failedSaveKeepsTheStoppedSessionRecoverable(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    fake.mSaveResult = false;
    var controller = new SessionController(fake);
    controller.start(:ice);
    controller.stop();
    return controller.save() == false && controller.getState() == :stopped;
}

(:test)
function aShiftCreatesOneLapAndFieldsAreAllocatedOnlyOnce(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    var controller = new SessionController(fake);
    controller.start(:ice);
    var fieldCountAfterStart = fake.mCreateCount;
    var firstShift = controller.markShift(:shift, 1000);
    var secondShift = controller.markShift(:bench, 2000);
    return firstShift && secondShift && fake.mLaps == 2 &&
        fieldCountAfterStart == 34 && fake.mCreateCount == fieldCountAfterStart;
}

(:test)
function failedShiftLapLeavesTheSessionRecording(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    fake.mLapResult = false;
    var controller = new SessionController(fake);
    controller.start(:ice);
    return controller.markShift(:shift, 1000) == false && controller.getState() == :recording &&
        fake.mCreatedFields[2].mValue == 1 && fake.mCreatedFields[15].mValue == 0 &&
        fake.mCreatedFields[16].mValue == 0 && fake.mCreatedFields[17].mValue == 0;
}

(:test)
function startWritesBenchSchemaAndModeBeforeAnyUserMarker(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    var controller = new SessionController(fake);
    return controller.start(:inlineIndoor) && fake.mCreatedFields[0].mValue == FitSchema.VERSION &&
        fake.mCreatedFields[1].mValue == 2 && fake.mCreatedFields[2].mValue == 1;
}

(:test)
function startPreparesSchemaModeAndBenchBeforeTheSessionCanStart(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    var controller = new SessionController(fake);
    return controller.start(:inlineIndoor) && fake.mStartRecordSnapshot[0] == FitSchema.VERSION &&
        fake.mStartRecordSnapshot[1] == 2 && fake.mStartRecordSnapshot[2] == 1;
}

(:test)
function failedInitialRecordDoesNotStartAndLeavesTheControllerRetryable(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    fake.mFailSetDataId = 3;
    fake.mFailSetDataValue = 1;
    var controller = new SessionController(fake);
    var rejected = controller.start(:ice);
    fake.mFailSetDataId = 0;
    return rejected == false && fake.mStartCalls == 0 && fake.mDiscardCalls == 1 &&
        controller.getState() == :idle && controller.start(:ice) && controller.getState() == :recording;
}

(:test)
function markerlessSessionStillKeepsInitialSchemaAndModeInTheFitRecord(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    var controller = new SessionController(fake);
    return controller.start(:ice) && controller.stop() && controller.save() &&
        fake.mCreatedFields[0].mValue == FitSchema.VERSION && fake.mCreatedFields[1].mValue == 1 &&
        fake.mCreatedFields[2].mValue == 1;
}

(:test)
function successfulLapCommitsTheMarkerEvenWhenRecordUpdateFails(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    fake.mFailSetDataId = 3;
    fake.mFailSetDataValue = 3;
    var controller = new SessionController(fake);
    return controller.start(:ice) && controller.markShift(:shift, 1000) &&
        fake.mLaps == 1 && fake.mCreatedFields[15].mValue == 1 &&
        fake.mCreatedFields[16].mValue == 3 && fake.mCreatedFields[17].mValue == 1000 &&
        fake.mCreatedFields[2].mValue == 1 && controller.stop() &&
        fake.mCreatedFields[25].mValue == 1;
}

(:test)
function discardedStoppedSessionUsesTheUnderlyingDiscard(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    var controller = new SessionController(fake);
    controller.start(:ice);
    controller.stop();
    return controller.discard() && controller.getState() == :discarded &&
        fake.mDiscardCalls == 1;
}

(:test)
function failedDiscardKeepsTheStoppedSessionRecoverable(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    fake.mDiscardResult = false;
    var controller = new SessionController(fake);
    controller.start(:ice);
    controller.stop();
    return controller.discard() == false && controller.getState() == :stopped &&
        fake.mDiscardCalls == 1;
}

(:test)
function missingCreateFieldCapabilityIsCleanedUpWithoutStartingRecording(logger as Test.Logger) as Lang.Boolean {
    var fake = new NoCreateFieldFitSession();
    var controller = new SessionController(fake);
    return controller.start(:ice) == false && controller.getState() == :idle &&
        fake.mStartCalls == 1 && fake.mStopCalls == 1 && fake.mDiscardCalls == 1;
}

(:test)
function partialFieldAllocationIsNotRetriedInTheSameSession(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    fake.mFailAtCreateCount = 4;
    var writer = new FitWriter(fake);
    var firstAttempt = writer.allocateFields();
    var countAfterFirstAttempt = fake.mCreateCount;
    var secondAttempt = writer.allocateFields();
    return firstAttempt == false && secondAttempt == false && writer.isInvalid() &&
        countAfterFirstAttempt == 4 && fake.mCreateCount == countAfterFirstAttempt;
}

(:test)
function firstFieldFailureInvalidatesThenRetriesOnlyWithAFreshSession(logger as Test.Logger) as Lang.Boolean {
    var factory = new FreshRetryFitFactory();
    var controller = new SessionController(factory);
    var firstStart = controller.start(:ice);
    var secondStart = controller.start(:ice);
    return firstStart == false && controller.getState() == :recording &&
        factory.mCreateSessionCalls == 2 &&
        factory.mFirstSession.mCreateCount == 1 &&
        factory.mFirstSession.mStartCalls == 1 &&
        factory.mFirstSession.mStopCalls == 1 &&
        factory.mFirstSession.mDiscardCalls == 1 &&
        factory.mSecondSession.mCreateCount == 34 && secondStart;
}

(:test)
function writerRejectsOutOfRangeUint8BeforeWritingAnyField(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    var writer = new FitWriter(fake);
    writer.allocateFields();
    return writer.writeRecord({:shiftConfidence=>256}) == false &&
        fake.mCreatedFields[4].mValue == null;
}

(:test)
function writerProtectsUint16AndTheSupportedUint32Range(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    var writer = new FitWriter(fake);
    writer.allocateFields();
    return writer.writeRecord({:movementIntensity=>65536}) == false &&
        writer.writeRecord({:estimatedDistanceCm=>2147483647}) &&
        writer.writeRecord({:estimatedDistanceCm=>-1}) == false &&
        fake.mCreatedFields[5].mValue == null && fake.mCreatedFields[8].mValue == 2147483647;
}

(:test)
function fieldCreationUsesTheSchemaFitTypesMessageTypesAndUnits(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    var writer = new FitWriter(fake);
    if (!writer.allocateFields()) {
        return false;
    }
    var fields = FitSchema.getFields();
    for (var index = 0; index < fake.mCreatedIds.size(); index += 1) {
        var definition = fields[fake.mCreatedIds[index] - 1];
        if (fake.mCreatedFields[definition[:id] - 1].mId != definition[:id] ||
            fake.mCreatedTypes[index] != FitSchema.typeFor(definition[:type]) ||
            fake.mCreatedOptions[index][:mesgType] != FitSchema.messageTypeFor(definition[:scope]) ||
            !fake.mCreatedOptions[index][:units].equals(definition[:unit])) {
            return false;
        }
    }
    return true;
}

(:test)
function liveSummaryMetricsAreWrittenIntoTheFitSessionSummary(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    var controller = new SessionController(fake);
    controller.start(:ice);
    var accepted = controller.setSummaryMetrics({:iceTimeMs=>4000, :benchTimeMs=>8000});
    return accepted && controller.stop() &&
        fake.mCreatedFields[26].mValue == 4000 && fake.mCreatedFields[27].mValue == 8000;
}

(:test)
function fitSummaryCountsOnlyRealShiftEntriesNotBothBoundaries(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    var controller = new SessionController(fake);
    controller.start(:ice);
    var bank = controller.markShift(:bench, 1000);
    var shift = controller.markShift(:shift, 2000);
    var returnToBank = controller.markShift(:bench, 3000);
    return bank && shift && returnToBank && controller.stop() &&
        fake.mCreatedFields[25].mValue == 1;
}

(:test)
function failedSaveCanRetryTheSameStoppedFitSession(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    fake.mSaveResult = false;
    var controller = new SessionController(fake);
    controller.start(:ice);
    controller.stop();
    var firstSave = controller.save();
    fake.mSaveResult = true;
    return firstSave == false && controller.getState() == :stopped &&
        controller.save() && controller.getState() == :saved;
}

(:test)
function failedSaveCanDiscardTheSameStoppedFitSession(logger as Test.Logger) as Lang.Boolean {
    var fake = new FakeFitSession();
    fake.mSaveResult = false;
    var controller = new SessionController(fake);
    controller.start(:ice);
    controller.stop();
    controller.save();
    return controller.discard() && controller.getState() == :discarded &&
        fake.mDiscardCalls == 1;
}
