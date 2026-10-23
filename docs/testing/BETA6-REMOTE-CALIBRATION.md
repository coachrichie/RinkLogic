# RinkLogic Beta 6 – Remote-Kalibrierung

Stand: 23. Oktober 2026. Diese Anleitung gilt ausschließlich für freigegebene
volljährige Pilot-Tester mit Garmin Venu 2 Plus (`venu2plus`). Andere Geräte
werden erst nach Eintrag in der Device Matrix freigegeben.

## Vor dem Test

1. Tester-ID, Uhrmodell, Firmware und Einwilligungsversion notieren.
2. SHA-256 der gerätespezifischen Datei mit der Release-Tabelle vergleichen.
3. Nur die Datei für die eigene Garmin-Produkt-ID installieren. Das Paket muss
   mit demselben RinkLogic-Schlüsselpaar wie die vorherige Store-Version
   signiert sein.
4. Eine gerade Strecke von 20, 22, 25 oder 30 m unabhängig vermessen.
5. Referenzformular aus `beta6-calibration-reference.csv` privat kopieren;
   keine reale Testerdatei im Repository bearbeiten oder committen.

## Bedienung und Kalibrierung

- Ready: untere Taste startet normales Training; obere Taste öffnet
  `KALIBRIERUNG` / `EXIT`.
- Menü: obere Taste wechselt, untere bestätigt; Touch wählt direkt.
- Kalibrierung: Eis/Inline und vermessene Distanz wählen. Die Uhr fordert je
  fünf Läufe ohne und mit Stickhandling an, jeweils `langsam, schnell, normal,
  langsam, schnell`.
- Ungültige Läufe werden mit derselben Vorgabe wiederholt. Auch verworfene
  technische FIT-Laps erhalten im Formular eine Zeile; genau zehn Zeilen
  werden als `valid` markiert.
- Erst nach gültiger Qualitätsprüfung `AKTIVIEREN` wählen. `VERWERFEN` löscht
  die offene Kalibrierung und lässt das bisherige Profil unverändert.

## Nach dem Test

Garmin Connect synchronisieren und `Export Original` verwenden. Privat senden:

1. unveränderten ZIP-/FIT-Originalexport;
2. ausgefülltes CSV-Referenzformular;
3. optionales Video nur mit separater Einwilligung.

Die App besitzt keinen Cloud-Upload. Reale FITs und Formulare dürfen nicht in
GitHub, öffentliche Drive-Ordner oder öffentliche Chats. Der vereinbarte Weg
ist ein privater Upload-only-Link oder ein individuell verschlüsselter Kanal.

## Abnahme und Rollback

Prüfen: kein `IQ!`, HR sichtbar, normales Shift-Markieren/Speichern intakt,
alle RinkLogic-Zeiten in Minuten, Kalibrierfaktor nach Neustart sichtbar und
Schema 12 mit Feld 115 exportierbar. Garmins natives `total_distance` kann
trotz RinkLogic-Distanz weiterhin `0,0` anzeigen; maßgeblich sind die
RinkLogic-Developer-Felder.

Bei Absturz, nicht speicherbarer Aktivität, falscher Tastenbelegung oder
beschädigtem Profil Test abbrechen, Originaldateien privat sichern und die
zuletzt bestätigte Beta 4 wieder installieren. Ein Rollback entfernt nicht
automatisch Garmin-Connect-Aktivitäten; diese werden dort separat verwaltet.
