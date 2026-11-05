import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Lang;

(:glance)
class HeuresCreusesGlanceView extends WatchUi.GlanceView {
    // The round screen hides the corners of the glance area, so centered text only has part of its width.
    const TEXT_WIDTH_PERCENT = 54;
    // Vector face of the system font on the products that can't scale it (Approach S70).
    const VECTOR_FACE = "RobotoCondensedBold";

    var settings as Settings;

    function initialize() {
        GlanceView.initialize();
        settings = new Settings();
    }

    // When FONT_XTINY is too wide, use a smaller font rather than clip the text.
    function fittingFont(dc as Dc, text as String, maxWidth as Number) as Graphics.FontType {
        var textWidth = dc.getTextWidthInPixels(text, Graphics.FONT_XTINY);
        if (textWidth > maxWidth and Graphics has :getVectorFont) {
            var scale = maxWidth.toFloat() / textWidth;
            var font = Graphics.getVectorFont({:font => Graphics.FONT_XTINY, :scale => scale});
            if (font != null) {
                return font;
            }
            // Height in pixels doesn't map exactly to width: measure once, then correct the size.
            var size = dc.getFontHeight(Graphics.FONT_XTINY) * scale;
            font = Graphics.getVectorFont({:face => VECTOR_FACE, :size => size});
            if (font != null) {
                size = size * maxWidth / dc.getTextWidthInPixels(text, font);
                var corrected = Graphics.getVectorFont({:face => VECTOR_FACE, :size => size});
                return corrected != null ? corrected : font;
            }
        }
        return Graphics.FONT_XTINY;
    }

    function onUpdate(dc as Dc) as Void {
        var width  = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.clear();

        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var nowMinutes = info.hour * 60 + info.min;

        // --- Status text: title, then the remaining time when there is one ---
        var title;
        var remaining = null;
        var periods = settings.getPeriods();
        if (periods.size() == 0) {
            title = WatchUi.loadResource(Rez.Strings.NoPeriodsTitle) as String;
            remaining = WatchUi.loadResource(Rez.Strings.NoPeriodsDetail) as String;
        } else if (settings.isHeuresCreuses(periods, nowMinutes)) {
            title = WatchUi.loadResource(Rez.Strings.ActiveTitle) as String;
            var minutesToEnd = settings.minutesUntilEndOfHeuresCreuses(periods, nowMinutes);
            if (minutesToEnd != null) {
                // Exact whatever the precision setting: rounding up would announce an end later than the real one.
                remaining = (WatchUi.loadResource(Rez.Strings.ActiveEndPrefix) as String) + settings.formatDuration(minutesToEnd);
            }
        } else {
            title = WatchUi.loadResource(Rez.Strings.NextOffPeakTitle) as String;
            var minutesToNext = settings.minutesUntilNextHeuresCreuses(periods, nowMinutes);
            remaining = (WatchUi.loadResource(Rez.Strings.NextOffPeakPrefix) as String) + settings.formatRemaining(minutesToNext);
        }

        // Both lines share one font, chosen from the wider of the two.
        var widestLine = title;
        if (remaining != null and
            dc.getTextWidthInPixels(remaining, Graphics.FONT_XTINY) > dc.getTextWidthInPixels(title, Graphics.FONT_XTINY)) {
            widestLine = remaining;
        }
        var font = fittingFont(dc, widestLine, width * TEXT_WIDTH_PERCENT / 100);
        var lineHeight = dc.getFontHeight(font);
        var justify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        // Center the text and the bar together; the "now" cursor reaches 10 pixels around the bar.
        var textHeight = remaining != null ? lineHeight * 2 : lineHeight;
        var textBottom = (height - (textHeight + 12 + 10)) / 2 + textHeight;
        var barY = textBottom + 12;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (remaining != null) {
            dc.drawText(width / 2, textBottom - lineHeight / 2, font, remaining, justify);
            dc.drawText(width / 2, textBottom - lineHeight * 3 / 2, font, title, justify);
        } else {
            dc.drawText(width / 2, textBottom - lineHeight / 2, font, title, justify);
        }

        // --- Timeline bar ---
        // The bar spans 24h, centered on "now"
        // nowMinutes maps to the center of the bar (width/2)
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