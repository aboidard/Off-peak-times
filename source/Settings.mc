import Toybox.Application;
import Toybox.Lang;

(:glance)
class Settings {
    static const KEY_PERIOD_COUNT = "period_count_v2";
    static const KEY_PERIOD_1_START = "p1_start";
    static const KEY_PERIOD_1_END = "p1_end";
    static const KEY_PERIOD_2_START = "p2_start";
    static const KEY_PERIOD_2_END = "p2_end";
    static const MAX_PERIODS = 8;
    
    // Valeurs par défaut: 1:10-6:10 et 14:10-17:10
    static const DEFAULT_P1_START = 70;
    static const DEFAULT_P1_END = 370;
    static const DEFAULT_P2_START = 850;
    static const DEFAULT_P2_END = 1030;
    
    function initialize() {
    }
    
    function periodStorageKey(index as Number, endpoint as String) as String {
        return "period_" + index.toString() + "_" + endpoint;
    }

    function storedMinute(key as String, defaultValue as Number) as Number {
        var value = Application.Storage.getValue(key);
        if (value instanceof Number) {
            var minute = value as Number;
            if (minute >= 0 and minute < 24 * 60) {
                return minute;
            }
        }
        return defaultValue;
    }

    function getPeriods() as Array<Array<Number>> {
        var store = Application.Storage;
        var count = store.getValue(KEY_PERIOD_COUNT);
        var periods = [];

        if (count == null) {
            periods.add([
                storedMinute(KEY_PERIOD_1_START, DEFAULT_P1_START),
                storedMinute(KEY_PERIOD_1_END, DEFAULT_P1_END)
            ]);
            periods.add([
                storedMinute(KEY_PERIOD_2_START, DEFAULT_P2_START),
                storedMinute(KEY_PERIOD_2_END, DEFAULT_P2_END)
            ]);
            savePeriods(periods);
            return periods;
        }

        var periodCount = count as Number;
        if (periodCount < 0 or periodCount > MAX_PERIODS) {
            savePeriods(periods);
            return periods;
        }

        for (var index = 0; index < periodCount; index += 1) {
            var startMinute = storedMinute(periodStorageKey(index, "start"), DEFAULT_P1_START);
            var endMinute = storedMinute(periodStorageKey(index, "end"), DEFAULT_P1_END);
            periods.add([startMinute, endMinute]);
        }

        return periods;
    }

    function getHeuresCreauses() as Array<Array<Number>> {
        return getPeriods();
    }

    function savePeriods(periods as Array<Array<Number>>) as Void {
        var periodCount = periods.size();
        if (periodCount > MAX_PERIODS) {
            periodCount = MAX_PERIODS;
        }

        for (var index = 0; index < periodCount; index += 1) {
            var period = periods[index];
            var startMinute = period[0];
            var endMinute = period[1];
            Application.Storage.setValue(periodStorageKey(index, "start"), startMinute);
            Application.Storage.setValue(periodStorageKey(index, "end"), endMinute);
        }

        Application.Storage.setValue(KEY_PERIOD_COUNT, periodCount);
    }

    function setPeriod(index as Number, startMinute as Number, endMinute as Number) as Void {
        var periods = getPeriods();
        if (index < 0 or index >= MAX_PERIODS or
            startMinute < 0 or startMinute >= 24 * 60 or
            endMinute < 0 or endMinute >= 24 * 60) {
            return;
        }
        while (periods.size() <= index) {
            periods.add([startMinute, endMinute]);
        }
        periods[index] = [startMinute, endMinute];
        savePeriods(periods);
    }

    function removePeriod(index as Number) as Void {
        var periods = getPeriods();
        if (index < 0 or index >= periods.size()) {
            return;
        }
        var remainingPeriods = [];
        for (var currentIndex = 0; currentIndex < periods.size(); currentIndex += 1) {
            if (currentIndex != index) {
                remainingPeriods.add(periods[currentIndex]);
            }
        }
        savePeriods(remainingPeriods);
    }

    function setPeriod1(startMin as Number, endMin as Number) as Void {
        setPeriod(0, startMin, endMin);
    }

    function setPeriod2(startMin as Number, endMin as Number) as Void {
        setPeriod(1, startMin, endMin);
    }

    function minutesToTimeString(minutes as Number) as String {
        var h = minutes / 60;
        var m = minutes % 60;
        var hourText = h < 10 ? "0" + h.toString() : h.toString();
        var minuteText = m < 10 ? "0" + m.toString() : m.toString();
        return hourText + ":" + minuteText;
    }
    
    function timeStringToMinutes(hour as Number, minute as Number) as Number {
        return hour * 60 + minute;
    }
}
