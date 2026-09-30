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
            WatchUi.switchToView(new CreditView(), new CreditDelegate(), WatchUi.SLIDE_UP);
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
    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var width = dc.getWidth();
        var height = dc.getHeight();
        dc.drawText(width / 2, height / 2 - 50, Graphics.FONT_SMALL,
                    WatchUi.loadResource(Rez.Strings.CreditTitle) as String,
                    Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, height / 2, Graphics.FONT_XTINY,
                    WatchUi.loadResource(Rez.Strings.CreditAuthor) as String,
                    Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, height / 2 + 30, Graphics.FONT_XTINY,
                    WatchUi.loadResource(Rez.Strings.CreditDescription) as String,
                    Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class CreditDelegate extends WatchUi.InputDelegate {
    function initialize() {
        InputDelegate.initialize();
    }

    function onKey(keyEvent as KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_ESC or key == WatchUi.KEY_MENU or key == WatchUi.KEY_START) {
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
        var picker = new WatchUi.Picker({
            :title => new WatchUi.Text({:text => WatchUi.loadResource(title) as String}),
            :pattern => [
                new TimeUnitPickerFactory(24),
                new WatchUi.Text({:text => ":", :color => Graphics.COLOR_WHITE, :font => Graphics.FONT_NUMBER_MEDIUM}),
                new TimeUnitPickerFactory(60)
            ],
            :defaults => [initialHour, 0, initialMinute]
        });
        WatchUi.pushView(picker, new TimeValuePickerDelegate(pickerView, fieldIndex), WatchUi.SLIDE_UP);
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

class TimeValuePickerDelegate extends WatchUi.PickerDelegate {
    var pickerView as TimePickerView;
    var fieldIndex as Number;

    function initialize(view as TimePickerView, index as Number) {
        PickerDelegate.initialize();
        pickerView = view;
        fieldIndex = index;
    }

    function onAccept(values as Array) as Boolean {
        if (values[0] != null and values[2] != null) {
            var minutes = (values[0] as Number) * 60 + (values[2] as Number);
            pickerView.setTime(fieldIndex, minutes);
        }
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}