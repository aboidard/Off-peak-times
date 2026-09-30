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
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function onShow() as Void {
    }

    function isHeuresCreuses(minutes) {
        var periods = settings.getPeriods();
        for (var index = 0; index < periods.size(); index += 1) {
            var startMinute = periods[index][0];
            var endMinute = periods[index][1];

            if (startMinute == endMinute or
                (startMinute < endMinute and minutes >= startMinute and minutes < endMinute) or
                (startMinute > endMinute and (minutes >= startMinute or minutes < endMinute))) {
                return true;
            }
        }
        return false;
    }

    function minutesUntilNextHeuresCreuses(nowMinutes) {
        var periods = settings.getPeriods();
        if (periods.size() == 0 or isHeuresCreuses(nowMinutes)) {
            return 0;
        }

        var shortestDelay = 24 * 60;
        for (var index = 0; index < periods.size(); index += 1) {
            var delay = periods[index][0] - nowMinutes;
            if (delay < 0) {
                delay += 24 * 60;
            }
            if (delay < shortestDelay) {
                shortestDelay = delay;
            }
        }
        return shortestDelay;
    }

    function roundUpToHalfHour(minutes) {
        var half = 30;
        var remainder = minutes % half;
        if (remainder == 0) {
            return minutes;
        }
        return minutes + (half - remainder);
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var width = dc.getWidth();
        var height = dc.getHeight();

        var periods = settings.getPeriods();
        var periodSummary = WatchUi.loadResource(Rez.Strings.PeriodCountPrefix) as String;
        periodSummary += periods.size().toString();
        dc.drawText(width / 2, height / 2 - 60, Graphics.FONT_XTINY, periodSummary, Graphics.TEXT_JUSTIFY_CENTER);

        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var nowMinutes = info.hour * 60 + info.min;
        var inHC = isHeuresCreuses(nowMinutes);

        var remainingStr = "";
        if (periods.size() == 0) {
            remainingStr = WatchUi.loadResource(Rez.Strings.NoPeriods) as String;
        } else if (inHC) {
            remainingStr = WatchUi.loadResource(Rez.Strings.StatusActive) as String;
        } else {
            var minutesLeft = minutesUntilNextHeuresCreuses(nowMinutes);
            var minutesRounded = roundUpToHalfHour(minutesLeft);

            var h = minutesRounded / 60;
            var m = minutesRounded % 60;

            var timePrefix = WatchUi.loadResource(Rez.Strings.RemainingTimePrefix) as String;
            var hourSuffix = WatchUi.loadResource(Rez.Strings.HourSuffix) as String;
            remainingStr = timePrefix + h.toString() + hourSuffix +
                           ((m == 0) ? "" : (m < 10 ? "0" : "") + m.toString());
        }

        dc.drawText(width / 2, height / 2 + 20, Graphics.FONT_MEDIUM, remainingStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function onHide() {
    }
}

class HeuresCreusesDelegate extends WatchUi.InputDelegate {
    function initialize() {
        InputDelegate.initialize();
    }

    function onKey(keyEvent as KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        //log key press
        System.println("Key pressed: " + key.toString());

        if (key == WatchUi.KEY_ENTER) {
            WatchUi.pushView(new HomeMenuView(), new HomeMenuDelegate(), WatchUi.SLIDE_UP);
            return true;
        }

        return false;
    }
}