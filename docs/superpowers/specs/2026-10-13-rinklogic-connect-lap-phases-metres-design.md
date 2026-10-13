# RinkLogic: Connect-Lap-Phasen und Distanz in Metern

## Ziel

Die nächste Testversion nach `0.2.0-beta.4` soll die Befunde des Feldtests vom
13. Oktober 2026 beheben, ohne die bereits hochgeladene Beta 4 oder vorhandene
FIT-Dateien umzudeuten:

1. Garmin Connect zeigt jeden manuell abgegrenzten Zeitabschnitt eindeutig als
   `On-Ice` oder `Bench` an.
2. Geschätzte Distanz wird in den Connect-IQ-Charts und der Lap-Tabelle in
   Metern statt Zentimetern angezeigt.
3. Die geschätzte Gesamtdistanz bleibt im Connect-IQ-Aktivitätsabschnitt
   sichtbar und wird nicht fälschlich als Bestandteil der nativen Garmin-
   Overview versprochen.
4. Der aufgezeichnete Referenzlauf wird mit 20 m je Wiederholung ausgewertet.

Die Änderung bleibt experimentell. Sie validiert weder die Distanzgenauigkeit
noch eine biologische Distanz-pro-Anschub-Gleichung.

## Plattformgrenze

Connect-IQ-Developer-Felder können Garmins native Overview-Karten für Distanz,
Geschwindigkeit oder Höhenmeter nicht ersetzen. RinkLogic zeigt die geschätzte
Gesamtdistanz deshalb im separaten Connect-IQ-Zusammenfassungsbereich. Ein
fehlender Wert in der nativen Overview ist keine durch das FIT-Contribution-
Schema behebbaren Darstellungslücke.

## Semantisches Lap-Modell

### Intervalle

Jede manuelle Umschaltung schließt genau ein semantisches Intervall:

- Wechsel von `On-Ice` zu `Bench`: ein `On-Ice`-Lap wird geschrieben.
- Wechsel von `Bench` zu `On-Ice`: ein `Bench`-Lap wird geschrieben.
- Speichern während `On-Ice`: der offene `On-Ice`-Lap wird einmal geschlossen.
- Speichern während `Bench`: der offene `Bench`-Lap wird einmal geschlossen.

Vor dem ersten manuell gestarteten Shift wird kein künstlicher Bench-Lap
erzeugt. Dadurch beginnt die Lap-Folge mit `On-Ice` und wechselt anschließend
streng zwischen `Bench` und `On-Ice`. Jeder Abschnitt enthält seine eigene
Dauer in Dezimalminuten.

### Phasenkennzeichnung

Ein neues Lap-Developer-Feld speichert die Phase als Textwert `On-Ice` oder
`Bench`. Die Connect-Lap-Tabelle erhält eine sichtbare Spalte `Phase`. Alte
numerische Grenzfelder bleiben für frühere Schema-Versionen lesbar, werden in
der neuen Version jedoch nicht als Ersatz für die Textkennzeichnung
umgedeutet.

Falls der Garmin-Simulator oder das Zielgerät ein String-Lap-Feld nicht
zuverlässig allokieren oder in Garmin Connect nicht darstellen kann, wird die
Version nicht veröffentlicht. Ein numerischer Code ohne unmittelbar sichtbare
Erklärung gilt nicht als Erfüllung der Anforderung.

### On-Ice- und Bench-Inhalte

On-Ice-Laps erhalten:

- Dauer in Minuten,
- durchschnittliche Shift-Herzfrequenz, sofern qualifiziert,
- erkannte Anschübe,
- geschätzte Shift-Distanz in Metern,
- Sensorabdeckung.

Bench-Laps erhalten:

- Dauer in Minuten,
- Phase `Bench`,
- keine erfundenen Anschub-, Distanz- oder Shift-HF-Werte.

Nicht anwendbare Werte werden als FIT-invalid geschrieben, niemals als Null.

## Recovery-Priorität

Zeitlich korrekte On-Ice-/Bench-Laps haben Vorrang vor den bisherigen
nachträglich vervollständigten Recovery-Feldern in derselben Connect-Lap-Zeile.
Garmin erlaubt keine nachträgliche Änderung eines bereits mit `addLap()`
geschriebenen Laps. Deshalb werden semantische Laps unmittelbar an der
manuellen Grenze gespeichert.

HR-Recovery nach 30 und 60 Sekunden bleibt Bestandteil der lokalen Analyse und
kann weiterhin aus Record-Daten berechnet werden. Die neue Version verspricht
keine zuverlässige Recovery-Anzeige in derselben Connect-Lap-Zeile. Alte
Recovery-Felder bleiben historisch lesbar und werden nicht umgedeutet.

## Distanzfelder in Metern

Die vorhandenen Felder 63 (`estimated_distance_cm_total`) und 66
(`shift_estimated_distance_cm`) behalten dauerhaft ihre Zentimeterbedeutung.
Die neue Schema-Version allokiert sie nicht mehr und führt neue `float32`-
Felder ein:

| Scope | Bedeutung | Typ | Einheit |
| --- | --- | --- | --- |
| Record | kumulierte geschätzte Gesamtdistanz | `float32` | `m` |
| Lap | geschätzte Distanz des On-Ice-Abschnitts | `float32` | `m` |
| Lap | Phase `On-Ice` oder `Bench` | `string` | – |

Die konkreten IDs werden bei der Implementierungsplanung aus dem nächsten
freien, appweit eindeutigen Bereich vergeben. Keine bestehende ID erhält eine
neue Einheit oder einen neuen Datentyp.

