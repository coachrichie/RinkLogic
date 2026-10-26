using Toybox.Lang;
using Toybox.Test as Test;
using Toybox.WatchUi;

class CalibrationTargetFake {
    var starts = 0;
    var cancels = 0;
    var saves = 0;
    var reviews = 0;
    var activations = 0;
    var discards = 0;
    var exits = 0;
    var menuRequests = 0;
    var trainingRequests = 0;
    var sportConfirms = 0;
    var cancelConfirmations = 0;
    var discardConfirmations = 0;
    var confirmedPurpose = null;
    var confirmedSport = null;
    var last = null;
    function startCalibration(sport) as Void {
        starts += 1;
        last = {:sport=>sport, :distanceCm=>2000};
    }
    function confirmCancelCalibration() as Void { cancelConfirmations += 1; }
    function confirmDiscardCalibration() as Void { discardConfirmations += 1; }
    function cancelCalibration() as Void { cancels += 1; }
    function saveCalibration() as Void { saves += 1; }
    function reviewCalibration(candidate) as Void { reviews += 1; last = candidate; }
    function activateAndSaveCalibration() as Void { activations += 1; }
    function discardCalibration() as Void { discards += 1; }
    function exitApp() as Void { exits += 1; }
    function requestCalibration() as Void { menuRequests += 1; }
    function requestTraining() as Void { trainingRequests += 1; }
    function confirmSport(purpose, sport) as Void {
        sportConfirms += 1;
        confirmedPurpose = purpose;
        confirmedSport = sport;
    }
}

class CalibrationCoordinatorFake {
    var toggles = 0;
    var lastShiftPushes = 8;
    var lastShiftDistanceCm = 2500;
    var coveragePercent = 90;
    var timebase = :measured;
    function toggleShift() as Lang.Boolean { toggles += 1; return true; }
    function getDashboard() as Lang.Dictionary {
        return {:onIce=>false, :lastShiftPushes=>lastShiftPushes,
            :lastShiftDistanceCm=>lastShiftDistanceCm,
            :coveragePercent=>coveragePercent, :timebase=>timebase};
    }
}

class CalibrationSummaryTapEventFake extends WatchUi.ClickEvent {
    private var mTapY;
    function initialize(y) { mTapY = y; }
    function getCoordinates() {
        var settings = Toybox.System.getDeviceSettings();
        return [settings.screenWidth / 2, mTapY];
    }
}

(:test)
function calibrationIntroShowsFixedProtocolAndSelectedSport(logger as Test.Logger) as Lang.Boolean {
    var target = new CalibrationTargetFake();
    var view = new CalibrationIntroView(target, :inline);
    var dc = new ReadyDcFake();
    view.onUpdate(dc);
    var text = dc.texts.toString();
    return view.sport() == :inline && text.find("20.00 M") != null &&
        text.find("INLINE") != null && text.find("5 WITHOUT STICK") != null;
}

(:test)
function calibrationIntroLowerStartsAndUpperGuardsCancellation(logger as Test.Logger) as Lang.Boolean {
    var target = new CalibrationTargetFake();
    var view = new CalibrationIntroView(target, :ice);
    var delegate = new CalibrationIntroInputDelegate(view);
    return delegate.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ESC)) &&
        target.starts == 1 && target.last[:distanceCm] == 2000 &&
        delegate.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ENTER)) &&
        target.cancelConfirmations == 1;
}

(:test)
function startMenuDefaultsToTrainingLowerCyclesAndUpperConfirms(logger as Test.Logger) as Lang.Boolean {
    var target = new CalibrationTargetFake();
    var menu = new StartMenuView(target);
    var delegate = new StartMenuInputDelegate(menu);
    if (menu.selection() != :training ||
        !delegate.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ESC)) ||
        menu.selection() != :calibration ||
        !delegate.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ESC)) ||
        menu.selection() != :exit ||
        !delegate.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ENTER))) { return false; }
    return target.exits == 1 && target.menuRequests == 0 &&
        target.trainingRequests == 0;
}

