using Toybox.Application.Storage;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class ProfileView extends WatchUi.View {
    private var mProfile = null;
    private var mController = null;
    private var mSelection = 0;
    private var mEditing = false;
    private var mRound = new RoundLayout();

    public function initialize(profile, controller) {
        View.initialize();
        mProfile = profile;
        mController = controller;
    }

    public function continueToMode() as Void {
        if (mProfile.validate().size() != 0) {
            return;
        }
        Storage.setValue(PlayerProfile.STORAGE_KEY, mProfile.serialize());
        var mode = new ModeView(mController);
        mode.setPlayerProfile(mProfile);
        WatchUi.pushView(mode, new ModeInputDelegate(mode), WatchUi.SLIDE_LEFT);
    }

    public function adjustAge(delta as Lang.Number) as Void {
        var changed = mProfile.withAge(mProfile.getAge() + delta);
        if (changed.validate().size() == 0) {
            mProfile = changed;
            WatchUi.requestUpdate();
        }
    }

    public function getProfile() as PlayerProfile { return mProfile; }

    public function toggleEditableField() as Void {
        if (mEditing) {
            mSelection = (mSelection + 1) % 2;
        } else {
            if (mSelection == 2) { mSelection = 0; }
            mEditing = true;
        }
        WatchUi.requestUpdate();
    }

    public function moveSelection(delta as Lang.Number) as Void {
        if (mEditing) { adjustCurrentField(delta); return; }
        mSelection = (mSelection + delta + 3) % 3;
        WatchUi.requestUpdate();
    }

    public function adjustCurrentField(delta as Lang.Number) as Void {
        if (!mEditing || mSelection == 2) { return; }
        if (mSelection == 0) {
            adjustAge(delta);
            return;
        }
        var current = mProfile.getTestedHrMax();
        var base = current == null ? mProfile.resolveHrMax() : current;
        var changed = mProfile.withTestedHrMax(base + delta);
        if (changed.validate().size() == 0) {
            mProfile = changed;
            WatchUi.requestUpdate();
        }
    }

    public function activateSelection() as Void {
        if (mEditing) { mEditing = false; WatchUi.requestUpdate(); return; }
        if (mSelection == 2) { continueToMode(); }
        else { toggleEditableField(); }
    }

    public function clearTestedHrMax() as Void {
        mProfile = mProfile.withTestedHrMax(null);
        WatchUi.requestUpdate();
    }
    public function resetSelectedField() as Lang.Boolean {
        if (mSelection != 1) { return false; }
        clearTestedHrMax();
        return true;
    }

    public function handleTap(point) as Lang.Boolean {
        if (mRound.contains(point, 15, 25, 85, 37)) { mSelection = 0; }
        else if (mRound.contains(point, 15, 40, 85, 52)) { mSelection = 1; }
        else if (mRound.contains(point, 15, 56, 35, 68)) { mEditing = true; adjustCurrentField(-1); }
        else if (mRound.contains(point, 65, 56, 85, 68)) { mEditing = true; adjustCurrentField(1); }
        else if (mSelection == 1 && mRound.contains(point, 37, 56, 63, 68)) { clearTestedHrMax(); }
        else if (mRound.contains(point, 25, 73, 75, 83)) { continueToMode(); }
        else { return false; }
        WatchUi.requestUpdate();
        return true;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        mRound.background(dc);
        mRound.text(dc, UiText.get(Rez.Strings.ProfileTitle), 50, 14, 62, false);
        mRound.button(dc, UiText.get(Rez.Strings.ProfileAge) + ": " + mProfile.getAge(), 15, 25, 85, 37, mSelection == 0);
        mRound.button(dc, UiText.get(Rez.Strings.ProfileHrMax) + ": " + mProfile.resolveHrMax() + " (" + hrSourceLabel() + ")", 15, 40, 85, 52, mSelection == 1);
        mRound.button(dc, "-", 15, 56, 35, 68, false);
        mRound.button(dc, "+", 65, 56, 85, 68, false);
        if (mSelection == 1) { mRound.button(dc, UiText.get(Rez.Strings.Automatic), 37, 56, 63, 68, false); }
        mRound.button(dc, UiText.get(Rez.Strings.Continue), 25, 73, 75, 83, mSelection == 2);
        mRound.text(dc, UiText.get(mSelection == 1 ? Rez.Strings.ProfileHintTested : Rez.Strings.ProfileHint), 50, 89, 50, false);
    }

    private function hrSourceLabel() as Lang.String {
        var source = mProfile.getHrMaxSource();
        if (source == :tested) { return UiText.get(Rez.Strings.ProfileHrSourceTested); }
        if (source == :garmin) { return UiText.get(Rez.Strings.ProfileHrSourceGarmin); }
        return UiText.get(Rez.Strings.ProfileHrSourceAge);
    }
}

class ProfileInputDelegate extends WatchUi.BehaviorDelegate {
    private var mView = null;

    public function initialize(view) {
        BehaviorDelegate.initialize();
        mView = view;
    }

    public function onSelect() as Lang.Boolean {
        mView.activateSelection();
        return true;
    }

    public function onTap(clickEvent) as Lang.Boolean {
        return mView.handleTap(clickEvent.getCoordinates());
    }

    public function onNextMode() as Lang.Boolean {
        mView.moveSelection(1);
        return true;
    }

    public function onPreviousMode() as Lang.Boolean {
        mView.moveSelection(-1);
        return true;
    }

    public function onKey(keyEvent) as Lang.Boolean {
        if (keyEvent.getKey() == WatchUi.KEY_DOWN) {
            mView.moveSelection(1);
            return true;
        }
        if (keyEvent.getKey() == WatchUi.KEY_UP) {
            mView.moveSelection(-1);
            return true;
        }
        return false;
    }

    public function onNextPage() as Lang.Boolean { return onNextMode(); }
    public function onPreviousPage() as Lang.Boolean { return onPreviousMode(); }
    public function onMenu() as Lang.Boolean { mView.toggleEditableField(); return true; }
    public function onHold(clickEvent) as Lang.Boolean { return mView.resetSelectedField(); }
    public function onBack() as Lang.Boolean { return mView.resetSelectedField(); }
}
