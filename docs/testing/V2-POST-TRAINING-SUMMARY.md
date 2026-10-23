# V2-Testprotokoll: Trainingszusammenfassung und Garmin Connect

Stand: 23. Oktober 2026. Zielgerät: Garmin Venu 2 Plus. Dieses Protokoll trennt
automatisierte Nachweise, beobachtete Beta-Ergebnisse und weiterhin nicht
protokollierte Detailprüfungen.

## Korrigierte Distanzreferenz vom 13. Oktober

Der aufgezeichnete Streckentest wird mit einer Referenz von **20 m je
Wiederholung (2.000 cm im Kalibrierungsmanifest)** ausgewertet. Die ältere
22-m-Beispielangabe im Distanzprotokoll ist damit ersetzt. Diese
Dokumentations- und Testkorrektur ändert keine App-Konstanten oder den
persönlichen Faktor und aktiviert keine Kalibrierung automatisch.

## Testidentität

- Datum/Uhrzeit: ____________________
- Git-Commit: ____________________
- App-/Buildversion: ____________________
- PRG-Größe und SHA-256: ____________________
- Uhrmodell: Garmin Venu 2 Plus
- Uhr-Firmware: ____________________
- Garmin-Connect-Mobile-Version und Telefonplattform: ____________________
- Tester: ____________________
- Screenshot-/Nachweisreferenz ohne persönliche Daten: ____________________

Aktivitätsdaten werden in **Garmin Connect Mobile** geprüft. Die Connect IQ
Store App dient Installation und Verwaltung; sie ist nicht die Anzeige für die
gespeicherten Trainings- und FIT-Felder.

## Testbuild

Der nächste Lauf verwendet den noch final zu paketierenden Beta-6-/Schema-12-Kandidaten.
Commit, Dateiname, Größe und SHA-256 werden erst nach der vollständigen
Endprüfung hier und in `docs/DEVELOPMENT.md` eingetragen. Die bestätigte
Beta 4 bleibt unangetastet als Rollback; ihr signiertes IQ-Paket wird nicht
überschrieben oder erneut veröffentlicht.

- Beta-6-/Schema-12-Quellcommit: ____________________
- PRG-Datei, Größe und SHA-256: ____________________
- IQ-Datei, Größe und SHA-256: ____________________
- SDK 9.2.0, Gerät `venu2plus`
- Distanzmodus: ____________________
- Automatisierte Prüfergebnisse: ____________________

## Beobachtete Beta-Abnahme

Die private Connect-IQ-Beta `0.1.0-beta.3` wurde am 10. Oktober 2026 vom
Projektinhaber auf der Venu 2 Plus geprüft. Bestätigt wurden App-Start,
Shift-Zählung, Live-Herzfrequenz, Shift-Dauer, durchschnittliche Herzfrequenz
pro Shift, Speichern und alle drei Abschlussseiten. Nach der Synchronisierung
waren die benutzerdefinierten Daten im Connect-IQ-Abschnitt der Aktivität auf
dem Telefon sichtbar; Anzahl Shifts, durchschnittliche Shift-Dauer und
durchschnittliche Shift-Herzfrequenz stehen dort zuerst.

Ein zuvor exportiertes reales Schema-7-FIT wurde ausschließlich in einem
ignorierten privaten Prüfpfad dekodiert. CRC, Entwicklerdaten-Definitionen und
die Sessionwerte für Shiftanzahl, Eiszeit, Bankzeit, durchschnittliche
Shift-Dauer und durchschnittliche Shift-Herzfrequenz waren vorhanden. Die
Datei und persönliche Aktivitätsdaten gehören nicht zum Repository.

Die Garmin-Connect-Overview mit Distanz, Anstieg oder Geschwindigkeit ist eine
native, vom Aktivitätstyp bestimmte Garmin-Darstellung. Connect-IQ-
Entwicklerfelder können diese Karten nicht ersetzen; sie erscheinen im
separaten Connect-IQ-Aktivitätsabschnitt. Uhr-Firmware, Mobile-App-Version und
datenschutzbereinigte Screenshots wurden bei diesem Beta-Durchlauf nicht
protokolliert. Offene Kästchen unten dürfen daher weiterhin nicht als
vollständiger formaler Lauf A oder B interpretiert werden.

