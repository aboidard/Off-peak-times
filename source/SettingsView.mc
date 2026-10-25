import Toybox.Lang;
import Toybox.WatchUi;
 
class SettingsView extends WatchUi.Menu2 {
    var settings as Settings;
    var itemCount as Number;

    function initialize() {
        Menu2.initialize({:title => Rez.Strings.Settings});
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

        addItem(new WatchUi.MenuItem(Rez.Strings.Precision,
                                     precisionLabel(settings.getPrecision()), :precision, null));
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
        // L'ordre des éléments suit les valeurs PRECISION_* pour que :focus pointe sur le choix actuel.
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
