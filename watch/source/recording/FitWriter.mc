using Toybox;
using Toybox.Lang;
using Toybox.System;

class FitWriter {
    // Venu 2 Plus raises an uncatchable system error when a session attempts
    // to create more than the already validated 34 contributor fields.
    public static const MAX_ALLOCATED_FIELDS = 34;
    hidden var mSession = null;
    hidden var mFields = {};
    hidden var mAllocated = false;
    hidden var mInvalid = false;
    hidden var mFailedFieldId = 0;
    hidden var mDegraded = false;
    public function getFailedFieldId() { return mFailedFieldId; }
    public function isDegraded() { return mDegraded; }
    // Garmin fields retain the value prepared for the next message. Keeping
    // the last confirmed value lets a failed addLap restore its pending lap
    // state instead of leaking an uncommitted marker into a later lap.
    hidden var mFieldValues = {};

    public function initialize(session) {
        mSession = session;
    }

    public function allocateFields() as Lang.Boolean {
        if (mAllocated) {
            return true;
        }
        if (mInvalid || mSession == null || !(mSession has :createField) ||
            !(Toybox has :FitContributor)) {
            invalidate();
            return false;
        }
        if (!FitSchema.hasOnlyUniqueIds() ||
            !FitSchema.usesStableIdRange(1, 42) ||
            FitSchema.getRecordPayloadBytes() > FitSchema.MAX_RECORD_PAYLOAD_BYTES) {
            invalidate();
            return false;
        }

        var definitions = FitSchema.getFields();
        // Reserve the fields required to recover a playable session first.
        // Never reuse an ID when an optional analytics field is unavailable.
        for (var pass = 0; pass < 2; pass += 1) {
            for (var index = 0; index < definitions.size(); index += 1) {
                var definition = definitions[index];
                if (definition[:id] > MAX_ALLOCATED_FIELDS) { continue; }
                var core = FitSchema.isCore(definition[:id]);
                if (core != (pass == 0)) { continue; }
                var field = null;
                try {
                    field = mSession.createField(definition[:name], definition[:id],
                        FitSchema.typeFor(definition[:type]),
                        {:mesgType=>FitSchema.messageTypeFor(definition[:scope]), :units=>definition[:unit]});
                } catch (ex) {
                    System.println("ShiftSense field=" + definition[:id] + " " + ex.getErrorMessage());
                }
                if (field == null) {
                    mFailedFieldId = definition[:id];
                    if (core) { invalidate(); return false; }
                    mDegraded = true;
                    System.println("ShiftSense optional fields unavailable from ID " + mFailedFieldId);
                    break;
                }
                mFields[definition[:id]] = field;
                mFieldValues[definition[:id]] = 0;
            }
        }
        mAllocated = true;
        return true;
    }

    public function isInvalid() as Lang.Boolean {
        return mInvalid;
    }

    public function writeRecord(sample as Lang.Dictionary) as Lang.Boolean {
        return writeScope(:record, sample, false);
    }

    public function writeShift(shift as Lang.Dictionary) as Lang.Boolean {
        return writeScope(:lap, shift, true);
    }

    public function writeSummary(summary as Lang.Dictionary) as Lang.Boolean {
        return writeScope(:session, summary, false);
    }

    private function writeScope(scope as Lang.Symbol, values as Lang.Dictionary, addLap as Lang.Boolean) as Lang.Boolean {
        if (mInvalid || !mAllocated || mSession == null) {
            return false;
        }
        var changed = [];
        try {
            var definitions = FitSchema.getFields();
            for (var validationIndex = 0; validationIndex < definitions.size(); validationIndex += 1) {
                var validationDefinition = definitions[validationIndex];
                if (validationDefinition[:scope] == scope &&
                    values.hasKey(validationDefinition[:key]) &&
                    !FitSchema.valueIsInRange(validationDefinition, values[validationDefinition[:key]])) {
                    return false;
                }
            }
            for (var index = 0; index < definitions.size(); index += 1) {
                var definition = definitions[index];
                if (definition[:scope] == scope && values.hasKey(definition[:key]) && mFields.hasKey(definition[:id])) {
                    changed.add({:id=>definition[:id], :previous=>mFieldValues[definition[:id]]});
                    mFields[definition[:id]].setData(values[definition[:key]]);
                    mFieldValues[definition[:id]] = values[definition[:key]];
                }
            }
            if (addLap) {
                if (!mSession.addLap()) {
                    restorePendingValues(changed);
                    return false;
                }
            }
        } catch (ex) {
            if (addLap) {
                restorePendingValues(changed);
            }
            return false;
        }
        return true;
    }

    private function restorePendingValues(changed as Lang.Array) as Void {
        for (var index = changed.size() - 1; index >= 0; index -= 1) {
            var change = changed[index];
            try {
                mFields[change[:id]].setData(change[:previous]);
                mFieldValues[change[:id]] = change[:previous];
            } catch (ex) {
            }
        }
    }

    private function invalidate() as Void {
        mAllocated = false;
        mInvalid = true;
        mFields = {};
        mFieldValues = {};
        mSession = null;
    }
}
