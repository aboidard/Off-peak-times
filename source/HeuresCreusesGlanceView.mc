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
    
    function isHeuresCreuses(minutes as Number) as Boolean {
        var periods = settings.getPeriods();
        for (var index = 0; index < periods.size(); index += 1) {
            var startMinute = periods[index][0];
            var endMinute = periods[index][1];
            if (startMinute == endMinute or
                (startMinute < endMinute and minutes >= startMinute and minutes < endMinute) or
                (startMinute > endMinute and (minutes >= startMinute or minutes < endMinute))) {
                return true;
            }
        }
        return false;
    }
    
    function minutesUntilNextHeuresCreuses(nowMinutes as Number) as Number {
        var periods = settings.getPeriods();
        if (periods.size() == 0 or isHeuresCreuses(nowMinutes)) {
            return 0;
        }

        var shortestDelay = 24 * 60;
        for (var index = 0; index < periods.size(); index += 1) {
            var delay = periods[index][0] - nowMinutes;
            if (delay < 0) {
                delay += 24 * 60;
            }
            if (delay < shortestDelay) {
                shortestDelay = delay;
            }
        }
        return shortestDelay;
    }
    
    function roundUpToHalfHour(minutes as Number) as Number {
        var half = 30;
        var remainder = minutes % half;
        if (remainder == 0) {
            return minutes;
        }
        return minutes + (half - remainder);
    }

    function isFrench() as Boolean {
        return System.getDeviceSettings().systemLanguage == System.LANGUAGE_FRE;
    }

    function onUpdate(dc as Dc) as Void {
        var width  = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.clear();

        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var nowMinutes = info.hour * 60 + info.min;

        // --- Texte statut ---
        var text;
        var periods = settings.getPeriods();
        if (periods.size() == 0) {
            text = isFrench() ? "Aucune période configurée" : "No periods configured";
        } else if (isHeuresCreuses(nowMinutes)) {
            text = isFrench() ? "Heures creuses en cours" : "Off-peak hours active";
        } else {
            var minutesLeft = minutesUntilNextHeuresCreuses(nowMinutes);
            var minutesRounded = roundUpToHalfHour(minutesLeft);
            var h = minutesRounded / 60;
            var m = minutesRounded % 60;
            var nextPrefix = isFrench() ?
                "Prochaine période d'heures creuses dans " : "Next off-peak period in ";
            var hourSuffix = isFrench() ? " h " : "h";
            text = nextPrefix + h.toString() + hourSuffix +
                   ((m == 0) ? "" : (m < 10 ? "0" : "") + m.toString());
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2,
            height / 2 - 18,
            Graphics.FONT_XTINY,
            text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // --- Barre temporelle ---
        // La barre représente 24h, centrée sur "now"
        // nowMinutes correspond au centre de la barre (width/2)
        var barY      = height / 2 + 10;
        var barHeight = 3;
        var hcHeight  = 7;

        // Conversion minutes -> pixels
        // La barre affiche une fenêtre de 24h (1440 min) sur toute la largeur
        var totalMinutes = 1440;
        var pixelsPerMinute = width.toFloat() / totalMinutes.toFloat();

        // Origine en pixels : le pixel 0 correspond à (nowMinutes - 720) minutes
        var windowStart = nowMinutes - 720; // 720 = 1440/2

        // Dessine la ligne de base (gris)
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, barY - barHeight / 2, width, barHeight);

        // Plages HC configurées
        // On les dessine aussi pour le jour suivant (+1440) pour couvrir le bord droit
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

            // Clamp à la largeur de l'écran
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

        // Curseur "now" : trait vertical blanc au centre
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(width / 2 - 1, barY - 10, 2, 20);
    }
}