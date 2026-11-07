# Beta 7 – Remote-Abnahme auf Ring-1-Uhren

**Status: FREIGEGEBEN ZUR REMOTE-ABNAHME – 7. November 2026**

Der Quellstand vom 5. November 2026 besitzt offene P0-Fehler in der
Touch-Interaktion und in der semantischen Anzeige des Kalibrierlaufs. Deshalb
darf das folgende Vorabpaket weder verteilt, installiert noch abgenommen
werden:

| Gesperrtes Vorabpaket | Wert |
|---|---|
| Datei | `RinkLogic-0.2.0-beta.7.iq` |
| Größe | `8.579.883` Byte |
| SHA-256 | `918F13E499F338B3F3D81EE1D564C445697F39EE99E290BD305E0195F48D6CB8` |
| App-ID | `4c7d5f9e2b484f0da6913b1c8e7f2a64` |
| Exportnachweis | 69/69 expandierte Binärvarianten |

Der gesperrte Hash bleibt nur als Negativkennung erhalten. Der neue Kandidat
ist unten eindeutig benannt; ausschließlich dieser darf für die Remote-Abnahme
verwendet werden.

## P0-Voraussetzungen vor jeder Remote-Abnahme

Die in `docs/testing/BETA7-HARDWARE-UI.md` dokumentierten Blocker müssen durch
Tests und erneuten UI-Review geschlossen sein:

- [x] Touchzonen der Review-Seite liegen auf den sichtbaren Aktionen;
- [x] Touchflächen im Startmenü und in der Sportauswahl sind auf sichtbare Optionen
  begrenzt; Titel, Leerraum und Bedienhinweise bleiben neutral;
- [x] Laufnummer, Bedingung und Tempo der Accepted-Seite beziehen sich auf denselben
  Lauf;
- [x] Responsive-Prüfung umfasst 466 px und kurze deutsche/englische
  Runddisplay-Zeilen; Venu 2S wurde zusätzlich visuell im Simulator geprüft;
- [x] der neue signierte Kandidat besitzt dokumentierte Größe, neuen SHA-256 und
  vollständigen Paketnachweis.

## Zweck und Aussagegrenze

Nach Freigabe prüft dieses Protokoll den Weg Uhr → FIT → Garmin Connect auf
realen Ring-1-Uhren. Es bewertet technische Durchgängigkeit und Datenqualität,
nicht medizinische Leistung oder die Genauigkeit der experimentellen
Distanzschätzung. Ein Modell wird nur dann als **hardware-verified** geführt,
wenn für genau dieses Modell ein vollständiger Ergebnisbogen und die
zugehörigen Original-FIT-Dateien vorliegen.

Portal-Upload, Veröffentlichung, automatische FIT-Übertragung und eine
pauschale Hardwarefreigabe sind nicht Bestandteil dieses Protokolls.

## Neuer Kandidat – vor Testbeginn ausfüllen

| Merkmal | Neuer Sollwert |
|---|---|
| Datei | `RinkLogic-0.2.0-beta.7.iq` |
| Größe | `8.624.741` Byte |
| SHA-256 | `4E6A62C40B0AE9FB978CB702CF82854A784A9E98CD79FFF662C7DCC7A90D40DF` |
| App-ID | `4c7d5f9e2b484f0da6913b1c8e7f2a64` |
| Commit | `7fef470` |
| Exportbinärdateien | `69/69` PRGs; `manifest.sig2` und `dev_key.pub` vorhanden |

## Geräteabdeckung

Jede Testperson füllt genau eine Gerätezeile aus. Für eine klassenübergreifende
Abnahme werden nach Möglichkeit drei getrennte reale Uhren eingesetzt:

| Test-ID | Geräteklasse | Ring-1-Beispiele | Eingabe | Gerät/Firmware/Tester/Datum |
|---|---|---|---|---|
| R1-A | rundes AMOLED, Touch | Venu 2/3/4, vívoactive 5/6 | Touch und zwei Tasten | ____ |
| R1-B | rundes AMOLED, Tasten | Forerunner AMOLED, epix, fēnix AMOLED, Instinct 3 AMOLED | fünf Tasten | ____ |
| R1-C | rundes MIP, Tasten | Forerunner 255/955, fēnix 7/Solar, Enduro 3 | fünf Tasten | ____ |

