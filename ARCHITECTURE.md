# Architektur

ShiftSense Hockey trennt die Aufzeichnung auf der Uhr von lokaler Analyse und
Hardwareabnahme. Garmin bleibt Autorität für die eigentliche Aktivität; die App
ergänzt manuelle Hockeygrenzen und abgeleitete Felder.

## Systemgrenzen

### Watch V2

`watch-v2/` ist die aktuelle Venu-2-Plus-App. `RecordingCoordinator` steuert
Start, Stop, Speichern und Fehlerzustände. `ShiftEventLedger` hält manuell
bestätigte Eis-/Bankgrenzen. `SessionAnalytics` berechnet die
Post-Training-Werte aus monotoner Sitzungszeit, gültigen HR-Samples und diesen
manuellen Grenzen. `ShadowFitWriter` schreibt die zusätzlichen Session- und
Lap-Felder in Garmins FIT-Aufzeichnung.

Manuelle Eingaben sind die Autorität für veröffentlichte Shift-Statistiken.
Automatische Vorschläge bleiben ein separater experimenteller Shadow-Pfad und
ändern keine bestätigten Shiftgrenzen.

### Watch V1

`watch/` bewahrt die frühere Implementierung und ihre Regressionstests. Sie ist
nicht die Basis neuer V2-Funktionen und darf nicht stillschweigend mit dem
aktuellen Geräteverhalten gleichgesetzt werden.

### Lokale Analyse

`analysis/` dekodiert FIT-Dateien für Pilot- und Kalibrierungsberichte. Diese
Werkzeuge laufen lokal; persönliche Eingaben und Ergebnisse bleiben unter
`analysis/private/`. Das gemeinsame Schema in `shared/schema/` beschreibt die
Feldbedeutung, ersetzt aber keine Prüfung der realen Garmin-Connect-Anzeige.

## Datenfluss

1. Garmin liefert Zeit-, HR-, Profil- und verfügbare Sensordaten.
2. Der Nutzer markiert Shiftbeginn und Shiftende auf der Uhr.
3. V2 aggregiert Liveanzeige, Shift-Laps und Session-Zusammenfassung.
4. Garmin speichert die Aktivität zusammen mit den FitContributor-Feldern.
5. Garmin Connect synchronisiert die Aktivität; die konkrete Darstellung wird
   separat auf Mobile und Web geprüft.
6. Exportierte FIT-Dateien können lokal analysiert werden, ohne Rohdaten in Git
   zu übernehmen.

## Fehler- und Fehlwertregeln

- Aufnahme und manuelle Shifts bleiben unabhängig von experimenteller
  Bewegungsauswertung.
- Fehlende oder unzulässige Werte werden als unbekannt geschrieben, nicht als
  scheinbar gemessene Null.
- Erst erfolgreiches Garmin-Speichern öffnet die Post-Training-Anzeige.
- Simulator, signierter Build, Installation, Uhrtest, Connect-Synchronisation
  und FIT-Dekodierung sind getrennte Nachweise.

## Vertiefung

- [`docs/PROJECT-MAP.md`](docs/PROJECT-MAP.md)
- [`docs/data/FIT-SCHEMA.md`](docs/data/FIT-SCHEMA.md)
- [`docs/data/HOCKEY-EVIDENCE-AUDIT-2026-09-28.md`](docs/data/HOCKEY-EVIDENCE-AUDIT-2026-09-28.md)
- [`docs/testing/V2-POST-TRAINING-SUMMARY.md`](docs/testing/V2-POST-TRAINING-SUMMARY.md)
