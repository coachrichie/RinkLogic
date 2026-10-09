using Toybox.Application;
using Toybox.Application.Storage;
using Toybox.Lang;
using Toybox.WatchUi;

class ShiftSenseApp extends Application.AppBase {
    public static const APP_NAME = "ShiftSense Hockey";

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var profile = PlayerProfile.deserialize(Storage.getValue(PlayerProfile.STORAGE_KEY));
        if (profile == null) {
            profile = PlayerProfile.defaultProfile();
        }
        var garminHrMax = GarminProfileAdapter.readHrMax();
        if (garminHrMax != null) {
            profile = profile.withGarminHrMax(garminHrMax);
        }
        profile = profile.withGarminSnapshot(GarminProfileAdapter.readProfile());
        var view = new ProfileView(profile, new SessionController(new FitSessionFactory()));
        return [view, new ProfileInputDelegate(view)];
    }
}
