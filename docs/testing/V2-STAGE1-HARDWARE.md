# ShiftSense V2 – Hardwareabnahme Stufe 1

Datum: 2026-09-22
Geraet: Garmin Venu 2 Plus
App-Branch: `codex/rebuild-v2`
Build-Commit: `ddcc53a`
PRG SHA-256: `ACC31E6C5AE7C082C58BACE7AC4D712AF4A3FDAE213709BAB185CBCEFB6ED315`

## Bestaetigte Ergebnisse

| Pruefpunkt | Ergebnis | Quelle |
| --- | --- | --- |
| Nativer Garmin-Startdialog | Erfolgreich | Nutzer-Rueckmeldung zum vorherigen V2-Build |
| Wechsel in Live-UI und laufende Aufnahme | Erfolgreich | Nutzer-Rueckmeldung zum vorherigen V2-Build |
| Aktuelle HR, Durchschnittspuls und HR-Zone als Zahlen | Erfolgreich | Nutzer-Rueckmeldung zum Build `ddcc53a` |
| Stop & Speichern | Erfolgreich | Nutzer-Rueckmeldung zum Build `ddcc53a` |
| Gespeicherte Aktivitaet auf der Uhr sichtbar | Erfolgreich | Nutzer-Rueckmeldung zum Build `ddcc53a` |

## Simulator und Build

- 17 von 17 Monkey-C-Tests bestanden.
- Signierter Venu-2-Plus-Release-Build erfolgreich.
- Die Tests umfassen den echten Garmin-Session-Ablauf `start -> stop -> save` im Simulator.

## Grenzen der Bestaetigung

- Der angezeigte HR-Sensor wurde nicht anhand einer Sensor-ID als Polar H10 identifiziert; Garmin stellt der App die aktive HR-Quelle bereit.
- Die Plausibilitaet von HR-Maximum und Zonengrenzen wurde nicht mit den Garmin-Profileinstellungen des Nutzers abgeglichen.
- FIT-Inhalte wurden noch nicht unabhaengig exportiert und auf CRC/Felder geprueft; bestaetigt ist die Sichtbarkeit der gespeicherten Aktivitaet auf der Uhr.
- Weitere Garmin-Modelle sind fuer V2 noch nicht physisch getestet.

## Nachtest des abgesicherten Builds

- Der nachfolgende Review-Build besteht 24 von 24 Simulator-Tests und wurde als signierte PRG-Datei erstellt.
- SHA-256 der lokalen PRG-Datei: `83FD7667DEDDA011186DACC19E4705FF54FA3093EAACFB010AAAF35187EA4FED`.
- Die Datei wurde am 2026-09-22 nach `GARMIN/APPS/ShiftSenseV2.prg` auf die verbundene Venu 2 Plus kopiert; die Geraeteansicht zeigt sie mit 119 KB an.
- Der Start dieses Review-Builds nach dem Trennen der Uhr und die neuen Ausnahmewege (Stop-/Save-Fehler, Sensorstart-Fehler, Verwerfen) sind auf Hardware noch nicht bestaetigt.
