# V2-Testprotokoll: Trainingszusammenfassung und Garmin Connect

Stand: 10. Oktober 2026. Zielgerät: Garmin Venu 2 Plus. Dieses Protokoll trennt
automatisierte Nachweise, beobachtete Beta-Ergebnisse und weiterhin nicht
protokollierte Detailprüfungen.

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

- Datei: `watch-v2/bin/venu2plus/ShiftSenseV2.prg`
- Quellstand: `c5d30c1`
- Größe: 406.844 Byte
- SHA-256: `779584297394367405FDF5CEE600D004ED12583638EF8E5B533568C71B903F9C`
- Geräteprofil: `venu2plus`
- Automatisiert: 163/163 Connect-IQ-Simulatortests bestanden

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

## Lauf A: fünf Shifts mit Recovery

1. Aufnahme starten und etwa 30 Sekunden auf der Bank warten.
2. Fünf manuelle Shifts mit der unteren Taste markieren. Ziel: jeweils 30–60
   Sekunden Eiszeit und dazwischen mindestens 30 Sekunden Bankzeit.
3. Nach mindestens einem Shift 65 Sekunden bis zum nächsten Shift warten. Damit
   sind sowohl das 30- als auch das 60-Sekunden-Recovery-Fenster vollständig.
4. Nach dem fünften Shift mindestens 65 Sekunden warten und dann mit der oberen
   Taste speichern.

### Direkt auf der Uhr

Unmittelbar nach erfolgreichem Speichern muss Seite 1 erscheinen. Wischen nach
links/rechts sowie Hoch-/Runter-/Bestätigungstaste wechseln die Seiten.

- [ ] Seite 1: Trainingsdauer, Durchschnittspuls, Maximalpuls.
- [ ] Seite 2: Anzahl Shifts = 5, Eiszeit, Bankzeit.
- [ ] Seite 3: durchschnittlicher Shift, längster Shift, Ø Puls pro Shift.
- [ ] Zeiten und Pulswerte sind plausibel; fehlende Werte erscheinen als `--`.
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
| Zeit über 90 % HFmax | [ ] | [ ] | |
| Work-to-Rest-Verhältnis | [ ] | [ ] | |
| Shift-Dichte | [ ] | [ ] | |
| kürzester, längster und Median-Shift | [ ] | [ ] | |

In der Aktivitätszusammenfassung werden erwartet:

- [ ] Anzahl Shifts, Time on Ice, Bankzeit.
- [ ] Ø Shiftdauer und Ø Herzfrequenz pro Shift.
- [ ] Zeit in HF-Zone 1, 2, 3, 4 und 5.
- [ ] Zeit über 90 % HFmax.
- [ ] Work-to-Rest-Verhältnis; der gespeicherte Ganzzahlwert trägt die Einheit
      `×0,1 Arbeit/Pause`.
- [ ] Shift-Dichte in Shifts pro Stunde.
- [ ] Kürzester, längster und Median-Shift.
- [ ] Die Top 3 beziehungsweise intensivsten Shifts sind intern nach gültigem
      Durchschnittspuls ermittelt. Eine eigene Garmin-Connect-Anzeige wird nur
      als bestanden markiert, wenn tatsächlich ein geeignetes Feld sichtbar ist.

In der Runden-/Lap-Tabelle werden erwartet:

- [ ] Genau fünf manuelle Shift-Runden, ohne doppelte Schlussrunde.
- [ ] Ø HF pro Shift. Die drei höchsten gültigen Werte sind die intensivsten
      Shifts dieser Testversion.
- [ ] HF-Abfall nach 30 und 60 Sekunden für die ausreichend langen Bankphasen.
- [ ] Fehlende Recovery-Fenster bleiben leer/ungültig und werden nicht als null ausgegeben.
- [ ] Negative Recovery-Werte bleiben als negative bpm sichtbar, falls der Puls
      am Zielzeitpunkt höher als am Shiftende war.

Screenshot-/Notizreferenzen für Summary, Laps und Recovery: ____________________

## Lauf B: fehlende oder lückenhafte HR-Daten

1. Einen kurzen Lauf mit zwei Shifts durchführen, während keine verlässliche
   HR-Quelle verfügbar ist oder bewusst Datenlücken entstehen.
2. Speichern und synchronisieren.

- [ ] Aufnahme, manuelle Shift-Taste und Speichern funktionieren weiterhin.
- [ ] Anzahl Shifts, Eiszeit und Bankzeit bleiben vorhanden.
- [ ] Nicht berechenbare Puls-, Zonen-, Top-Shift- und Recovery-Werte erscheinen
      als `--`, leer oder ungültig – niemals als erfundene Null.
- [ ] Kein `IQ!` und keine verlorene Standard-Garmin-Aktivität.

## FIT-Exportvergleich

Die Aktivität aus Garmin Connect als Original-FIT exportieren und mit den
manuell notierten Zeiten vergleichen.

- [ ] FIT-Datei lässt sich mit gültiger CRC dekodieren.
- [ ] Schema-7-Marker ID 73 kommt in Record-Nachrichten vor.
- [ ] Session-IDs 74–89 liegen in den dokumentierten Nachrichtentypen und Einheiten vor.
- [ ] Lap-IDs 93–95 gehören jeweils zur richtigen manuellen Shift-Grenze.
- [ ] ID 95 entspricht dem Ø Puls des jeweiligen Shifts; IDs 93/94 entsprechen
      `Puls am Shiftende minus Puls nach 30/60 Sekunden`.
- [ ] Die Garmin-Connect-Anzeige stimmt mit den dekodierten FIT-Werten überein.

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
