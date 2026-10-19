# 20–30-m-Bewegungs- und Distanztest

Stand: 2026-10-13

Zweck: lokale Validierung der heuristischen Anschub-/Distanzschätzung von ShiftSense auf der Venu 2 Plus.

Dieses Protokoll mit mindestens fünf gültigen Wiederholungen je Bedingung
dient der persönlichen Distanzprüfung. Es ist kein Kalibrierungsmodul und
ändert keine App-Parameter. Auch `profile_status: eligible`
ist keine Freigabe eines populationsweiten Höhenmodells. Dafür gelten die
spielergruppengetrennten Kriterien in
[`player-profile-distance-validation.md`](player-profile-distance-validation.md);
der normale Build bleibt bis zu deren Erfüllung bei `:fixed`.

## Sicherheits- und Messgrenze

Die Uhr liefert hier **keine GPS-Distanz**. `estimated_distance_cm` ist ein experimenteller Modellwert aus Bewegungsmerkmalen und Anschüben. Eine hohe Sensorabdeckung beweist keine hohe Distanzgenauigkeit. Die Ergebnisse gelten zunächst nur für die getestete Person, Uhrposition und Bewegungsart.

Die Beta `0.2.0-beta.4` verwendet als dokumentierte Ausgangsbasis die bereits
vorliegende persönliche Testrelation `220/292,5`. Sie wird als zweite, lokale
Schicht nach dem evidenzbegrenzten Höhenmodell angewandt. Sie ist keine
Populationsaussage und wird weder automatisch aus neuen Läufen geschrieben
noch für andere Nutzer aktiviert. Für diesen Test gibt es kein GPS, keinen
Upload und kein globales Training.

## Ablauf vor dem Training

Im Testbuild wird vor **jedem** Training eine eigene kurze Testaufzeichnung
über den normalen Start- und Shift-Ablauf angelegt. Der Ready-Bildschirm hat
dafür keinen separaten Eintrag `Kalibrierung`: Eine echte Kalibrierung wird
später als eigenständiges Modul entworfen und validiert.

1. Eine gerade, klar markierte Strecke von mindestens 20 m und höchstens 30 m auswählen und mit Maßband oder Hallenmarkierung bestimmen.
2. Pro Versuch Start und Ende der Strecke unabhängig markieren (zweite Person, Video oder sichtbare Markierung). Die Distanz nicht aus der Uhr ablesen.
3. ShiftSense starten und die Live-Seite mit den Bewegungswerten öffnen. Falls Anschübe oder Distanz als `--` erscheinen, den Versuch trotzdem durchführen und die fehlende Abdeckung notieren.
4. Für jede Sportumgebung zwei getrennte Testbedingungen durchführen: **A = normales Skating ohne Puck** und **B = Skating mit Puck und Stickhandling**. Vor jedem Training sind mindestens fünf Wiederholungen je Bedingung erforderlich (also mindestens zehn pro Testaufzeichnung). Nicht zwischen den Sportarten mischen.
5. Für **jede** Wiederholung die untere Taste am Start drücken (Shift starten) und am Ende erneut (Shift beenden). Zwischen den Wiederholungen kurz auf die Bank zurückkehren. Die Reihenfolge der vollständigen manuellen Shifts muss der Reihenfolge im CSV-Protokoll entsprechen.
6. Bewegungsform und Bedingung je Versuch notieren: `A: normales Skating ohne Puck` oder `B: Puck und Stickhandling`, zusätzlich `Antritt`, `Gleitphase` oder `Richtungswechsel`. Für die erste Distanzprüfung möglichst gerade Antritte priorisieren.
7. Anschübe möglichst unabhängig zählen (zweite Person oder Video). Wenn das nicht möglich ist, `reference_pushes` leer lassen. Die Uhranzeige darf nicht als Referenzzählung verwendet werden.
8. Während jedes Shifts die geschätzte Shift-Distanz und nach dem Shift die
   fortlaufende Gesamtdistanz mit `≈` notieren. Aufnahme mit der oberen Taste
   stoppen und speichern. Original-FIT anschließend lokal unter
   `analysis/private/` ablegen und niemals committen.

