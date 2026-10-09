using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;

class ErrorView extends WatchUi.View {
    private var mCode;
    private var mCoordinator;
    function initialize(code, coordinator) { View.initialize(); mCode = code; mCoordinator = coordinator; }
    function retryFinish() as Lang.Boolean {
        if (mCoordinator == null) { return false; }
        var state = mCoordinator.getState();
        var completed = false;
        if (state == :recording) { completed = mCoordinator.stopAndSave(); }
        else if (state == :stopped) { completed = mCoordinator.retrySave(); }
        if (!completed) { mCode = mCoordinator.getErrorCode(); WatchUi.requestUpdate(); return false; }
        var summaryView = new SessionSummaryView(mCoordinator.getSessionSummary());
        WatchUi.switchToView(summaryView, new SessionSummaryInputDelegate(summaryView),
            WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
    function requestDiscard() as Lang.Boolean {
        if (mCoordinator == null || !mCoordinator.hasPendingSession()) { return false; }
        WatchUi.pushView(new WatchUi.Confirmation(
            WatchUi.loadResource(Rez.Strings.ConfirmDiscard)),
            new DiscardConfirmationDelegate(self), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
    function discardConfirmed() as Lang.Boolean {
        if (mCoordinator == null || !mCoordinator.discardSession()) {
            mCode = mCoordinator == null ? "REC_DISCARD" : mCoordinator.getErrorCode();
            WatchUi.requestUpdate();
            return false;
        }
        WatchUi.switchToView(new SavedView(Rez.Strings.Discarded),
            new SavedInputDelegate(), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()*42/100, Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.RecordingFailed), Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()*55/100, Graphics.FONT_XTINY,
            mCode == null ? "UNKNOWN" : mCode, Graphics.TEXT_JUSTIFY_CENTER);
        if (mCoordinator != null && (mCoordinator.getState() == :stopped ||
            mCoordinator.getState() == :recording)) {
            dc.drawText(dc.getWidth()/2, dc.getHeight()*70/100, Graphics.FONT_XTINY,
                WatchUi.loadResource(Rez.Strings.RetryFinish), Graphics.TEXT_JUSTIFY_CENTER);
        }
        if (mCoordinator != null && mCoordinator.hasPendingSession()) {
            dc.drawText(dc.getWidth()/2, dc.getHeight()*80/100, Graphics.FONT_XTINY,
                WatchUi.loadResource(Rez.Strings.DiscardHint), Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}

class ErrorInputDelegate extends WatchUi.BehaviorDelegate {
    private var mView;
    function initialize(view) { BehaviorDelegate.initialize(); mView = view; }
    function onSelect() as Lang.Boolean { return mView.retryFinish(); }
    function onBack() as Lang.Boolean {
        if (!mView.requestDiscard()) { System.exit(); }
        return true;
    }
}

class DiscardConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    private var mView;
    function initialize(view) { ConfirmationDelegate.initialize(); mView = view; }
    function onResponse(response) as Lang.Boolean {
        if (response == WatchUi.CONFIRM_YES) { mView.discardConfirmed(); }
        return true;
    }
}
