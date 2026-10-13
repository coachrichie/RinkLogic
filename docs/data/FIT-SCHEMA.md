# ShiftSense Hockey FIT-Schema

Registry-Version: **10**. Die kanonische, maschinenlesbare Registry liegt in `shared/schema/hockey-fit-schema.json`. Die frühere Watch schreibt weiterhin ihre eigene Schema-Version mit IDs 1–34. Die Watch-V2-Testversion soll 33 Felder anlegen und Schema 10 in Record-ID 73 kennzeichnen. Ältere V2-FITs mit Schema 4–9 bleiben lesbar; frühere IDs werden nicht umgedeutet.

## Kompatibilitätsvertrag

- IDs `1..112` sind appweit eindeutig. Die Bedeutung, Einheit und Breite vergebener IDs bleibt unverändert; Schema 9 verwendet für Minutenwerte ausschließlich die IDs 101–109, Schema 10 ergänzt Meter- und Phasenfelder 110–112.
- Neue optionale Felder erhalten ausschließlich neue IDs. Ein Parser muss unbekannte IDs ignorieren und die frühere Version an Sitzungsfeld 24, die V2-Pilotversion an Sitzungsfeld 50 erkennen.
- Schema 9 schreibt pro V2-`record` 17 Byte eigener Nutzdaten. Schema 10 ersetzt das Record-cm-Feld 63 durch das Float-Meterfeld 110. Die Session-Zusammenfassung verwendet weiterhin exakt 16 Entwicklerfelder; neun Float-Minutenfelder erhöhen deren Nutzdaten auf 50 Byte.
- Numerische Entwicklerfelder werden als unskalierte Integer mit der dokumentierten Einheit abgelegt. `au_x100` bedeutet Wert geteilt durch 100, `ratio_x1000` Wert geteilt durch 1000.
- Die erste Gerätewelle verwendet einen vorzeichenbehafteten 32-Bit-`Number`-Wert. `uint32`-Felder akzeptieren deshalb sicher nur `0..2147483647`; größere Werte müssen vom Aufrufer skaliert oder aufgeteilt werden, statt zu überlaufen.

## Garmin-Connect-Metadaten

`watch-v2/resources/fitfields.xml` enthält die in diesem Build für Garmin Connect sichtbaren Beiträge als globale `fitContributions`. Die SDK-Regel erlaubt keine sprachspezifische Überschreibung dieser Definitionen. Ihre `dataLabel`- und `unitLabel`-Verweise zeigen deshalb auf die parallelen englischen und deutschen String-Ressourcen; die angezeigten Bezeichnungen werden mit der App-Sprache lokalisiert.

Die Venu 2 Plus beendet eine Session im Simulator mit einem nicht abfangbaren Systemfehler, sobald ein 17. Session-Developer-Feld angelegt wird. Schema 10 sieht deshalb genau 16 Session-Felder und 33 Felder insgesamt vor. Die bisherigen Sekundenfelder 75–76, 79–84 und 89 bleiben reserviert, werden aber nicht mehr angelegt. Gleiches gilt für 43, 46–50, 53–54, 57–61, 63–64, 66–70, 77, 87–94. Die Schema-9-Simulator-Allokation ist geprüft; Schema 10, die physische Uhr und Garmin Connect müssen getrennt abgenommen werden.

Nur numerisch sinnvoll darstellbare Felder sind als Diagramme oder Detailwerte freigegeben: Bewegungsintensität, geschätzte Distanz, Anschubfrequenz, Gleit-/Anschubverhältnis und Impact als Charts; Wechseldauer, Konfidenz und Intensität in Runden; Shiftzahl, Eis-/Bankzeit und Distanz in der Zusammenfassung. Rohcodes, Schema-Versionen und Bitmasken bleiben für den Parser erhalten, ohne die Garmin-Connect-Oberfläche mit unübersetzten Codes zu überladen.

## Feldgruppen