## Vorbereitung

- [ ] Prüfsumme der zu installierenden PRG stimmt mit dem Wert oben überein.
- [ ] Vorhandene Geräteversion wurde bei Bedarf gesichert.
- [ ] PRG wurde nach `GARMIN/APPS/ShiftSenseV2.prg` kopiert und die Uhr sicher getrennt.
- [ ] Persönliches HFmax und die Garmin-HF-Zonen sind plausibel eingestellt.
- [ ] Brustgurt oder optischer Sensor liefert vor dem Start einen plausiblen Puls.

## Lauf A: fünf Shifts mit semantischen Phasen

1. Aufnahme starten und etwa 30 Sekunden auf der Bank warten.
2. Fünf manuelle Shifts mit der unteren Taste markieren. Ziel: jeweils 30–60
   Sekunden Eiszeit und dazwischen mindestens 30 Sekunden Bankzeit.
3. Nach dem fünften Shift mindestens 30 Sekunden auf der Bank bleiben und dann
   mit der oberen Taste speichern. Dadurch wird auch die letzte Bankphase
   abgeschlossen.

### Direkt auf der Uhr

Unmittelbar nach erfolgreichem Speichern muss Seite 1 erscheinen. Wischen nach
links/rechts sowie Hoch-/Runter-/Bestätigungstaste wechseln die Seiten.

- [ ] Seite 1: Trainingsdauer, Durchschnittspuls, Maximalpuls.
- [ ] Seite 2: Anzahl Shifts = 5, Eiszeit, Bankzeit.
- [ ] Seite 3: durchschnittlicher Shift, längster Shift, Ø Puls pro Shift.
- [ ] Zeiten und Pulswerte sind plausibel; fehlende Werte erscheinen als `--`.
- [ ] Sämtliche RinkLogic-Zeitwerte tragen `min`: Gesamt-/Eis-/Bankzeit mit
      einer, Shift-Zeiten mit zwei Nachkommastellen.
- [ ] Live-/letzte Shift-Distanz und Gesamtdistanz sind sichtbar und mit `≈`
      als Schätzung gekennzeichnet.
- [ ] Zurück beendet die App ohne erneutes Speichern oder `IQ!`.

### In Garmin Connect nach der Synchronisierung

Synchronisierungsergebnis und -dauer: ____________________

Für jedes Feld wird `sichtbar`, `korrekt`, `nicht unterstützt` oder `fehlerhaft`
mit Screenshot-/Notizreferenz dokumentiert. `Nicht unterstützt` ist eine
Plattformgrenze und kein bestandener Sichtbarkeitstest.

| Summary-Feld | Sichtbar | Korrekt/plausibel | Plattformgrenze oder Nachweis |
| --- | --- | --- | --- |
| Anzahl Shifts | [ ] | [ ] | |
| Time on Ice | [ ] | [ ] | |
| Bankzeit | [ ] | [ ] | |
| Ø Shiftdauer | [ ] | [ ] | |
| Ø Herzfrequenz pro Shift | [ ] | [ ] | |
| HF-Zonen 1–5 | [ ] | [ ] | |
| Work-to-Rest-Verhältnis | [ ] | [ ] | |
| Shift-Dichte | [ ] | [ ] | |
| Median-Shift | [ ] | [ ] | |
| geschätzte Distanz | [ ] | [ ] | Entwicklerfeld 97; native Distanz darf 0,0 bleiben |
| erkannte Anschübe | [ ] | [ ] | |
| persönlicher Faktor | [ ] | [ ] | Feld 115 oder leer ohne aktives Profil |

In der Aktivitätszusammenfassung werden erwartet:

- [ ] Anzahl Shifts, Time on Ice, Bankzeit.
- [ ] Aktivitätstyp beziehungsweise Titel erscheint als `Hockey`, nicht als
      `Other`.
