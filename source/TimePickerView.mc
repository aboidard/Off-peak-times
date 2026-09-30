import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

function createIconButton(x as Number, y as Number, size as Number, behavior as Symbol) as WatchUi.Button {
    return new WatchUi.Button({
        :locX => x,
        :locY => y,
        :width => size,
        :height => size,
        :behavior => behavior,
        :background => Graphics.COLOR_TRANSPARENT,
        :stateDefault => Graphics.COLOR_TRANSPARENT,
        :stateHighlighted => Graphics.COLOR_TRANSPARENT,
        :stateSelected => Graphics.COLOR_TRANSPARENT,
        :stateDisabled => Graphics.COLOR_TRANSPARENT
    });
}

function drawCheckIcon(dc as Dc, centerX as Number, centerY as Number) as Void {
    dc.setColor(0x20A95A, 0x20A95A);
    dc.fillCircle(centerX, centerY, 29);
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
    dc.setPenWidth(5);
    dc.drawLine(centerX - 12, centerY, centerX - 3, centerY + 9);
    dc.drawLine(centerX - 3, centerY + 9, centerX + 15, centerY - 12);
    dc.setPenWidth(1);
}

function drawTrashIcon(dc as Dc, centerX as Number, centerY as Number) as Void {
    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
    dc.fillCircle(centerX, centerY, 29);
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
    dc.setPenWidth(2);
    // Lid
    dc.drawLine(centerX - 9, centerY - 8, centerX + 9, centerY - 8);
    dc.drawLine(centerX - 3, centerY - 11, centerX + 3, centerY - 11);
    // Bin body
    dc.drawLine(centerX - 7, centerY - 6, centerX - 6, centerY + 10);
    dc.drawLine(centerX + 7, centerY - 6, centerX + 6, centerY + 10);
    dc.drawLine(centerX - 6, centerY + 10, centerX + 6, centerY + 10);
    dc.setPenWidth(1);
}

class TimePickerView extends WatchUi.View {
    var startMinutes as Number;
    var endMinutes as Number;
    var selectedField as Number;
    var isNew as Boolean;
    var width as Number;
    var height as Number;
    var fieldTop as Number;
    var fieldBottom as Number;
    var buttonTop as Number;
    var actionButtons as Array<WatchUi.Drawable>;

    function initialize(startMinute as Number, endMinute as Number, newPeriod as Boolean) {
        View.initialize();
        startMinutes = startMinute;
        endMinutes = endMinute;
        selectedField = 0;
        isNew = newPeriod;
        width = 0;
        height = 0;
        fieldTop = 0;
        fieldBottom = 0;
        buttonTop = 0;
        actionButtons = [];
    }

    function onLayout(dc as Dc) as Void {
        width = dc.getWidth();
        height = dc.getHeight();
        buttonTop = height * 70 / 100;
        actionButtons = [];

        if (isNew) {
            actionButtons.add(createIconButton(width / 2 - 32, buttonTop, 64, :onAdd));
        } else {
            actionButtons.add(createIconButton(width / 4 - 32, buttonTop, 64, :onDelete));
            actionButtons.add(createIconButton(width * 3 / 4 - 32, buttonTop, 64, :onSave));
        }
        setLayout(actionButtons);
    }

    function formatTime(minutes as Number) as String {
        var hour = minutes / 60;
        var minute = minutes % 60;
        var hourText = hour < 10 ? "0" + hour.toString() : hour.toString();
        var minuteText = minute < 10 ? "0" + minute.toString() : minute.toString();
        return hourText + ":" + minuteText;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        View.onUpdate(dc);
        width = dc.getWidth();
        height = dc.getHeight();
        fieldTop = height * 30 / 100;
        fieldBottom = height * 65 / 100;
        if (isNew) {
            drawCheckIcon(dc, width / 2, buttonTop + 32);
        } else {
            drawTrashIcon(dc, width / 4, buttonTop + 32);
            drawCheckIcon(dc, width * 3 / 4, buttonTop + 32);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var title = isNew ? Rez.Strings.AddPeriod : Rez.Strings.Periods;
        dc.drawText(width / 2, height * 0.16, Graphics.FONT_SMALL,
                    WatchUi.loadResource(title) as String, Graphics.TEXT_JUSTIFY_CENTER);

        var startColor = selectedField == 0 ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE;
        var endColor = selectedField == 1 ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE;
        dc.setColor(startColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 4, height * 0.39, Graphics.FONT_XTINY,
                    WatchUi.loadResource(Rez.Strings.Start) as String, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 4, height * 0.49, Graphics.FONT_LARGE,
                    formatTime(startMinutes), Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(endColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width * 3 / 4, height * 0.39, Graphics.FONT_XTINY,
                    WatchUi.loadResource(Rez.Strings.End) as String, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width * 3 / 4, height * 0.49, Graphics.FONT_LARGE,
                    formatTime(endMinutes), Graphics.TEXT_JUSTIFY_CENTER);

    }

    function getTime(fieldIndex as Number) as Number {
        return fieldIndex == 0 ? startMinutes : endMinutes;
    }

    function setTime(fieldIndex as Number, minutes as Number) as Void {
        if (fieldIndex == 0) {
            startMinutes = minutes;
        } else {
            endMinutes = minutes;
        }
        WatchUi.requestUpdate();
    }
}

// Vertical wheel factory for a 0..count-1 numeric picker column (native Picker style).
class TimeUnitPickerFactory extends WatchUi.PickerFactory {
    var itemCount as Number;

    function initialize(count as Number) {
        PickerFactory.initialize();
        itemCount = count;
    }

    function getDrawable(item as Number, isSelected as Boolean) as WatchUi.Drawable or Null {
        var text = item < 10 ? "0" + item.toString() : item.toString();
        return new WatchUi.Text({:text => text, :color => Graphics.COLOR_WHITE,
                                  :font => Graphics.FONT_NUMBER_MEDIUM,
                                  :locX => WatchUi.LAYOUT_HALIGN_CENTER,
                                  :locY => WatchUi.LAYOUT_VALIGN_CENTER});
    }

    function getSize() as Number {
        return itemCount;
    }

    function getValue(item as Number) as Lang.Object or Null {
        return item;
    }
}

