# ShiftSense Hockey – kurzer Gerätetest

## Installationsdatei

Die signierte Venu-2-Plus-Datei liegt nach dem Build hier:

`watch/bin/venu2plus/ShiftSense.prg`

Die Version vom 17.09.2026 enthält die überarbeitete Touch-Steuerung und die zwei Live-Seiten. Vor der Installation den Hash der tatsächlich verwendeten Datei mit `Get-FileHash watch\bin\venu2plus\ShiftSense.prg -Algorithm SHA256` prüfen; ein neuer Build kann einen neuen Hash erzeugen.

## Minimaler Test auf einer Venu 2 Plus

1. Uhr per USB verbinden und die PRG-Datei in `GARMIN/APPS/` der Uhr kopieren. Eine ältere ShiftSense-Datei mit derselben App-ID wird dabei ersetzt.
2. Uhr sicher trennen, **ShiftSense Hockey** öffnen. Im Spielerprofil zuerst die Zeile **Alter** oder **HF max** antippen; die aktive Zeile ist blau. **− / +** ändern den Wert, ebenso Wischen. **Auto** in der HF-Zeile löscht die getestete HF max und stellt Garmin-HF-max beziehungsweise den altersbasierten Ersatz wieder her. Nur **Weiter** öffnet die Moduswahl. Tastenbedienung: Auswählen wechselt Alter → HF max → Weiter; Hoch/Runter ändert das gewählte Feld; Zurück bei gewählter HF max entspricht Auto. Auswählen bei Weiter öffnet die Moduswahl.
3. **Eishockey**, **Inline Halle** oder **Inline draußen** antippen, danach den separaten Button **Start**, danach den Startdialog bestätigen. Ein Tap auf einen Modus darf noch keine Aufzeichnung starten. Die Alpha aktiviert weiterhin kein GPS.
4. Auf der Leistungsseite müssen **REC**, die jede Sekunde laufende Dauer, HR, Zone/%HFmax, Ø HF, Shifts und Eiszeit sichtbar sein. HR ohne Signal wird als `--` dargestellt. **BANK → Aufs Eis** setzt einen Shiftmarker; **EIS → Zur Bank** setzt den Rückwechsel. Nur Bank → Eis erhöht die Shiftanzahl. Bei 10 Sekunden auf dem Eis muss die Eiszeit etwa 00:10 betragen.
5. Über **Events >** zur zweiten Seite wechseln. **Hits**, **Pässe** und **Schüsse** sind manuelle Zähler: jeweils ein Tap auf die betreffende Zeile zählt eins hoch. Andere Bildschirmbereiche dürfen weder zählen noch einen Shift auslösen. Mit **Leistung >** zurück. Tastenbedienung: Hoch/Runter auf Leistung öffnet Events; auf Events wandert die blaue Auswahl durch Hits, Pässe, Schüsse, Shiftmarker, Seitenwechsel. Auswählen führt ausschließlich die hervorgehobene Aktion aus; Menü wechselt direkt die Seite. Zurück öffnet auf beiden Seiten den Stoppdialog.
6. **Stopp** oder Zurück drücken, den Dialog bestätigen und die Zusammenfassung prüfen. Beim Abbrechen muss die Aufzeichnung mit weiterlaufender Zeit fortgesetzt werden. Dauer, Wechsel und Eiszeit müssen plausibel sein.
7. In Garmin Connect kontrollieren, dass eine neue Aktivität gespeichert wurde. Die App verwendet Garmins generische Aktivitätsaufzeichnung mit Hockey-Entwicklerfeldern. FIT-Summary-IDs 32–34 enthalten die manuellen Hits/Pässe/Schüsse. Die Anzeige von Entwicklerfeldern bei lokal installierten Apps in Connect ist separat zu prüfen; die rohe FIT-Datei ist maßgeblich.
8. Beim Start und Ende der Aufnahme darf keine Fehlermeldung zur Herzfrequenz erscheinen, wenn kein Brustgurt verbunden ist. Die Einheit muss auch ohne HF-Signal speicherbar bleiben.