| IDs | FIT-Nachricht | Inhalt |
| --- | --- | --- |
| 1–15 | `record` | Modus, Shift-Zustand/-Konfidenz, Bewegungs- und Qualitätsdaten (typisch einmal pro Sekunde aktualisieren). |
| 16–23 | `lap` | Marker an jeder Shift-/Bankgrenze. Der `timestamp_ms` ist die Uhrzeit relativ zum Beginn der Session in Millisekunden. |
| 24–34 | `session` | Auf der Venu 2 Plus persistierte Zusammenfassung mit Schemaversion, Modus, Shifts, Spiel-/Bankzeit, Distanz, Qualität, Kalibrierung sowie Hits, Pässen und Schüssen. |
| 35–42 | `session` | Reservierte HR-Zusammenfassung: Stichproben, Erholung und Zeit in HR-Zonen 0–5; auf der Venu 2 Plus derzeit nicht als FIT-Feld angelegt. |
| 43–50 | `record`/historisch | IDs 44–45 schreiben Bewegungsintensität (`mg`) und Rotation (`deg/s`); die übrigen IDs dieser Gruppe werden in Schema 8 nicht allokiert. |
| 51–52 | `lap` | Exakter manueller Grenzmarker: Millisekunden seit Aufzeichnungsbeginn und Zustand. |
| 53–54 | historisch | V2-Pilotfelder; in Schema 8 nicht allokiert. |
| 55–56 | `lap` | Automatischer Grenzvorschlag mit geschätztem Bewegungsbeginn in Millisekunden und Zustand. |
| 57–61 | historisch | Frühere Session-Zusammenfassung; in Schema 8 nicht allokiert und nicht umgedeutet. |
| 62 | `record` | Kumulierte Anschübe. |
| 63 | historisch | Kumulierte geschätzte Distanz (cm), seit Schema 10 nicht allokiert. |
| 64 | historisch | Anschubkadenz; in Schema 8 nicht allokiert. |
| 65 | `lap` | Anschübe des beendeten manuellen Shifts. |
| 66 | historisch | Geschätzte Shift-Distanz (cm), seit Schema 10 nicht allokiert. |
| 67–70 | historisch | Frühere Bewegungszusammenfassung; in Schema 8 nicht allokiert und nicht umgedeutet. |
| 71–72 | `lap` | Kurze Anschübe und Sensorabdeckung (%) des beendeten manuellen Shifts. |
| 73 | `record` | Schema-Version 10 (`uint8`, 1 Byte). |
| 74 | `session` | Anzahl Shifts (`uint8`, ungültig `255`). |
| 75–76 | historisch | Eiszeit und Bankzeit in Sekunden aus Schema 7–8; seit Schema 9 nicht allokiert und nicht umgedeutet. |
| 77 | historisch | Durchschnittliche Shiftdauer in Sekunden aus Schema 7; in Schema 8 nicht allokiert und nicht umgedeutet. |
| 78 | `session` | Durchschnittliche Herzfrequenz pro Shift in bpm (`uint8`, ungültig `255`). |
| 79–83 | historisch | Sekunden in HF-Zone 1–5 aus Schema 7–8; seit Schema 9 nicht allokiert. |
| 84 | historisch | Sekunden über 90 % HFmax aus Schema 7–8; seit Schema 9 nicht allokiert. |
| 85 | `session` | Work-to-Rest-Verhältnis ×10 (`uint8`, Einheit weist in Garmin Connect auf den Faktor ×0,1 hin; ungültig `255`). |
| 86 | `session` | Shifts pro Stunde, ganzzahlig (`uint8`, ungültig `255`). |
| 87–88 | historisch | Kürzester und längster Shift in Sekunden aus Schema 7; in Schema 8 nicht allokiert und nicht umgedeutet. |
| 89 | historisch | Median-Shift in Sekunden aus Schema 7–8; seit Schema 9 nicht allokiert. |
| 90–92 | reserviert | Nicht allokiert; keine Umdeutung früherer oder geplanter IDs. |
| 93–94 | historisch | HF-Abfall 30/60 Sekunden nach Shiftende in bpm (`sint16`, ungültig `32767`); negative Werte sind zulässig. Seit Schema 10 nicht allokiert; Recovery bleibt lokal aus Record-Daten auswertbar. |
| 95 | `lap` | Durchschnittliche HF des Shifts (`uint8`, ungültig `255`). Die intensivsten Shifts sind dadurch in der Rundentabelle direkt vergleichbar. |
| 96 | `session` | Erkannte Anschübe (`uint16`, ungültig `65535`). Diese experimentelle Detektion kann Anschübe überzählen. |
| 97 | `session` | Geschätzte Distanz in Metern (`float32`), auf Zentimeter beziehungsweise zwei Dezimalstellen aufgelöst; über `nativeNum=9` als Äquivalent zum nativen Sessionfeld `total_distance` gekennzeichnet. Kein GPS-Messwert. |
| 98 | `session` | Durchschnittliche Shiftdauer in Dezimalminuten (`float32`, Einheit `min`). |
| 99 | `lap` | Dauer des beendeten manuellen Shifts in Dezimalminuten (`float32`). Daraus leitet der lokale Parser kürzesten, längsten und Median-Shift ohne 254-s-Grenze ab. |
| 100 | `record` | Kumulierte rohe Anschubkandidaten vor Rhythmusfilter (`uint32`). Feld 96 bleibt die Zahl akzeptierter Anschübe. |
| 101–102 | `session` | Eiszeit und Bankzeit in Dezimalminuten (`float32`, `min`), Connect-Präzision eine Nachkommastelle. |
| 103–107 | `session` | Zeit in HF-Zone 1–5 in Dezimalminuten (`float32`, `min`), Connect-Präzision eine Nachkommastelle. |
| 108 | `session` | Zeit über 90 % HFmax in Dezimalminuten (`float32`, `min`), Connect-Präzision eine Nachkommastelle. |
| 109 | `session` | Median-Shiftdauer in Dezimalminuten (`float32`, `min`), Connect-Präzision zwei Nachkommastellen. |
| 110 | `record` | Kumulierte geschätzte Distanz in Metern (`float32`, `m`), Connect-Chart mit mindestens einer Nachkommastelle. |
| 111 | `lap` | Geschätzte Distanz des On-Ice-Abschnitts in Metern (`float32`, `m`), Connect-Lap mit zwei Nachkommastellen; bei Bench FIT-invalid. |
| 112 | `lap` | Sichtbare Phase `On-Ice` oder `Bench` (`string`, Länge 8), Connect-Lap-Spalte `Phase`. |

