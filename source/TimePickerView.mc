import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Timer;
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

// Two side-by-side wheels: hours on the left (index 1), minutes on the right (index 0).
class WheelPickerView extends WatchUi.View {
    const FRICTION = 0.92;
    const TICK_MS = 33;

    var titleText as String;
    var positions as Array<Float>;
    var counts as Array<Number>;
    var activeWheel as Number;
    var velocity as Float;
    var lastY as Number;
    var lastTime as Number;
    var timer as Timer.Timer or Null;
    var width as Number;
    var height as Number;
    var rowHeight as Float;
    var centerY as Number;
    var buttonY as Number;

    function initialize(title as String, hour as Number, minute as Number) {
        View.initialize();
        titleText = title;
        positions = [minute.toFloat(), hour.toFloat()];
        counts = [60, 24];
        activeWheel = 1;
        velocity = 0.0;
        lastY = 0;
        lastTime = 0;
        timer = null;
        width = 0;
        height = 0;
        rowHeight = 80.0;
        centerY = 0;
        buttonY = 0;
    }

    function onLayout(dc as Dc) as Void {
        updateGeometry(dc.getWidth(), dc.getHeight());
    }

    function updateGeometry(w as Number, h as Number) as Void {
        width = w;
        height = h;
        rowHeight = h * 0.19;
        centerY = h / 2;
        buttonY = h * 89 / 100;
    }

    function onHide() as Void {
        stopTimer();
    }

    function getValue(wheel as Number) as Number {
        return Math.round(positions[wheel]).toNumber() % counts[wheel];
    }

    function formatValue(value as Number) as String {
        return value < 10 ? "0" + value.toString() : value.toString();
    }

    function wheelX(wheel as Number) as Number {
        return wheel == 0 ? width * 7 / 10 : width * 3 / 10;
    }

    function normalize(wheel as Number) as Void {
        var count = counts[wheel].toFloat();
        var p = positions[wheel];
        while (p < 0) {
            p += count;
        }
        while (p >= count) {
            p -= count;
        }
        positions[wheel] = p;
    }

    function onUpdate(dc as Dc) as Void {
        updateGeometry(dc.getWidth(), dc.getHeight());
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var half = (rowHeight * 1.5).toNumber();
        var top = centerY - half;
        var colWidth = width * 36 / 100;

        // Active column highlight
        dc.setColor(0x16301E, 0x16301E);
        dc.fillRectangle(wheelX(activeWheel) - colWidth / 2, top, colWidth, half * 2);

        // Selection band
        dc.setColor(0x262D38, 0x262D38);
        dc.fillRectangle(0, centerY - (rowHeight / 2).toNumber(), width, rowHeight.toNumber());

        // Title and underline
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 4 / 100, Graphics.FONT_SMALL, titleText, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(0x808080, 0x808080);
        dc.drawLine(width * 19 / 100, height * 15 / 100, width * 81 / 100, height * 15 / 100);

        for (var wheel = 0; wheel < 2; wheel += 1) {
            drawWheel(dc, wheel, top, half * 2);
        }

        // Active indicator under the selected value
        dc.setColor(0x3CE070, 0x3CE070);
        dc.fillRectangle(wheelX(activeWheel) - colWidth / 2, centerY + (rowHeight / 2).toNumber() - 3, colWidth, 3);

        dc.setClip(0, 0, width, height);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, centerY, Graphics.FONT_NUMBER_MEDIUM, ":",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        drawCheckIcon(dc, width / 2, buttonY);
    }

    function drawWheel(dc as Dc, wheel as Number, top as Number, clipHeight as Number) as Void {
        var pos = positions[wheel];
        var base = Math.round(pos).toNumber();
        var count = counts[wheel];
        var x = wheelX(wheel);
        dc.setClip(0, top, width, clipHeight);
        for (var k = -2; k <= 2; k += 1) {
            var offset = (base + k) - pos;
            var y = centerY + (offset * rowHeight).toNumber();
            var value = ((base + k) % count + count) % count;
            var isCenter = offset > -0.5 and offset < 0.5;
            dc.setColor(isCenter ? Graphics.COLOR_WHITE : 0x9A9A9A, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y, isCenter ? Graphics.FONT_NUMBER_MEDIUM : Graphics.FONT_MEDIUM,
                        formatValue(value), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function beginDrag(x as Number, y as Number) as Void {
        stopTimer();
        activeWheel = x < width / 2 ? 1 : 0;
        velocity = 0.0;
        lastY = y;
        lastTime = System.getTimer();
        WatchUi.requestUpdate();
    }

    function dragTo(y as Number) as Void {
        var now = System.getTimer();
        var dt = now - lastTime;
        var delta = (lastY - y) / rowHeight;
        positions[activeWheel] += delta;
        normalize(activeWheel);
        if (dt > 0) {
            velocity = 0.5 * velocity + 0.5 * (delta / dt);
        }
        lastY = y;
        lastTime = now;
        WatchUi.requestUpdate();
    }

    function endDrag() as Void {
        if (System.getTimer() - lastTime > 100) {
            velocity = 0.0;
        }
        timer = new Timer.Timer();
        timer.start(method(:onTick), TICK_MS, true);
    }

    function onTick() as Void {
        var step = velocity * TICK_MS;
        if (step > 0.05 or step < -0.05) {
            positions[activeWheel] += step;
            normalize(activeWheel);
            velocity *= FRICTION;
        } else {
            var target = Math.round(positions[activeWheel]);
            var diff = target - positions[activeWheel];
            if (diff > -0.01 and diff < 0.01) {
                positions[activeWheel] = target;
                normalize(activeWheel);
                velocity = 0.0;
                stopTimer();
            } else {
                positions[activeWheel] += diff * 0.35;
            }
        }
        WatchUi.requestUpdate();
    }

    function stopTimer() as Void {
        if (timer != null) {
            timer.stop();
            timer = null;
        }
    }

    function isOnButton(x as Number, y as Number) as Boolean {
        var dx = x - width / 2;
        var dy = y - buttonY;
        return dx * dx + dy * dy <= 40 * 40;
    }
}

class WheelPickerDelegate extends WatchUi.InputDelegate {
    var wheelView as WheelPickerView;
    var pickerView as TimePickerView;
    var fieldIndex as Number;

    function initialize(view as WheelPickerView, editor as TimePickerView, index as Number) {
        InputDelegate.initialize();
        wheelView = view;
        pickerView = editor;
        fieldIndex = index;
    }

    function accept() as Void {
        var minutes = wheelView.getValue(1) * 60 + wheelView.getValue(0);
        pickerView.setTime(fieldIndex, minutes);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function onTap(clickEvent as ClickEvent) as Boolean {
        var coordinates = clickEvent.getCoordinates();
        if (wheelView.isOnButton(coordinates[0], coordinates[1])) {
            accept();
            return true;
        }
        return false;
    }

    function onDrag(dragEvent as DragEvent) as Boolean {
        var coordinates = dragEvent.getCoordinates();
        var type = dragEvent.getType();
        if (type == WatchUi.DRAG_TYPE_START) {
            wheelView.beginDrag(coordinates[0], coordinates[1]);
        } else if (type == WatchUi.DRAG_TYPE_CONTINUE) {
            wheelView.dragTo(coordinates[1]);
        } else {
            wheelView.dragTo(coordinates[1]);
            wheelView.endDrag();
        }
        return true;
    }

    function onKey(keyEvent as KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_START or key == WatchUi.KEY_ENTER) {
            accept();
            return true;
        } else if (key == WatchUi.KEY_ESC) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return true;
        }
        return false;
    }
}