- [ ] Ø Shiftdauer und Ø Herzfrequenz pro Shift.
- [ ] Zeit in HF-Zone 1, 2, 3, 4 und 5.
- [ ] Work-to-Rest-Verhältnis; der gespeicherte Ganzzahlwert trägt die Einheit
      `×0,1 Arbeit/Pause`.
- [ ] Shift-Dichte in Shifts pro Stunde.
- [ ] Median-Shift. Kürzester und längster Shift werden auf der Uhr geprüft;
      Schema 12 reserviert dafür keine aktiven Connect-Summary-Felder.
- [ ] Die ersten fünf Entwicklerwerte stehen in der Reihenfolge Anzahl Shifts,
      Ø Shiftdauer, Ø Shift-HF, geschätzte Distanz, erkannte Anschübe.
- [ ] Eis-/Bankzeit, HF-Zonen und Median tragen die Einheit
      `min`; Distanz trägt `≈` und `m`.
- [ ] Geschätzte Distanz, erkannte Anschübe und persönlicher Faktor 115 sind
      jeweils als eigene Entwicklerwerte sichtbar und plausibel.
- [ ] Die Top 3 beziehungsweise intensivsten Shifts sind intern nach gültigem
      Durchschnittspuls ermittelt. Eine eigene Garmin-Connect-Anzeige wird nur
      als bestanden markiert, wenn tatsächlich ein geeignetes Feld sichtbar ist.
- [ ] Die nativen Garmin-Overview-Karten werden nur beobachtet. Ein Ersatz von
      Distanz, Geschwindigkeit oder Anstieg durch Connect-IQ-Entwicklerfelder
      ist **nicht** Teil dieser Abnahme.
- [ ] Garmins native Gesamtzeit darf weiterhin `HH:MM:SS` verwenden; die
      Minutenpflicht gilt für RinkLogic-eigene Entwicklerfelder.

In der Runden-/Lap-Tabelle werden erwartet:

- [ ] Es gibt vor dem ersten Shift keine künstliche `Bench`-Runde.
- [ ] Die Phasen wechseln streng `On-Ice`, `Bench`, `On-Ice`, `Bench` und so
      weiter; bei diesem Ablauf entstehen beim Speichern genau zehn Phasenrunden.
- [ ] Jede Phase zeigt ihre Dauer in Minuten: `On-Ice` über Feld 113 und
      `Bench` über Feld 114. Pro Runde ist genau eines davon gültig.
      Die beschrifteten Entwicklerwerte müssen sichtbar sein; eine Umbenennung
      der gesamten nativen Garmin-Rundenzeile wird nicht vorausgesetzt.
      On-Ice-Runden zeigen zusätzlich
      die geschätzte Distanz in Metern und – bei ausreichenden Daten – Ø HF.
- [ ] Bench-Runden enthalten keine erfundene Distanz, Shift-HF, Anschubzahl
      oder Bewegungsabdeckung; nicht verfügbare Werte bleiben leer/ungültig.
- [ ] Record-Feld 110 (Meterkurve), On-Ice-Lap-Feld 111 (Meter) und das
      bestehende Session-Feld 97 (Meter) stimmen mit demselben Uhr-Datenfluss
      überein. Das historische Stringfeld 112 ist nicht aktiv.
- [ ] Die letzte Phase erscheint nach Speichern genau einmal; ein Speicher-Retry
      erzeugt keine zusätzliche Schlussrunde.
- [ ] Bei 15 On-Ice- und 15 Bench-Phasen stehen 29 explizite Runden plus die
      native Schlussrunde im FIT, insgesamt 30 statt 31. Dieses Verhalten ist
      hardwareabhängig und muss auf der echten Uhr bestätigt werden.

Screenshot-/Notizreferenzen für Summary und Phasen-Laps: ____________________

## Lauf B: fehlende oder lückenhafte HR-Daten

1. Einen kurzen Lauf mit zwei Shifts durchführen, während keine verlässliche
   HR-Quelle verfügbar ist oder bewusst Datenlücken entstehen.