## Protokollvorlage

| Versuch | Bedingung | Sport | Referenzstrecke m | Bewegungsform | Referenz-Anschübe | Uhr-Anschübe | Uhr-Distanz m | Sensorabdeckung % | Start-/Endmarker korrekt? | Notiz |
|---:|---|---:|---|---:|---:|---:|---:|---|---|
| 1 | A/B | Inline/Eis |  | Antritt/Gleitphase/Richtungswechsel |  |  |  |  | ja/nein |  |
| 2 | A/B | Inline/Eis |  |  |  |  |  |  |  |  |
| 3 | A/B | Inline/Eis |  |  |  |  |  |  |  |  |  |
| 4 | A/B | Inline/Eis |  |  |  |  |  |  |  |  |  |
| 5 | A/B | Inline/Eis |  |  |  |  |  |  |  |  |  |

**Bedingung A:** normales Skating ohne Puck, möglichst gleiche Strecke und ähnliches Tempo.  
**Bedingung B:** gleicher Ablauf mit Puck und aktivem Stickhandling.  
Die Bedingungen werden nicht zu einem gemeinsamen Distanztest-Mittelwert vermischt: Stickhandling kann die Gyroskopie, Anschuberkennung und Gleit-/Anschubverteilung verändern. Berichtet werden jeweils Median und Streuung für A und B sowie der Unterschied `B − A`.

Die Spalten `Uhr-Anschübe`, `Uhr-Distanz` und `Sensorabdeckung` werden nach dem FIT-Export aus dem passenden manuellen Shift-Lap beziehungsweise der lokalen Auswertung übernommen. Ein fehlender FIT-Wert bleibt leer/`nicht verfügbar`; er wird nicht als `0` interpretiert.

## Berechnung

Für jeden gültigen Versuch:

- Distanzfehler (m) = `Uhr-Distanz − Referenzstrecke`
- Absoluter Fehler (m) = `abs(Distanzfehler)`
- Prozentfehler = `100 × Distanzfehler / Referenzstrecke`
- Anschubfehler = `Uhr-Anschübe − Referenz-Anschübe`, **nur** wenn eine unabhängige Referenzzählung vorliegt. Sonst bleibt der Fehler unbekannt, während die Distanzbewertung möglich bleibt.

Zusammengefasst werden Median, Mittelwert, Minimum/Maximum und 95%-Perzentil des absoluten Distanzfehlers sowie der Median des Prozentfehlers berichtet. Zusätzlich werden Anschubzählfehler und fehlende Werte separat berichtet. Eine einzelne gute Wiederholung reicht nicht für eine Freigabe oder Modelländerung.

## Qualitätsregeln

- Nur Versuche mit vollständigem manuellem Start- und Endmarker kommen in die primäre Distanzbewertung.
- Verspätete, doppelte oder vergessene Marker werden markiert und nur in einer Sensitivitätsanalyse berücksichtigt.
- Versuche mit unbekannter oder 0-%-Sensorabdeckung, `--`-Distanz oder ungültiger FIT-Lap bleiben für die Distanzgenauigkeit unbewertet.
- Die `session_id` im Distanztestprotokoll muss dem Startzeitpunkt der tatsächlich ausgewerteten FIT-Sitzung entsprechen. Eine andere Sitzung wird abgewiesen; Zeitzonenunterschiede werden berücksichtigt.
- Inline und Eis werden getrennt zusammengefasst; Bedingung A und B werden getrennt ausgewertet. Antritt und Gleitphase werden nicht ungeprüft zu einer gemeinsamen Distanzbewertung vermischt.
- Die aktuellen Modellannahmen (kurze Antritte etwa 1,25 m, spätere Anschübe etwa 2,25 m) sind Startwerte, keine wissenschaftlich bestätigten individuellen Parameter.

