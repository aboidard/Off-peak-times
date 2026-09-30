import Toybox.Lang;
import Toybox.WatchUi;
 
class SettingsView extends WatchUi.Menu2 {
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
