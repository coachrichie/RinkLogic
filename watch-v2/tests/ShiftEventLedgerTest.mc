using Toybox.Lang;
using Toybox.Test as Test;

(:test)
function manualTimelineIgnoresNearbyAutoProposal(logger as Test.Logger) as Lang.Boolean {
    var ledger = new ShiftEventLedger();
    var first = ledger.manualToggle(1000);
    ledger.noteProposal({:atMs=>1100, :state=>:on_ice,
        :source=>:auto, :confidence=>90, :reason=>:sustained_motion});
    var middle = ledger.snapshot(6000);
    ledger.manualToggle(11000);
    var ended = ledger.snapshot(11000);
    return first[:state] == :on_ice && middle[:shiftCount] == 1 &&
        middle[:timeOnIceMs] == 5000 && ended[:shiftCount] == 1 &&
        ended[:lastShiftMs] == 10000 && !ended[:onIce];
}

(:test)
function closingOpenManualShiftFreezesIceTime(logger as Test.Logger) as Lang.Boolean {
    var ledger = new ShiftEventLedger();
    ledger.manualToggle(1000);
    ledger.close(6000);
    return ledger.snapshot(16000)[:timeOnIceMs] == 5000 &&
        ledger.snapshot(16000)[:shiftCount] == 1;
}