Für den späteren FIT-Decode prüfen: Schon eine markerlose Einheit enthält den initialen Bankstatus sowie Schema und Modus. Ein fehlgeschlagener Marker darf keinen zusätzlichen Lap, keinen zusätzlichen Wechsel und keine veränderten Shift-Index/-State/-Zeitstempelwerte hinterlassen.

## Save-Fehler kontrolliert behandeln (manueller Gate)

Wenn die Uhr beim Speichern einen Fehler zeigt, muss die sichtbare deutsche Fehleransicht „Speichern fehlgeschlagen“ anbieten. Auswählen versucht das Speichern derselben bereits gestoppten Einheit erneut. Zurück öffnet erst die Bestätigung „Einheit verwerfen?“; nur deren Bestätigung darf die Einheit verwerfen. Ein echter Speicherfehler konnte ohne Gerät/Simulator-Export nicht erzwungen werden und bleibt daher manuell offen.

## Zwei getrennte Herzfrequenzläufe

1. **Handgelenk:** Polar H10 ausschalten oder in der Uhr unter Sensoren trennen; eine kurze Aufnahme wie oben speichern.
2. **Polar H10:** Den Brustgurt anlegen, in der Uhr unter Sensoren als Herzfrequenzsensor verbinden, den Sensorstatus abwarten und eine getrennte kurze Aufnahme speichern.
3. In Garmin Connect beide Aktivitäten auf vorhandene Herzfrequenzkurven und gespeicherte Aktivität prüfen; Zeit, Sensorstatus und eventuelle Aussetzer notieren.

Die Herkunft der Standard-Herzfrequenz wird von Garmin entschieden. Die App fordert den dokumentierten Herzfrequenzsensor an, kann aber den gewählten H10 nicht selbst beweisen. Eine Auswertung darf deshalb bei diesem Alpha-Test noch nicht behaupten, einen Polar-H10-Lauf anhand eines eigenen `hr_source`-Feldes verifiziert zu haben.

## Falls Start weiterhin fehlschlägt

Die Anzeige nennt jetzt einen Code: `CREATE` (Garmin-Sitzung), `FIELD:<ID>` (Pflichtfeld), `INIT` (Anfangswerte) oder `START` (Garmin-Start). Den kompletten Code und die Firmwareversion notieren. Zurück führt zur Moduswahl für einen erneuten Versuch. Es gibt keine belegte pauschale 16-Feld-Grenze: im Venu-2-Plus-Simulator starteten zunächst 31 und danach 34 Felder erfolgreich.

Nach dem Versuch per USB verbinden und vorhandene Dateien aus `GARMIN/APPS/LOGS/` in einen lokalen Diagnoseordner kopieren, besonders `CIQ_LOG.YML`, `CIQ_LOG.TXT` und ggf. `SHIFTSENSE.TXT`; Dateinamen variieren nach Firmware. Keine Logs löschen. Falls keine App-Ausgaben vorhanden sind, vor einem weiteren Versuch eine leere Datei `SHIFTSENSE.TXT` unter `GARMIN/APPS/LOGS/` anlegen (Basisname muss der installierten PRG entsprechen). Die App protokolliert Fehlerstufe und Feld-ID über Garmins `System.println`. Logs vor einer öffentlichen Weitergabe auf persönliche Daten prüfen.

## Bedeutung der Live-Werte

HF-Zonen sind feste Prozentbereiche der im Spielerprofil aufgelösten HF max: Z0 &lt;50 %, Z1 50–&lt;60 %, Z2 60–&lt;70 %, Z3 70–&lt;80 %, Z4 80–&lt;90 %, Z5 ≥90 %. Das ist eine transparente Alpha-Konvention, keine individualisierte sportmedizinische Zonenbestimmung. Ø HF ist der arithmetische Mittelwert gültiger 1-Hz-Sensor.Info-Werte seit Aufnahmebeginn; fehlende Werte werden nicht als Null gemittelt. Nach mehr als fünf Sekunden ohne aktuellen HF-Wert verschwinden aktuelle HR und Zone, während der bisherige Mittelwert erhalten bleibt. Hits/Pässe/Schüsse sind ausdrücklich manuelle Eingaben und keine bereits validierte automatische Erkennung.
