import Toybox.Lang;
import Toybox.WatchUi;

// Root settings menu: each entry opens a sub-menu and shows the current state as its sub-label.
class SettingsMenuView extends WatchUi.Menu2 {
    var settings as Settings;
    var periodsItem as WatchUi.MenuItem;
    var precisionItem as WatchUi.MenuItem;

    function initialize() {
        Menu2.initialize({:title => Rez.Strings.Settings});
        settings = new Settings();
        periodsItem = new WatchUi.MenuItem(Rez.Strings.Periods, null, :periods, null);
        precisionItem = new WatchUi.MenuItem(Rez.Strings.Precision, null, :precision, null);
        addItem(periodsItem);
        addItem(precisionItem);
        refresh();
    }

    function refresh() as Void {
        periodsItem.setSubLabel(periodsLabel(settings.getPeriods().size()));
        precisionItem.setSubLabel(precisionLabel(settings.getPrecision()));
    }

    function onShow() as Void {
        refresh();
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    var menuView as SettingsMenuView;

    function initialize(view as SettingsMenuView) {
        Menu2InputDelegate.initialize();
        menuView = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var identifier = item.getId();
        if (identifier == :periods) {
            var periodsView = new PeriodsView();
            WatchUi.pushView(periodsView, new PeriodsDelegate(periodsView), WatchUi.SLIDE_LEFT);
        } else if (identifier == :precision) {
            var precisionView = new PrecisionView(menuView.settings.getPrecision());
            WatchUi.pushView(precisionView, new PrecisionDelegate(menuView.settings), WatchUi.SLIDE_LEFT);
        }
    }
}

function periodsLabel(count as Number) as String {
    if (count == 0) {
        return WatchUi.loadResource(Rez.Strings.PeriodsCountNone) as String;
    } else if (count == 1) {
        return WatchUi.loadResource(Rez.Strings.PeriodsCountOne) as String;
    }
    return Lang.format(WatchUi.loadResource(Rez.Strings.PeriodsCountMany) as String, [count]);
}

class PeriodsView extends WatchUi.Menu2 {
    var settings as Settings;
    var itemCount as Number;

    function initialize() {
        Menu2.initialize({:title => Rez.Strings.Periods});
        settings = new Settings();
        itemCount = 0;
        refresh();
    }

    function refresh() as Void {
        while (itemCount > 0) {
            deleteItem(itemCount - 1);
            itemCount -= 1;
        }

        var periods = settings.getPeriods();
        for (var index = 0; index < periods.size(); index += 1) {
            var period = periods[index];
            var label = settings.minutesToTimeString(period[0]) + " - " +
                        settings.minutesToTimeString(period[1]);
            addItem(new WatchUi.MenuItem(label, null, index, null));
            itemCount += 1;
        }

        if (periods.size() < Settings.MAX_PERIODS) {
            addItem(new WatchUi.MenuItem(Rez.Strings.Add, null, :add, null));
        } else {
            addItem(new WatchUi.MenuItem(Rez.Strings.MaximumPeriods, null, :maximum, null));
        }
        itemCount += 1;
    }

    function onShow() as Void {
        refresh();
    }
}

function precisionLabel(precision as Number) as ResourceId {
    if (precision == Settings.PRECISION_HOUR) {
        return Rez.Strings.PrecisionHour;
    } else if (precision == Settings.PRECISION_MINUTE) {
        return Rez.Strings.PrecisionMinute;
    }
    return Rez.Strings.PrecisionHalfHour;
}

class PrecisionView extends WatchUi.Menu2 {
    function initialize(current as Number) {
        // Item order follows the PRECISION_* values so that :focus points at the current choice.
        Menu2.initialize({:title => Rez.Strings.Precision, :focus => current});
        addItem(new WatchUi.MenuItem(Rez.Strings.PrecisionHalfHour, null, Settings.PRECISION_HALF_HOUR, null));
        addItem(new WatchUi.MenuItem(Rez.Strings.PrecisionHour, null, Settings.PRECISION_HOUR, null));
        addItem(new WatchUi.MenuItem(Rez.Strings.PrecisionMinute, null, Settings.PRECISION_MINUTE, null));
    }
}

class PrecisionDelegate extends WatchUi.Menu2InputDelegate {
    var settings as Settings;

    function initialize(model as Settings) {
        Menu2InputDelegate.initialize();
        settings = model;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        settings.setPrecision(item.getId() as Number);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
