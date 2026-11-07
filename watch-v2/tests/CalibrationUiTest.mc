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
function calibrationIntroUsesShortRoundSafeRows(logger as Test.Logger) as Lang.Boolean {
    var view = new CalibrationIntroView(new CalibrationTargetFake(), :ice);
    var dc = new ReadyDcFake();
    view.onUpdate(dc);
    var distance = false;
    var course = false;
    var without = false;
    var withStick = false;
    for (var i = 0; i < dc.texts.size(); i += 1) {
        if (dc.texts[i].equals("20.00 M")) { distance = true; }
        if (dc.texts[i].equals("STRAIGHT COURSE")) { course = true; }
        if (dc.texts[i].equals("5 WITHOUT STICK")) { without = true; }
        if (dc.texts[i].equals("5 WITH STICK")) { withStick = true; }
    }
    return distance && course && without && withStick;
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
    if (!new StartMenuView(training).selectAt(416 * 34 / 100, 416)) { return false; }
    var calibration = new CalibrationTargetFake();
    if (!new StartMenuView(calibration).selectAt(416 * 51 / 100, 416)) { return false; }
    var exit = new CalibrationTargetFake();
    if (!new StartMenuView(exit).selectAt(416 * 68 / 100, 416)) { return false; }
    return training.trainingRequests == 1 && calibration.menuRequests == 1 &&
        exit.exits == 1;
}

(:test)
function startMenuTouchIgnoresHintAndWhitespace(logger as Test.Logger) as Lang.Boolean {
    var target = new CalibrationTargetFake();
    var view = new StartMenuView(target);
    return !view.selectAt(416 * 10 / 100, 416) &&
        !view.selectAt(416 * 84 / 100, 416) &&
        !view.selectAt(416 * 98 / 100, 416) &&
        target.trainingRequests == 0 && target.menuRequests == 0 &&
        target.exits == 0;
}

(:test)
function menuHintsUseTwoShortReadableLines(logger as Test.Logger) as Lang.Boolean {
    var menuDc = new ReadyDcFake();
    new StartMenuView(new CalibrationTargetFake()).onUpdate(menuDc);
    var sportDc = new ReadyDcFake();
    new SportSelectionView(new CalibrationTargetFake(), :training, :ice).onUpdate(sportDc);
    var menuLower = false;
    var menuUpper = false;
    var sportLower = false;
    var sportUpper = false;
    for (var i = 0; i < menuDc.texts.size(); i += 1) {
        if (menuDc.texts[i].equals("LOWER: CYCLE")) { menuLower = true; }
        if (menuDc.texts[i].equals("UPPER: SELECT")) { menuUpper = true; }
    }
    for (var j = 0; j < sportDc.texts.size(); j += 1) {
        if (sportDc.texts[j].equals("LOWER: CYCLE")) { sportLower = true; }
        if (sportDc.texts[j].equals("UPPER: SELECT")) { sportUpper = true; }
    }
    return menuLower && menuUpper && sportLower && sportUpper;
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
    if (!view.selectAt(416 * 61 / 100, 416)) { return false; }
    if (target.sportConfirms != 1 || target.confirmedPurpose != :calibration ||
        target.confirmedSport != :inline) { return false; }
    var invalid = new SportSelectionView(target, :run, :hockey);
    invalid.cycleSelection();
    invalid.confirmSelection();
    invalid.selectAt(100, 416);
    return invalid.selection() == null && target.sportConfirms == 1;
}

(:test)
function sportSelectorTouchIgnoresTitleHintAndWhitespace(logger as Test.Logger) as Lang.Boolean {
    var target = new CalibrationTargetFake();
    var view = new SportSelectionView(target, :training, :ice);
    return !view.selectAt(416 * 22 / 100, 416) &&
        !view.selectAt(416 * 52 / 100, 416) &&
        !view.selectAt(416 * 82 / 100, 416) &&
        target.sportConfirms == 0 && view.selection() == :ice;
}