(:test)
function startMenuTouchSelectsAllThreeEntriesDirectly(logger as Test.Logger) as Lang.Boolean {
    var training = new CalibrationTargetFake();
    new StartMenuView(training).selectAt(100, 416);
    var calibration = new CalibrationTargetFake();
    new StartMenuView(calibration).selectAt(210, 416);
    var exit = new CalibrationTargetFake();
    new StartMenuView(exit).selectAt(330, 416);
    return training.trainingRequests == 1 && calibration.menuRequests == 1 &&
        exit.exits == 1;
}

(:test)
function sportSelectorUsesRememberedSportAndSemanticButtons(logger as Test.Logger) as Lang.Boolean {
    var target = new CalibrationTargetFake();
    var view = new SportSelectionView(target, :training, :inline);
    var delegate = new SportSelectionInputDelegate(view);
    if (view.selection() != :inline ||
        !delegate.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ESC)) ||
        view.selection() != :ice ||
        !delegate.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ENTER))) { return false; }
    return target.sportConfirms == 1 && target.confirmedPurpose == :training &&
        target.confirmedSport == :ice;
}

(:test)
function sportSelectorTouchSelectsAndInvalidInputsDoNothing(logger as Test.Logger) as Lang.Boolean {
    var target = new CalibrationTargetFake();
    var view = new SportSelectionView(target, :calibration, :ice);
    view.selectAt(300, 416);
    if (target.sportConfirms != 1 || target.confirmedPurpose != :calibration ||
        target.confirmedSport != :inline) { return false; }
    var invalid = new SportSelectionView(target, :run, :hockey);
    invalid.cycleSelection();
    invalid.confirmSelection();
    invalid.selectAt(100, 416);
    return invalid.selection() == null && target.sportConfirms == 1;
}

(:test)
function runViewUsesLowerMarkerForStartAndEndStates(logger as Test.Logger) as Lang.Boolean {
    var target = new CalibrationTargetFake();
    var controller = new CalibrationController();
    controller.configureLegacy(:inline, :skate_only, 2000, 5);
    var view = new CalibrationRunView(target, controller);
    if (view.getState() != :ready) { return false; }
    if (!view.toggleMarker(1000) || view.getState() != :running) { return false; }
    if (!view.toggleMarker(4000) || view.getState() != :retry) { return false; }
    view.requestCancel();
    return target.cancelConfirmations == 1;
}

(:test)
function runViewForwardsMarkersToLiveCoordinator(logger as Test.Logger) as Lang.Boolean {
    var target = new CalibrationTargetFake();
    var controller = new CalibrationController();
    controller.configureLegacy(:inline, :skate_only, 2000, 5);
    var coordinator = new CalibrationCoordinatorFake();
    var view = new CalibrationRunView(target, controller);
    view.setCoordinator(coordinator);
    if (!view.toggleMarker(1000) || !view.toggleMarker(4000)) { return false; }
    return coordinator.toggles == 2 && controller.validCount() == 1;
}

(:test)
function runViewUpperActionCancelsCalibration(logger as Test.Logger) as Lang.Boolean {
    var target = new CalibrationTargetFake();
    var controller = new CalibrationController();
    controller.configureLegacy(:inline, :skate_only, 2000, 5);
    var view = new CalibrationRunView(target, controller);
    view.requestCancel();
    return target.cancelConfirmations == 1;
}

(:test)
function runViewRendersConditionPaceDurationAndHonestUpperAction(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    controller.configure(:ice);
    var view = new CalibrationRunView(new CalibrationTargetFake(), controller);
    view.setCoordinator(new CalibrationCoordinatorFake());
    if (!view.toggleMarker(1000) || !view.toggleMarker(11000)) { return false; }
    var dc = new ReadyDcFake();
    view.onUpdate(dc);
    var joined = dc.texts.toString();
    if (joined.find("WITHOUT STICK") == null || joined.find("SLOW") == null ||
        joined.find("0.17 MIN") == null || joined.find("UPPER: CANCEL") == null ||
        joined.find("UPPER: SAVE") != null) { return false; }
    if (!view.nextRepetition()) { return false; }
    return view.prompt()[:pace] == :fast;
}

