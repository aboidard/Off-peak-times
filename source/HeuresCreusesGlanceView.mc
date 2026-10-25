import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Lang;

(:glance)
class HeuresCreusesGlanceView extends WatchUi.GlanceView {
    var settings as Settings;

    function initialize() {
        GlanceView.initialize();
        settings = new Settings();
    }
    
    function onUpdate(dc as Dc) as Void {
        var width  = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.clear();

        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var nowMinutes = info.hour * 60 + info.min;

        // --- Status text ---
        var text;
        var periods = settings.getPeriods();
        if (periods.size() == 0) {
            text = WatchUi.loadResource(Rez.Strings.NoPeriods) as String;
        } else if (settings.isHeuresCreuses(periods, nowMinutes)) {
            text = WatchUi.loadResource(Rez.Strings.StatusActive) as String;
        } else {
            var minutesLeft = settings.minutesUntilNextHeuresCreuses(periods, nowMinutes);
            var nextPrefix = WatchUi.loadResource(Rez.Strings.NextOffPeakPrefix) as String;
            text = nextPrefix + settings.formatRemaining(minutesLeft);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2,
            height / 2 - 18,
            Graphics.FONT_XTINY,
            text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // --- Timeline bar ---
        // The bar spans 24h, centered on "now"
        // nowMinutes maps to the center of the bar (width/2)
        var barY      = height / 2 + 10;
        var barHeight = 3;
        var hcHeight  = 7;

        // Minutes -> pixels conversion
        // The bar shows a 24h window (1440 min) across the full width
        var totalMinutes = 1440;
        var pixelsPerMinute = width.toFloat() / totalMinutes.toFloat();

        // Pixel origin: pixel 0 maps to (nowMinutes - 720) minutes
        var windowStart = nowMinutes - 720; // 720 = 1440/2

        // Draw the baseline (gray)
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, barY - barHeight / 2, width, barHeight);

        // Configured off-peak periods
        // Also draw them for the next day (+1440) to cover the right edge
        var hcPeriods = new Array<Array<Number>>[0];
        for (var periodIndex = 0; periodIndex < periods.size(); periodIndex += 1) {
            var startMinute = periods[periodIndex][0];
            var endMinute = periods[periodIndex][1];
            for (var dayOffset = -1440; dayOffset <= 1440; dayOffset += 1440) {
                if (startMinute == endMinute) {
                    hcPeriods.add([dayOffset, dayOffset + 1440]);
                } else if (startMinute < endMinute) {
                    hcPeriods.add([dayOffset + startMinute, dayOffset + endMinute]);
                } else {
                    hcPeriods.add([dayOffset + startMinute, dayOffset + 1440]);
                    hcPeriods.add([dayOffset + 1440, dayOffset + 1440 + endMinute]);
                }
            }
        }

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < hcPeriods.size(); i++) {
            var startMin = hcPeriods[i][0];
            var endMin   = hcPeriods[i][1];

            var xStart = ((startMin - windowStart) * pixelsPerMinute).toNumber();
            var xEnd   = ((endMin   - windowStart) * pixelsPerMinute).toNumber();

            // Clamp to the screen width
            if (xStart < 0)     { xStart = 0; }
            if (xEnd   > width) { xEnd   = width; }

            if (xEnd > xStart) {
                dc.fillRectangle(
                    xStart,
                    barY - hcHeight / 2,
                    xEnd - xStart,
                    hcHeight
                );
            }
        }

        // "now" cursor: white vertical line at the center
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(width / 2 - 1, barY - 10, 2, 20);
    }
}