Schema 10 sieht 33 aktive Entwicklerfelder vor. Die automatische Erkennung bleibt im Pilot **nicht autoritativ**; sie verändert weder Shiftzahl noch Time on Ice. Manuelle Grenzen stehen weiterhin in Lap-Feldern 51–52, automatische Vorschläge in 55–56. Jedes manuell abgegrenzte Intervall erhält unmittelbar beim Umschalten oder Speichern genau eine Lap: zuerst `On-Ice`, danach abwechselnd `Bench` und `On-Ice`. Vor dem ersten Shift entsteht keine künstliche Bench-Lap. On-Ice-Laps können 65/71/72/95/99/111 enthalten; Bench-Laps enthalten Phase und Dauer, optionale Shiftwerte bleiben FIT-invalid. Feld 112 kennzeichnet die Phase sichtbar. Record-Summen sind kumuliert, sodass ausgelassene Sekunden die Endsumme nicht zerstören. In Schema 9 gehörten 65/66/71/72/93–95/99 zu einem manuellen Ende (`manual_boundary_state=2`); diese Laps wurden für die Recovery-Messung bis zu 65 Sekunden zurückgehalten. Alte FITs behalten diese Bedeutung.

Die 16 aktiven Session-IDs sind `74, 78, 85, 86, 96, 97, 98, 101–109`. Fehlende Floatwerte werden als FIT-Invalid/NaN geschrieben, gültige Nullwerte als `0.0`. Der lokale Parser wählt die Einheit anhand von Schemaversion und Feldidentität: Sekunden aus Schema 4–8 werden einmal geteilt, die Minutenfelder 98/99 und 101–109 nie erneut; cm-Felder aus Schema 4–9 werden nur für die Ausgabe in Meter umgerechnet. Rohwerte bleiben im Bericht erhalten. Die fünf obersten Connect-Werte sind Shifts, mittlere Shiftdauer (min), mittlere Shift-HF, geschätzte Distanz (m) und erkannte Anschübe (Feldreihenfolge 74, 98, 78, 97, 96). Feld 95 zeigt zusätzlich die Durchschnitts-HF für On-Ice-Laps in Garmin Connect.