Record-, Lap- und Session-Distanz verwenden weiterhin ausschließlich den Wert
des `DistanceEstimator`. Die Anzeige rechnet Zentimeter einmalig durch 100 in
Meter um; keine Oberfläche berechnet eine eigene Distanz.

Die Session-Gesamtdistanz bleibt Feld 97 in Metern. Ihre Connect-Reihenfolge
bleibt hinter Anzahl Shifts, durchschnittlicher Shiftdauer und
durchschnittlicher Shift-Herzfrequenz. Chart und Lap-Tabelle verwenden eine
sinnvolle Meterpräzision von mindestens einer Nachkommastelle.

## Allokationsgrenze und Schema-Kompatibilität

Die Venu 2 Plus hat im Projekt eine aktive Grenze von 34 Developer-Feldern und
16 Session-Feldern gezeigt. Neue Felder dürfen diese Belegung nicht erhöhen.
Für jedes neue Feld wird deshalb ein nicht mehr benötigtes aktives Feld
stillgelegt; historische Registry-Einträge bleiben erhalten.

Die Implementierungsplanung muss vor Vergabe der IDs eine vollständige Tabelle
aller aktiven Record-, Lap- und Session-Felder erstellen. Bevorzugte Kandidaten
für die Stilllegung sind die alten cm-Felder und nicht mehr in Connect
angezeigte Recovery- beziehungsweise Diagnosefelder. Session-Felder werden
nicht erweitert.

Der lokale Parser liest weiterhin Schema 4 bis 9 und zusätzlich die neue
Version. Bei alten Dateien rechnet er cm-Felder nur für die Ausgabe in Meter
um. Neue Dateien schreiben ausschließlich die neuen Meter- und Phasenfelder.

## Korrigierte Referenzdistanz

Der am 13. Oktober 2026 aufgezeichnete Streckentest wird als 20-m-Test
behandelt. Pro Wiederholung werden Referenzdistanz, Bedingung, Markerqualität,
unabhängig gezählte Anschübe, Uhrschätzung und Sensorabdeckung getrennt
protokolliert.

Die Korrektur von 22 m auf 20 m ändert nicht automatisch die App-Konstanten
oder den persönlichen Testfaktor. Erst nach Export und Qualitätsprüfung der
Original-FIT-Datei darf ein neuer persönlicher Faktor als experimenteller
Kandidat berechnet werden. Er bleibt getrennt von der wissenschaftlich
informierten Basisschicht und wird niemals als Literaturkonstante bezeichnet.

## Fehler- und Rückfallverhalten

- Scheitert die vollständige Feldallokation, startet die Aufnahme nicht mit
  einem teilweise interpretierbaren Schema.
- Ein Lap wird pro manueller Grenze höchstens einmal geschrieben.
- Speichern schließt genau einen offenen Abschnitt und erzeugt keine doppelte
  Schlussrunde.
- Fehlende Bewegungssamples ergeben ungültige Distanzwerte statt Null.
- Bei `IQ!`, Speicherfehler, ungültiger FIT-Datei, nicht alternierenden Phasen
  oder fehlender Meterdarstellung wird auf Beta 4 zurückgefallen.
- Die bereits hochgeladene `0.2.0-beta.4` und ihr Portalstatus bleiben während
  Entwicklung und Test unverändert.

## Verifikation

Vor einem neuen Beta-Upload sind frisch nachzuweisen:

1. Simulator-Tests für streng alternierende `On-Ice`-/`Bench`-Laps,
   Start-/Endzustände, Speichern in beiden Phasen und keine Duplikate.
2. Tests, dass nur On-Ice-Laps Anschub-, Distanz- und Shift-HF-Werte erhalten.
3. Schema-Tests für eindeutige IDs, höchstens 34 aktive Developer-Felder und
   exakt 16 Session-Felder.
4. FIT-Tests für Meterwerte in Record, Lap und Session sowie FIT-invalid bei
   fehlenden Daten.
5. Parser-Regressionen für Schema 4 bis 9 und die neue Schema-Version.
6. Lokalisierungs- und Contribution-Tests für `Phase`, `On-Ice`, `Bench`,
   `Geschätzte Distanz`, `m` und die bestehende Summary-Reihenfolge.
7. Signierte normale und Test-Builds für `venu2plus`; die normale Release-
   Distanzkonfiguration bleibt unverändert.
8. Physischer Smoke-Test und eine kurze synchronisierte Aktivität, die in
   Garmin Connect Textphasen und Meterwerte tatsächlich sichtbar zeigt.
9. Export des Original-FITs mit gültiger CRC und erwarteten Felddefinitionen.

## Akzeptanzkriterien

Die Änderung ist abnahmefähig, wenn:

- Connect-Laps ab dem ersten Shift streng als `On-Ice`, `Bench`, `On-Ice`, …
  erkennbar sind,
- On-Ice- und Bench-Dauern plausibel in Minuten erscheinen,
- Chart, On-Ice-Laps und Connect-IQ-Summary Distanz in Metern darstellen,
- Record-, Lap- und Session-Distanz aus demselben Schätzpfad stammen,
- die native Garmin-Overview nicht als RinkLogic-Ausgabefläche dokumentiert
  oder beworben wird,
- der 20-m-Test als korrigierte Referenz geführt wird, ohne automatische
  Kalibrierungsaktivierung,
- und Beta 4 bis zum bestandenen Hardware-/Connect-Test als Rückfallversion
  erhalten bleibt.
