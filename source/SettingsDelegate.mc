import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class HomeMenuView extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title => Rez.Strings.AppName});
        addItem(new WatchUi.MenuItem(Rez.Strings.Settings, null, :settings, null));
        addItem(new WatchUi.MenuItem(Rez.Strings.Credits, null, :credits, null));
    }
}

class HomeMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item.getId() == :settings) {
            var settingsView = new SettingsView();
            WatchUi.switchToView(settingsView, new SettingsDelegate(settingsView), WatchUi.SLIDE_UP);
        } else if (item.getId() == :credits) {
            var creditView = new CreditView();
            WatchUi.switchToView(creditView, new CreditDelegate(creditView), WatchUi.SLIDE_UP);
        }
    }
}

class SettingsDelegate extends WatchUi.Menu2InputDelegate {
    var settingsView as SettingsView;

    function initialize(view as SettingsView) {
        Menu2InputDelegate.initialize();
        settingsView = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var identifier = item.getId();
        var periods = settingsView.settings.getPeriods();
        var periodIndex = -1;

        if (identifier == :add) {
            periodIndex = periods.size();
        } else if (identifier instanceof Number) {
            periodIndex = identifier as Number;
        } else {
            return;
        }

        if (periodIndex < 0 or periodIndex >= Settings.MAX_PERIODS) {
            return;
        }

        var startMinute = 22 * 60;
        var endMinute = 6 * 60;
        if (periodIndex < periods.size()) {
            startMinute = periods[periodIndex][0];
            endMinute = periods[periodIndex][1];
        }

        var isNew = periodIndex == periods.size();
        var editor = new TimePickerView(startMinute, endMinute, isNew);
        var delegate = new TimePickerDelegate(editor, settingsView, periodIndex);
        WatchUi.switchToView(editor, delegate, WatchUi.SLIDE_UP);
    }
}

class DeletePeriodView extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title => Rez.Strings.DeleteConfirmation});
        addItem(new WatchUi.MenuItem(Rez.Strings.Delete, null, :delete, null));
        addItem(new WatchUi.MenuItem(Rez.Strings.Cancel, null, :cancel, null));
    }
}

class DeletePeriodDelegate extends WatchUi.Menu2InputDelegate {
    var settings as Settings;
    var settingsView as SettingsView;
    var editor as TimePickerView;
    var periodIndex as Number;

    function initialize(model as Settings, listView as SettingsView, editView as TimePickerView, index as Number) {
        Menu2InputDelegate.initialize();
        settings = model;
        settingsView = listView;
        editor = editView;
        periodIndex = index;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item.getId() == :delete) {
            settings.removePeriod(periodIndex);
            settingsView.refresh();
            WatchUi.switchToView(settingsView, new SettingsDelegate(settingsView), WatchUi.SLIDE_IMMEDIATE);
        } else {
            WatchUi.switchToView(editor,
                new TimePickerDelegate(editor, settingsView, periodIndex),
                WatchUi.SLIDE_IMMEDIATE);
        }
    }
}

class CreditView extends WatchUi.View {
    var qrCode as WatchUi.BitmapResource or Null;
    var scrollOffset as Number;
    var maxScroll as Number;

    function initialize() {
        View.initialize();
        qrCode = null;
        scrollOffset = 0;
        maxScroll = 0;
    }

    function onLayout(dc as Dc) as Void {
        qrCode = WatchUi.loadResource(Rez.Drawables.QrCode) as WatchUi.BitmapResource;
        maxScroll = dc.getHeight() * 75 / 100;
    }