Die Distanz ist eine heuristische **Schätzung**, keine GPS-Messung. Feld 97 trägt weiterhin `nativeNum=9`, die FIT-Profilzuordnung zum nativen Sessionfeld `total_distance`, damit Garmin Connect die Schätzung testweise auch in der nativen Distanzdarstellung verwenden kann. Ob Garmin diese Zuordnung tatsächlich in einer nativen Overview-Karte zeigt und mit welcher Einheit oder Dezimaldarstellung, ist ungeprüft und liegt bei Garmin. Der Connect-IQ-Zusammenfassungsbereich zeigt Feld 97 separat. Die Zuordnung ändert weder Quelle noch Genauigkeit der Schätzung. Der normale Build behält exakt 125/225 cm, `ProfileHeight` wendet nur den begrenzten Höhenfaktor an. Ausschließlich `0.2.0-beta.4` berechnet zuerst die höhenbegrenzte Baseline mit positiver Half-up-Rundung und wendet danach getrennt den lokalen persönlichen Faktor `220/292,5` mit erneuter Half-up-Rundung an. Ungültige Höhen verwenden vor der persönlichen Schicht exakt 125/225 cm. Gewicht und BMI sind keine Faktoren. Es gibt keine automatische Aktivierung, kein GPS, keinen Upload und kein globales Modell oder Training. Auch die Anschuberkennung ist experimentell und kann insbesondere bei Stickhandling überzählen. Historische Zentimeterfelder sind Integer; die neuen Meterfelder sind `float32`. `≈` steht in den lokalisierten Garmin-Connect-Labels. `motion_coverage_percent=255` und `shift_motion_coverage_percent=255` bedeuten unbekannte Abdeckung, nicht 255 %. Fehlende uint16-Anschub- und Kadenzwerte verwenden den FIT-Invalidwert `65535`; fehlende historische uint32-Summen, -Distanzen oder -Kandidaten verwenden `4294967295`. Ein Shift ohne einziges gültiges Bewegungssample liefert ungültige statt scheinbar gemessener Nullwerte. Sensorlücken behalten die letzte kumulierte Summe bei. Eine hohe Sensorabdeckung beweist noch keine Distanzgenauigkeit.

## Codes und Qualität

`hockey_mode`: 1 Eis, 2 Inline Halle, 3 Inline Outdoor. `shift_state`: 1 Bank, 2 Übergang, 3 Shift, 4 Unterbrechung, 5 unsicher. Spätere Quellen-, HR- und Qualitätsflag-Codes werden vor ihrer Verwendung versioniert ergänzt; `quality_flags` ist eine Bitmaske und niemals eine stillschweigende Qualitätsbehauptung.

## FIT-Prüfung

Die SDK-Referenz beschreibt die Aufzeichnung über `ActivityRecording.Session` und Felder über `Session.createField`. Beim Test muss die Simulator-Aktivitätsdaten-UI die Aufnahme starten/stoppen; danach ist die erzeugte FIT-Datei mit einem verfügbaren FIT-CSV-/FIT-SDK-Werkzeug auf CRC sowie die IDs 1, 2, 3, 5, 6 und 7 zu prüfen. Fehlt ein nicht-interaktives CSV-Werkzeug, wird das als Validierungsgrenze dokumentiert, nicht als erfolgreicher FIT-Export ausgegeben.