(:test)
function calibrationReviewOffersExplicitActivateAndDiscard(logger as Test.Logger) as Lang.Boolean {
    var target = new CalibrationTargetFake();
    var candidate = calibrationProfileCandidate(:ice, 1.0);
    var view = new CalibrationSummaryView(target, candidate);
    var delegate = new CalibrationSummaryInputDelegate(view);
    if (!delegate.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ENTER)) ||
        target.activations != 1) { return false; }
    return delegate.onKey(new PhysicalKeyEventFake(WatchUi.KEY_ESC)) &&
        target.discardConfirmations == 1;
}

(:test)
function calibrationReviewTouchExecutesTouchedOption(logger as Test.Logger) as Lang.Boolean {
    var target = new CalibrationTargetFake();
    var candidate = calibrationProfileCandidate(:ice, 1.0);
    var view = new CalibrationSummaryView(target, candidate);
    var delegate = new CalibrationSummaryInputDelegate(view);
    if (!delegate.onTap(new CalibrationSummaryTapEventFake(265)) ||
        target.discardConfirmations != 1 || target.activations != 0) { return false; }

    target = new CalibrationTargetFake();
    view = new CalibrationSummaryView(target, candidate);
    delegate = new CalibrationSummaryInputDelegate(view);
    return delegate.onTap(new CalibrationSummaryTapEventFake(220)) &&
        target.activations == 1 && target.discardConfirmations == 0;
}

(:test)
function calibrationReviewTouchOutsideOptionsDoesNothing(logger as Test.Logger) as Lang.Boolean {
    var target = new CalibrationTargetFake();
    var view = new CalibrationSummaryView(target, calibrationProfileCandidate(:ice, 1.0));
    var delegate = new CalibrationSummaryInputDelegate(view);
    return !delegate.onTap(new CalibrationSummaryTapEventFake(120)) &&
        target.activations == 0 && target.discards == 0;
}

(:test)
function calibrationRunExposesConditionPaceAndMinuteDuration(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    controller.configure(:ice);
    var view = new CalibrationRunView(new CalibrationTargetFake(), controller);
    if (view.prompt()[:condition] != :skate_only || view.prompt()[:pace] != :slow ||
        !view.toggleMarker(1000) || !view.toggleMarker(11000)) { return false; }
    return view.prompt()[:durationMinutes] > 0.1666 &&
        view.prompt()[:durationMinutes] < 0.1667;
}

(:test)
function missingMotionStillCompletesMarkerPairAndAdvances(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    controller.configureLegacy(:inline, :skate_only, 2000, 5);
    var coordinator = new CalibrationCoordinatorFake();
    coordinator.lastShiftPushes = null;
    coordinator.lastShiftDistanceCm = null;
    coordinator.coveragePercent = 0;
    var view = new CalibrationRunView(new CalibrationTargetFake(), controller);
    view.setCoordinator(coordinator);
    if (!view.toggleMarker(1000) || !view.toggleMarker(11000)) { return false; }
    if (view.getState() != :retry || controller.invalidCount() != 1 ||
        controller.validCount() != 0) { return false; }
    if (!view.toggleMarker(12000)) { return false; }
    if (view.getState() != :ready || coordinator.toggles != 2) { return false; }
    return view.toggleMarker(13000) && view.getState() == :running &&
        coordinator.toggles == 3;
}

(:test)
function calibrationRunOnlyOffersReviewAfterTenAcceptedRuns(logger as Test.Logger) as Lang.Boolean {
    var target = new CalibrationTargetFake();
    var controller = new CalibrationController();
    if (!controller.configure(:ice)) { return false; }
    var coordinator = new CalibrationCoordinatorFake();
    coordinator.lastShiftDistanceCm = 2000;
    var view = new CalibrationRunView(target, controller);
    view.setCoordinator(coordinator);
    for (var i = 0; i < 10; i += 1) {
        var start = 1000 + i * 40000;
        if (!view.toggleMarker(start) || !view.toggleMarker(start + 10000)) { return false; }
        if (i < 9 && !view.toggleMarker(start + 11000)) { return false; }
    }
    if (view.getState() != :complete || target.reviews != 0) { return false; }
    view.requestUpperAction();
    return target.reviews == 1 && target.cancelConfirmations == 0;
}