(:test)
function calibrationTouchBandsMatchVisibleActionsAcrossTouchSizes(logger as Test.Logger) as Lang.Boolean {
    var sizes = [360, 390, 416, 454];
    for (var i = 0; i < sizes.size(); i += 1) {
        var height = sizes[i];
        var menu = new StartMenuView(new CalibrationTargetFake());
        if (menu.selectAt(height * 26 / 100 - 1, height) ||
            !menu.selectAt(height * 26 / 100, height) ||
            menu.selectAt(height * 42 / 100 + 1, height) ||
            !menu.selectAt(height * 51 / 100, height) ||
            !menu.selectAt(height * 68 / 100, height) ||
            menu.selectAt(height * 76 / 100 + 1, height)) { return false; }

        var sport = new SportSelectionView(new CalibrationTargetFake(), :training, :ice);
        if (sport.selectAt(height * 35 / 100 - 1, height) ||
            !sport.selectAt(height * 43 / 100, height) ||
            sport.selectAt(height * 51 / 100, height) ||
            !sport.selectAt(height * 61 / 100, height) ||
            sport.selectAt(height * 69 / 100 + 1, height)) { return false; }

        var summaryTarget = new CalibrationTargetFake();
        var summary = new CalibrationSummaryView(summaryTarget,
            calibrationProfileCandidate(:ice, 1.0));
        if (summary.confirmTouch(height * 69 / 100 - 1, height) ||
            !summary.confirmTouch(height * 74 / 100, height) ||
            summaryTarget.activations != 1 ||
            !summary.confirmTouch(height * 84 / 100, height) ||
            summaryTarget.discardConfirmations != 1 ||
            summary.confirmTouch(height * 90 / 100 + 1, height)) { return false; }
    }
    return true;
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
    var screenHeight = Toybox.System.getDeviceSettings().screenHeight;
    var target = new CalibrationTargetFake();
    var candidate = calibrationProfileCandidate(:ice, 1.0);
    var view = new CalibrationSummaryView(target, candidate);
    var delegate = new CalibrationSummaryInputDelegate(view);
    if (!delegate.onTap(new CalibrationSummaryTapEventFake(screenHeight * 84 / 100)) ||
        target.discardConfirmations != 1 || target.activations != 0) { return false; }

    target = new CalibrationTargetFake();
    view = new CalibrationSummaryView(target, candidate);
    delegate = new CalibrationSummaryInputDelegate(view);
    return delegate.onTap(new CalibrationSummaryTapEventFake(screenHeight * 74 / 100)) &&
        target.activations == 1 && target.discardConfirmations == 0;
}

(:test)
function calibrationReviewTouchOutsideOptionsDoesNothing(logger as Test.Logger) as Lang.Boolean {
    var target = new CalibrationTargetFake();
    var view = new CalibrationSummaryView(target, calibrationProfileCandidate(:ice, 1.0));
    var delegate = new CalibrationSummaryInputDelegate(view);
    return !delegate.onTap(new CalibrationSummaryTapEventFake(
        Toybox.System.getDeviceSettings().screenHeight * 28 / 100)) &&
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
function calibrationRunUsesSeparateStatusAndActionRows(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    if (!controller.configure(:ice)) { return false; }
    var view = new CalibrationRunView(new CalibrationTargetFake(), controller);
    var dc = new ReadyDcFake();
    view.onUpdate(dc);
    var ready = false;
    var lower = false;
    var upper = false;
    for (var i = 0; i < dc.texts.size(); i += 1) {
        if (dc.texts[i].equals("READY")) { ready = true; }
        if (dc.texts[i].equals("LOWER: START")) { lower = true; }
        if (dc.texts[i].equals("UPPER: CANCEL")) { upper = true; }
    }
    return ready && lower && upper;
}

(:test)
function calibrationSummaryUsesShortRoundSafeTitle(logger as Test.Logger) as Lang.Boolean {
    var view = new CalibrationSummaryView(new CalibrationTargetFake(),
        calibrationProfileCandidate(:ice, 1.0));
    var dc = new ReadyDcFake();
    view.onUpdate(dc);
    for (var i = 0; i < dc.texts.size(); i += 1) {
        if (dc.texts[i].equals("REVIEW")) { return true; }
    }
    return false;
}

(:test)
function acceptedCalibrationRunKeepsCompletedPromptUntilAcknowledged(logger as Test.Logger) as Lang.Boolean {
    var controller = new CalibrationController();
    if (!controller.configure(:ice)) { return false; }
    var coordinator = new CalibrationCoordinatorFake();
    coordinator.lastShiftDistanceCm = 2000;
    var view = new CalibrationRunView(new CalibrationTargetFake(), controller);
    view.setCoordinator(coordinator);
    for (var i = 0; i < 10; i += 1) {
        var start = 1000 + i * 40000;
        if (!view.toggleMarker(start) || !view.toggleMarker(start + 10000)) {
            return false;
        }
        var completed = view.prompt();
        var expectedCondition = i < 5 ? :skate_only : :puck_stickhandling;
        var expectedIndex = (i % 5) + 1;
        if (completed[:condition] != expectedCondition ||
            completed[:withinConditionIndex] != expectedIndex ||
            completed[:pace] != CalibrationTypes.paceForIndex(i % 5)) {
            return false;
        }
        if (i < 9) {
            if (!view.toggleMarker(start + 11000)) { return false; }
            if (i == 4) {
                var nextCondition = view.prompt();
                if (nextCondition[:condition] != :puck_stickhandling ||
                    nextCondition[:withinConditionIndex] != 1 ||
                    nextCondition[:pace] != :slow) { return false; }
            }
        }
    }
    var finalPrompt = view.prompt();
    return view.getState() == :complete &&
        finalPrompt[:condition] == :puck_stickhandling &&
        finalPrompt[:withinConditionIndex] == 5 && finalPrompt[:pace] == :fast;
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