    function scrollBy(delta as Number) as Void {
        scrollOffset += delta;
        if (scrollOffset < 0) {
            scrollOffset = 0;
        } else if (scrollOffset > maxScroll) {
            scrollOffset = maxScroll;
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // The QR page fills the screen; its quiet zone is white so it scans on a dark background.
        if (qrCode != null) {
            var size = qrCode.getWidth();
            var x = (width - size) / 2;
            var y = (height - size) / 2 - scrollOffset;
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
            dc.fillRectangle(x, y, size, size);
            dc.drawBitmap(x, y, qrCode);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var justify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.drawText(width / 2, height * 125 / 100 - scrollOffset, Graphics.FONT_SMALL,
                    WatchUi.loadResource(Rez.Strings.CreditTitle) as String, justify);
        dc.drawText(width / 2, height * 145 / 100 - scrollOffset, Graphics.FONT_XTINY,
                    WatchUi.loadResource(Rez.Strings.CreditAuthor) as String, justify);
        dc.drawText(width / 2, height * 160 / 100 - scrollOffset, Graphics.FONT_XTINY,
                    WatchUi.loadResource(Rez.Strings.CreditDescription) as String, justify);
    }
}

class CreditDelegate extends WatchUi.InputDelegate {
    var creditView as CreditView;
    var lastY as Number;

    function initialize(view as CreditView) {
        InputDelegate.initialize();
        creditView = view;
        lastY = 0;
    }

    function onDrag(dragEvent as DragEvent) as Boolean {
        var y = dragEvent.getCoordinates()[1];
        if (dragEvent.getType() != WatchUi.DRAG_TYPE_START) {
            creditView.scrollBy(lastY - y);
        }
        lastY = y;
        return true;
    }

    function onKey(keyEvent as KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_DOWN) {
            creditView.scrollBy(60);
            return true;
        } else if (key == WatchUi.KEY_UP) {
            creditView.scrollBy(-60);
            return true;
        } else if (key == WatchUi.KEY_ESC or key == WatchUi.KEY_MENU or key == WatchUi.KEY_START) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return true;
        }
        return false;
    }

    function onSwipe(swipeEvent as SwipeEvent) as Boolean {
        if (swipeEvent.getDirection() == WatchUi.SWIPE_RIGHT) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return true;
        }
        return false;
    }
}

class TimePickerDelegate extends WatchUi.BehaviorDelegate {
    var pickerView as TimePickerView;
    var settingsView as SettingsView;
    var settings as Settings;
    var periodIndex as Number;

    function initialize(view as TimePickerView, listView as SettingsView, index as Number) {
        BehaviorDelegate.initialize();
        pickerView = view;
        settingsView = listView;
        settings = listView.settings;
        periodIndex = index;
    }

    function onAdd() as Boolean {
        savePeriod();
        return true;
    }

    function onSave() as Boolean {
        savePeriod();
        return true;
    }

    function onDelete() as Boolean {
        openDeleteConfirmation();
        return true;
    }

    function openPicker() as Void {
        var fieldIndex = pickerView.selectedField;
        var initialMinutes = pickerView.getTime(fieldIndex);
        var initialHour = initialMinutes / 60;
        var initialMinute = initialMinutes % 60;
        var title = fieldIndex == 0 ? Rez.Strings.Start : Rez.Strings.End;
        var wheels = new WheelPickerView(WatchUi.loadResource(title) as String, initialHour, initialMinute);
        WatchUi.pushView(wheels, new WheelPickerDelegate(wheels, pickerView, fieldIndex), WatchUi.SLIDE_UP);
    }

    function openDeleteConfirmation() as Void {
        var confirmation = new DeletePeriodView();
        WatchUi.switchToView(confirmation,
            new DeletePeriodDelegate(settings, settingsView, pickerView, periodIndex),
            WatchUi.SLIDE_UP);
    }

    function savePeriod() as Void {
        settings.setPeriod(periodIndex, pickerView.startMinutes, pickerView.endMinutes);
        settingsView.refresh();
        WatchUi.switchToView(settingsView, new SettingsDelegate(settingsView), WatchUi.SLIDE_IMMEDIATE);
    }

    function handleTap(x as Number, y as Number) as Boolean {
        if (y >= pickerView.fieldTop and y <= pickerView.fieldBottom) {
            pickerView.selectedField = x < pickerView.width / 2 ? 0 : 1;
            openPicker();
            return true;
        }
        return false;
    }

    function onTap(clickEvent as ClickEvent) as Boolean {
        var coordinates = clickEvent.getCoordinates();
        return handleTap(coordinates[0], coordinates[1]);
    }

    function onKey(keyEvent as KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_UP or key == WatchUi.KEY_DOWN) {
            pickerView.selectedField = (pickerView.selectedField + 1) % 2;
            WatchUi.requestUpdate();
            return true;
        } else if (key == WatchUi.KEY_ENTER) {
            openPicker();
            return true;
        } else if (key == WatchUi.KEY_START) {
            savePeriod();
            return true;
        } else if (key == WatchUi.KEY_MENU and pickerView.isNew == false) {
            openDeleteConfirmation();
            return true;
        } else if (key == WatchUi.KEY_ESC) {
            WatchUi.switchToView(settingsView, new SettingsDelegate(settingsView), WatchUi.SLIDE_IMMEDIATE);
            return true;
        }
        return false;
    }
}
