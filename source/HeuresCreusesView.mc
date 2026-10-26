import Toybox.Graphics;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Timer;

class HeuresCreusesView extends WatchUi.View {
    // Shortest timer interval: the screen opens right after onSelect returns, as the menu closes.
    const ACTION_DELAY_MS = 50;

    var settings as Settings;
    var pendingAction as Symbol or Null;
    var actionTimer as Timer.Timer or Null;

    function initialize() {
        View.initialize();
        settings = new Settings();
        pendingAction = null;
        actionTimer = null;
        // System hint showing how to open the action menu on this product.
        if (View has :setActionMenuIndicator) {
            setActionMenuIndicator({:enabled => true});
        }
    }

    // View operations are not allowed from an ActionMenu, so the selected entry
    // is opened once the menu has closed.
    function queueAction(action as Symbol) as Void {
        pendingAction = action;
        if (actionTimer != null) {
            actionTimer.stop();
        }
        actionTimer = new Timer.Timer();
        actionTimer.start(method(:runPendingAction), ACTION_DELAY_MS, false);
    }

    function runPendingAction() as Void {
        actionTimer = null;
        var action = pendingAction;
        pendingAction = null;
        if (action == :settings) {
            openSettings();
        } else if (action == :credits) {
            openCredits();
        }
    }

    function onShow() as Void {
    }

    // Period in progress, or the next one to start; null when none is configured.
    function relevantPeriod(periods as Array<Array<Number>>, nowMinutes as Number) as Array<Number> or Null {
        var best = null;
        var bestDelay = 24 * 60 + 1;
        for (var index = 0; index < periods.size(); index += 1) {
            if (settings.isPeriodActive(periods[index], nowMinutes)) {
                return periods[index];
            }
            var delay = (periods[index][0] - nowMinutes + 24 * 60) % (24 * 60);
            if (delay < bestDelay) {
                bestDelay = delay;
                best = periods[index];
            }
        }
        return best;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var width = dc.getWidth();
        var height = dc.getHeight();

        var periods = settings.getPeriods();

        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var nowMinutes = info.hour * 60 + info.min;
        var inHC = settings.isHeuresCreuses(periods, nowMinutes);

        var period = relevantPeriod(periods, nowMinutes);
        if (period != null) {
            var range = settings.minutesToTimeString(period[0]) + " - " + settings.minutesToTimeString(period[1]);
            dc.drawText(width / 2, height / 2 - 60, Graphics.FONT_XTINY, range, Graphics.TEXT_JUSTIFY_CENTER);
        }

        var remainingStr = "";
        if (periods.size() == 0) {
            remainingStr = WatchUi.loadResource(Rez.Strings.NoPeriods) as String;
        } else if (inHC) {
            remainingStr = WatchUi.loadResource(Rez.Strings.StatusActive) as String;
        } else {
            var minutesLeft = settings.minutesUntilNextHeuresCreuses(periods, nowMinutes);
            var timePrefix = WatchUi.loadResource(Rez.Strings.RemainingTimePrefix) as String;
            remainingStr = timePrefix + settings.formatRemaining(minutesLeft);
        }

        dc.drawText(width / 2, height / 2 + 20, Graphics.FONT_MEDIUM, remainingStr, Graphics.TEXT_JUSTIFY_CENTER);
    }
}

// Native side menu holding the main view actions; it dismisses itself on selection or back.
class HomeActionMenu extends WatchUi.ActionMenu {
    function initialize() {
        ActionMenu.initialize(null);
        addItem(new WatchUi.ActionMenuItem({:label => Rez.Strings.Settings}, :settings));
        addItem(new WatchUi.ActionMenuItem({:label => Rez.Strings.Credits}, :credits));
    }
}

class HomeActionMenuDelegate extends WatchUi.ActionMenuDelegate {
    var mainView as HeuresCreusesView;

    function initialize(view as HeuresCreusesView) {
        ActionMenuDelegate.initialize();
        mainView = view;
    }

    function onSelect(item as WatchUi.ActionMenuItem) as Void {
        mainView.queueAction(item.getId() as Symbol);
    }
}

class HeuresCreusesDelegate extends WatchUi.BehaviorDelegate {
    // Showing the action menu twice in a row freezes it mid-animation.
    const MENU_DEBOUNCE_MS = 1000;

    var mainView as HeuresCreusesView;
    var lastMenuTime as Number;

    function initialize(view as HeuresCreusesView) {
        BehaviorDelegate.initialize();
        mainView = view;
        lastMenuTime = -MENU_DEBOUNCE_MS;
    }

    function showMenu() as Boolean {
        var now = System.getTimer();
        if (now - lastMenuTime >= MENU_DEBOUNCE_MS) {
            lastMenuTime = now;
            WatchUi.showActionMenu(new HomeActionMenu(), new HomeActionMenuDelegate(mainView));
        }
        return true;
    }

    // Product action menu input, handled by the system: a button, KEY_ENTER or the edge
    // touch area, depending on the watch. Don't add a swipe handler, it would open it twice.
    function onActionMenu() as Boolean {
        return showMenu();
    }

    function onMenu() as Boolean {
        return showMenu();
    }
}