## Korrigierte Referenz vom 13. Oktober 2026

Der am 13. Oktober 2026 aufgezeichnete Referenzlauf hatte pro Wiederholung
eine unabhängig bestimmte Strecke von **20 m (2.000 cm)**. Im lokalen
Kalibrierungsmanifest muss daher `reference_distance_cm=2000` stehen. Die
Uhrschätzung bleibt ein separater Messwert; diese Korrektur ändert weder
Modellparameter noch den persönlichen Testfaktor und aktiviert keine
automatische Kalibrierung.

## Lokale Auswertung nach dem Test

Im Projektordner ausführen:

```text
python -m analysis.shift_pilot analysis/private/<datei>.fit
```

Für eine manuelle Grenzreferenz kann zusätzlich eine CSV mit `elapsed_ms,state` verwendet werden:

```text
python -m analysis.shift_pilot analysis/private/<datei>.fit --reference analysis/private/<datei>-reference.csv
```

Für die Distanzprüfung zuerst den Sitzungsbeginn aus genau dieser FIT-Datei auslesen (Original-FIT bleibt lokal):

```text
python -c "from analysis.shift_pilot import load_pilot_fit; print(load_pilot_fit('analysis/private/<datei>.fit')['session_start'])"
```

Die ausgegebene Zeit als `session_id` in jeder Zeile des lokalen CSV-Protokolls verwenden. Die Spalte `reference_pushes` bleibt vorhanden, ihr Wert darf aber leer sein. `repetition` zählt die **manuellen Shifts in dieser Aufnahme** ab 1, auch wenn ein Versuch als `uncertain` ausgeschlossen werden muss. Beispiel für einen 20-m-Versuch ohne unabhängige Anschubzählung:

```csv
session_id,repetition,sport,condition,reference_distance_cm,reference_pushes,marker_status
2026-10-13 10:30:00+00:00,1,inline,skate_only,2000,,valid
```

Dann den Vergleich lokal starten. `--calibration-manifest` und die Dateinamen
mit `calibration` sind bestehende interne CLI-Bezeichnungen; sie bedeuten
nicht, dass die App ein Kalibrierungsmodul ausführt oder Parameter ändert:

```text
python -m analysis.shift_pilot analysis/private/<datei>.fit --calibration-manifest analysis/private/<datei>-calibration.csv --output analysis/private/<datei>-calibration-report.json
```

Das Datum im Beispiel ist **nur ein Platzhalter**; die echte `session_id` muss aus der FIT-Datei kommen. Der Bericht enthält getrennte Gruppen für `inline/skate_only` und `inline/puck_stickhandling`. Eine gültige Distanzbewertung ohne Anschubzählung ist **keine** Validierung der Anschuberkennung.

Die Ausgabe wird nur lokal gespeichert. `profile_status: eligible` wird erst vergeben, wenn **beide** Bedingungen der protokollierten Sportart je mindestens fünf gültige Wiederholungen haben. Das ist nur eine Mindest-Datenmenge für die spätere Prüfung, **keine** Freigabe der Distanzgenauigkeit. Vor einer nächsten Anpassung der Uhr-App werden die Roh-FIT-Datei, die Tabelle oben und die Unsicherheiten gemeinsam geprüft.

## Entscheidung nach fünf Wiederholungen

Die Distanzanzeige bleibt zunächst als **experimentelle Schätzung** gekennzeichnet. Eine Anpassung der Modellparameter wird erst vorgeschlagen, wenn mindestens fünf gültige Wiederholungen je Bedingung (A ohne Puck, B mit Puck/Stickhandling) und Sportumgebung vorliegen und die Referenzstrecke unabhängig bestimmt wurde. Eine automatische Live-Distanz oder automatische Shift-Zählung wird aus diesem kurzen Test allein nicht freigegeben.
