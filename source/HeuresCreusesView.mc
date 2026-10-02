import Toybox.Graphics;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Timer;

class HeuresCreusesView extends WatchUi.View {
    const GRAB_ZONE = 70;
    const TICK_MS = 33;

    var settings as Settings;
    var screenWidth as Number;
    var screenHeight as Number;
    var drawerWidth as Number;
    var drawerOffset as Number;
    var drawerTarget as Number;
    var drawerTimer as Timer.Timer or Null;

    function initialize() {
        View.initialize();
        settings = new Settings();
        screenWidth = 0;
        screenHeight = 0;
        drawerWidth = 0;
        drawerOffset = 0;
        drawerTarget = 0;
        drawerTimer = null;
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
        drawerWidth = screenWidth * 60 / 100;
    }

    function setDrawerOffset(offset as Number) as Void {
        drawerOffset = offset < 0 ? 0 : (offset > drawerWidth ? drawerWidth : offset);
        WatchUi.requestUpdate();
    }

    function isDrawerOpen() as Boolean {
        return drawerOffset > 0;
    }

    function isInGrabZone(x as Number) as Boolean {
        return x >= screenWidth - GRAB_ZONE;
    }

    function settleDrawer(open as Boolean) as Void {
        drawerTarget = open ? drawerWidth : 0;
        stopDrawerTimer();
        drawerTimer = new Timer.Timer();
        drawerTimer.start(method(:onDrawerTick), TICK_MS, true);
    }

    function onDrawerTick() as Void {
        var diff = drawerTarget - drawerOffset;
        var step = diff * 40 / 100;
        if (step == 0) {
            step = diff > 0 ? 1 : -1;
        }
        if (diff == 0 or (diff > 0 and step >= diff) or (diff < 0 and step <= diff)) {
            drawerOffset = drawerTarget;
            stopDrawerTimer();
        } else {
            drawerOffset += step;
        }
        WatchUi.requestUpdate();
    }

    function stopDrawerTimer() as Void {
        if (drawerTimer != null) {
            drawerTimer.stop();
            drawerTimer = null;
        }
    }

    function drawDrawer(dc as Dc) as Void {
        var panelX = screenWidth - drawerOffset;

        if (drawerOffset > 0) {
            dc.setColor(0x1C1C1C, 0x1C1C1C);
            dc.fillRectangle(panelX, 0, drawerOffset, screenHeight);
        }

        // Handle follows the panel edge.
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillRoundedRectangle(panelX - 12, screenHeight / 2 - 30, 6, 60, 3);

        if (drawerOffset > drawerWidth / 2) {
            var centerX = panelX + drawerOffset / 2;
            var justify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, screenHeight * 38 / 100, Graphics.FONT_SMALL,
                        WatchUi.loadResource(Rez.Strings.Settings) as String, justify);
            dc.drawText(centerX, screenHeight * 62 / 100, Graphics.FONT_SMALL,
                        WatchUi.loadResource(Rez.Strings.Credits) as String, justify);
            dc.setColor(0x606060, 0x606060);
            dc.drawLine(panelX + 20, screenHeight / 2, screenWidth, screenHeight / 2);
        }
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

        drawDrawer(dc);
    }

    function onHide() {
        stopDrawerTimer();
    }
}

class HeuresCreusesDelegate extends WatchUi.InputDelegate {
    var mainView as HeuresCreusesView;
    var dragging as Boolean;
    var dragStartX as Number;
    var dragStartOffset as Number;

    function initialize(view as HeuresCreusesView) {
        InputDelegate.initialize();
        mainView = view;
        dragging = false;
        dragStartX = 0;
        dragStartOffset = 0;
    }

    function onDrag(dragEvent as DragEvent) as Boolean {
        var x = dragEvent.getCoordinates()[0];
        var type = dragEvent.getType();
        if (type == WatchUi.DRAG_TYPE_START) {
            dragging = mainView.isDrawerOpen() or mainView.isInGrabZone(x);
            if (dragging) {
                mainView.stopDrawerTimer();
                dragStartX = x;
                dragStartOffset = mainView.drawerOffset;
            }
            return dragging;
        }
        if (!dragging) {
            return false;
        }
        mainView.setDrawerOffset(dragStartOffset + dragStartX - x);
        if (type == WatchUi.DRAG_TYPE_STOP) {
            dragging = false;
            mainView.settleDrawer(mainView.drawerOffset > mainView.drawerWidth * 40 / 100);
        }
        return true;
    }

    function onTap(clickEvent as ClickEvent) as Boolean {
        var coordinates = clickEvent.getCoordinates();
        var x = coordinates[0];
        var y = coordinates[1];
        if (mainView.isDrawerOpen()) {
            if (x >= mainView.screenWidth - mainView.drawerOffset) {
                mainView.stopDrawerTimer();
                mainView.setDrawerOffset(0);
                if (y < mainView.screenHeight / 2) {
                    openSettings(false);
                } else {
                    openCredits(false);
                }
            } else {
                mainView.settleDrawer(false);
            }
            return true;
        }
        if (mainView.isInGrabZone(x)) {
            mainView.settleDrawer(true);
            return true;
        }
        return false;
    }

    function onKey(keyEvent as KeyEvent) as Boolean {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_ENTER) {
            WatchUi.pushView(new HomeMenuView(), new HomeMenuDelegate(), WatchUi.SLIDE_UP);
            return true;
        } else if (key == WatchUi.KEY_ESC and mainView.isDrawerOpen()) {
            mainView.settleDrawer(false);
            return true;
        }

        return false;
    }
}