Ein erfolgreicher Repräsentantentest gilt nicht automatisch als Hardwarebeleg
für andere Modelle derselben Klasse.

## Vorbereitung

- [ ] Dokumentstatus lautet `FREIGEGEBEN ZUR REMOTE-ABNAHME`.
- [ ] Neuer Kandidat, Commit, Größe und SHA-256 stimmen exakt überein.
- [ ] Exaktes Uhrenmodell, Firmware und Garmin-Connect-Version sind notiert.
- [ ] Vorhandener Status für `EIS` und `INLINE` ist notiert.
- [ ] Gerade, tatsächlich gemessene Strecke von exakt 20,00 m ist markiert.
- [ ] Uhr wird eng getragen; optionaler Brustgurt ist in Garmin gekoppelt.
- [ ] Es ist bekannt, dass kein GPS und kein Cloud-Upload erforderlich sind.

## Lauf A – Kalibrierung

Für jede getestete Uhr ist mindestens eine Sportart vollständig zu
kalibrieren. Eine benannte Profil-Isolationsuhr führt Lauf A und B für `EIS`
und für `INLINE` aus.

1. `WEITER` → `KALIBRIERUNG` → Sport wählen.
2. Fünf gültige 20-m-Läufe ohne Stickhandling durchführen.
3. Fünf gültige 20-m-Läufe mit Stickhandling durchführen.
4. Jeden Lauf über die angezeigte untere Taste beginnen und beenden.
5. Prüfen, dass ein abgelehnter Lauf denselben Schritt wiederholt und keinen
   Zähler erhöht.
6. Bei `10 / 10` Faktor und Sport notieren, aktivieren und die Rückkehr ins
   Auswahlmenü prüfen.
7. Originale Kalibrierungs-FIT-Datei unverändert sichern.

| Prüfpunkte Kalibrierung | EIS | INLINE |
|---|---:|---:|
| 10 gültige Läufe erreicht | [ ] | [ ] |
| Laufnummer, Bedingung und Tempo widerspruchsfrei | [ ] | [ ] |
| abgelehnte Läufe erhöhten den Zähler nicht | [ ] | [ ] |
| angezeigter persönlicher Faktor | ____ | ____ |
| Profilstatus nach Speichern sichtbar | [ ] | [ ] |
| Original-FIT gesichert | [ ] | [ ] |

## Lauf B – Training

1. `WEITER` → `TRAINING` → denselben Sport wie in Lauf A ausdrücklich wählen.
2. Mindestens fünf manuelle On-Ice-Shifts mit dazwischenliegenden Bench-Phasen
   markieren.
3. Vor dem Speichern Shiftzahl, Ø Shiftdauer, Ø Shift-Herzfrequenz, Eiszeit und
   Gesamtzeit auf der Uhr notieren.
4. Aktivität speichern, mit Garmin Connect synchronisieren und die originale
   Trainings-FIT-Datei unverändert sichern.

## Garmin-Connect-Abnahme

### Native Aktivitätsdarstellung

- [ ] Aktivität erscheint als `Hockey`, nicht als `Other`, HIIT oder Cardio.
- [ ] Name unterscheidet `RinkLogic Ice Hockey` und `RinkLogic Inline Hockey`.
- [ ] Gesamtzeit ist vorhanden und plausibel.
- [ ] Kalorien sind vorhanden; Garmin berechnet sie aus Hockey-Aktivität und
      verfügbaren Sensordaten.
- [ ] Native Distanzanzeige notiert: ____ km.

Beta 7 schreibt die experimentelle Distanz in RinkLogic-Entwicklerfelder.
Garmins natives `total_distance` blieb im Hardwaretest `0,0` und ist **kein
Erfolgskriterium**. Der Wert wird nur beobachtet; `0,00 km` ist zulässig.

### Connect-IQ-Zusammenfassung

| ID | Anzeige | Einheit | Ergebnis |
|---:|---|---|---|
| 74 | Shifts | Anzahl | ____ |
| 98 | Ø Shiftdauer | min | ____ |
| 78 | Ø Shift-HF | bpm | ____ |
| 97 | geschätzte Distanz | m | ____ |
| 96 | erkannte Anschübe | Anzahl | ____ |
| 101 | Time On Ice | min | ____ |
| 102 | Bench Time | min | ____ |
| 115 | persönlicher Kalibrierfaktor | Faktor | ____ |