2. Speichern und synchronisieren.

- [ ] Aufnahme, manuelle Shift-Taste und Speichern funktionieren weiterhin.
- [ ] Anzahl Shifts, Eiszeit und Bankzeit bleiben vorhanden.
- [ ] Nicht berechenbare Puls-, Zonen- und Top-Shift-Werte erscheinen
      als `--`, leer oder ungültig – niemals als erfundene Null.
- [ ] Kein `IQ!` und keine verlorene Standard-Garmin-Aktivität.

## FIT-Exportvergleich

Die Aktivität aus Garmin Connect als Original-FIT exportieren und mit den
manuell notierten Zeiten vergleichen.

- [ ] FIT-Datei lässt sich mit gültiger CRC dekodieren.
- [ ] Schema-12-Marker ID 73 kommt in Record-Nachrichten vor.
- [ ] Aktive Session-IDs sind exakt `74,78,85,86,96,97,98,101–107,109,115`.
- [ ] IDs 101–107 und 109 sind Float-Minuten; alte Sekunden-IDs 75/76/79–84/89 sind
      nicht aktiv allokiert.
- [ ] IDs 63, 66, 93, 94, 108 und 112 bleiben historisch registriert, sind in Schema 12
      aber nicht aktiv allokiert oder umgedeutet.
- [ ] Session-ID 115 ist `float32`/`factor` und enthält den aktiven lokalen
      Faktor oder FIT-invalid ohne aktives Profil.
- [ ] ID 110 ist `record`/`float32`/`m`, ID 111 ist `lap`/`float32`/`m` und
      IDs 113/114 sind `lap`/`float32`/`min` mit exklusiver Gültigkeit.
- [ ] Session-ID 97 bleibt `float32`/`m` ohne `nativeNum`; das native
      `total_distance` wird durch den geschätzten Entwicklerwert nicht befüllt.
- [ ] On-Ice-Laps können ID 95 als Ø Shift-HF enthalten; Bench-Laps lassen
      diesen und alle anderen optionalen Shiftwerte FIT-invalid.
- [ ] Die 20-m-Referenzzeilen sind im lokalen Kalibrierungsmanifest jeweils als
      `2.000 cm` hinterlegt; 22-m-Altwerte werden nicht verwendet.
- [ ] Die Garmin-Connect-Anzeige stimmt mit den dekodierten FIT-Werten überein.
- [ ] Die Original-FIT-Datei bleibt ausschließlich lokal; CRC ist gültig.

## Abnahme

- [ ] **Uhr bestanden** – alle drei Seiten, Navigation und Speichern geprüft.
- [ ] **Garmin Connect bestanden** – Summary- und Lap-Felder sichtbar und plausibel.
- [ ] **FIT bestanden** – Export, CRC, IDs, Einheiten und Werte geprüft.
- [ ] **Fehlende Daten bestanden** – keine erfundenen Werte, keine verlorene Aktivität.
- [ ] **Nachweise vollständig** – Commit, Build-Hash, Firmware, Mobile-Version,
      Synchronisation und datenschutzbereinigte Screenshot-Referenzen erfasst.

Noch nicht angekreuzte Punkte sind offen und dürfen nicht als bestanden gemeldet
werden. Die Simulator-Suite beweist Berechnung, Begrenzung, Speicherung und UI-
Formatierung, ersetzt aber weder den physischen Uhrtest noch die serverseitige
Darstellung in Garmin Connect.

## Abbruch und Rollback

Bei `IQ!`, fehlgeschlagenem Speichern, nicht öffnbarer Aktivität, falscher
Phasenfolge, doppelter Schlussrunde, Zentimeter-/Meterfehler oder fehlenden
Schema-12-Pflichtfeldern wird der Test abgebrochen. Diagnose-Logs und
Original-FIT bleiben lokal; anschließend wird die zuletzt bestätigte Beta 4
installiert. Simulatorerfolg darf keinen dieser Hardware-/Connect-Punkte
automatisch abhaken.
