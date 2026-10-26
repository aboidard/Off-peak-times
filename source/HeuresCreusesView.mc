import Toybox.Graphics;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Lang;

class HeuresCreusesView extends WatchUi.View {
    var settings as Settings;

    function initialize() {
        View.initialize();
        settings = new Settings();
        // System hint showing how to open the action menu on this product.
        if (View has :setActionMenuIndicator) {
            setActionMenuIndicator({:enabled => true});
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
    function initialize() {
        ActionMenuDelegate.initialize();
    }

    function onSelect(item as WatchUi.ActionMenuItem) as Void {
        if (item.getId() == :settings) {
            openSettings();
        } else if (item.getId() == :credits) {
            openCredits();
        }
    }
}

class HeuresCreusesDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function showMenu() as Boolean {
        WatchUi.showActionMenu(new HomeActionMenu(), new HomeActionMenuDelegate());
        return true;
    }

    // Product action menu input: a dedicated button or KEY_ENTER, depending on the watch.
    function onActionMenu() as Boolean {
        return showMenu();
    }

    function onMenu() as Boolean {
        return showMenu();
    }

    // Touch: the side menu slides in from the right edge, so a left swipe opens it.
    function onSwipe(swipeEvent as SwipeEvent) as Boolean {
        if (swipeEvent.getDirection() == WatchUi.SWIPE_LEFT) {
            return showMenu();
        }
        return false;
    }
}