- [ ] Zeitfelder 98, 101, 102, 103–107 und 109 erscheinen in Minuten, nicht
      in Sekunden.
- [ ] Fehlende Bewegung oder Herzfrequenz erscheint unbekannt und nicht als
      erfundene Null.
- [ ] Shiftzahl in Connect entspricht der auf der Uhr gespeicherten Shiftzahl.

### Charts und Laps

- [ ] Chart 62 zeigt Anschübe; Chart 110 zeigt kumulierte geschätzte Distanz in
      Metern, nicht in Zentimetern.
- [ ] Laps sind klar als `On-Ice` (113) und `Bench` (114) erkennbar.
- [ ] Lap-Zeiten 99, 113 und 114 verwenden Minuten.
- [ ] On-Ice-Laps dürfen Shift-HF (95), Anschübe (65/71) und geschätzte
      Shift-Distanz in Metern (111) enthalten; Bench-Laps erfinden diese Werte
      nicht.
- [ ] Eine native Schlussrunde wird nicht als zusätzlicher Shift gezählt.

## FIT-Abnahme

Je Uhr werden Kalibrierungs-FIT und Trainings-FIT desselben Sports benötigt.
Für die Profil-Isolationsuhr werden vier Dateien benötigt: Kalibrierung und
Training für `EIS` sowie Kalibrierung und Training für `INLINE`.

Im lokalen Decoder prüfen:

- [ ] CRC lesbar und FIT-Schema 12 vorhanden.
- [ ] Aktivitätssport ist Hockey.
- [ ] Trainingsname und Testprotokoll identifizieren Eis oder Inline eindeutig.
- [ ] Session-ID 115 im Training stimmt mit dem zuvor gespeicherten Faktor des
      ausgewählten Sports überein.
- [ ] Eis-Training lädt nicht das Inline-Profil und Inline-Training nicht das
      Eis-Profil. Sind beide Faktoren numerisch gleich, wird die Isolation über
      Testreihenfolge, Aktivitätsnamen und beide Kalibrierungs-FITs belegt.
- [ ] RinkLogic-Distanzen 97/110/111 sind Meterwerte oder FIT-Invalid bei
      fehlender Bewegung; Zentimeterwerte sind nicht zulässig.
- [ ] Nativen `total_distance`-Rohwert separat notiert: ____ m. Der Wert ist
      kein Freigabegate.

## Profil-Isolation

Auf mindestens einer realen Ring-1-Uhr:

1. Eis kalibrieren und Eis-Training speichern.
2. Inline kalibrieren und Inline-Training speichern.
3. Ready-Status muss beide Profile getrennt anzeigen.
4. Erneut Eis wählen und ein kurzes Eis-Training speichern.
5. Prüfen, dass der Eis-Faktor erhalten blieb und nicht durch Inline ersetzt
   wurde.

| Isolationsergebnis | Wert |
|---|---|
| Eis-Faktor vor Inline | ____ |
| Inline-Faktor | ____ |
| Eis-Faktor nach Inline | ____ |
| beide Statusanzeigen sichtbar | [ ] |
| kein Cross-Load nachweisbar | [ ] |

## Rückgabe und Datenschutz

Über den vereinbarten privaten Kanal zurückgeben:

- ausgefüllte Gerätezeile und Checkboxen dieses Protokolls;
- originale Kalibrierungs- und Trainings-FIT-Dateien;
- Screenshots von nativer Übersicht, Connect-IQ-Zusammenfassung, Charts und
  Laps ohne Namen, Standort oder Kontodaten;
- genaue Beschreibung jedes `IQ!`, Speicherfehlers, abgeschnittenen Texts oder
  Bedienproblems.

Rohdateien bleiben außerhalb von Git. Beta 7 lädt nichts automatisch hoch und
trainiert kein globales Modell. Ein persönliches Profil wird ausschließlich
lokal auf der Uhr gespeichert. Compile- und Simulatortests ersetzen diese
Hardware- und Connect-Abnahme nicht.
