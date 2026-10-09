# ShiftSense Hockey FIT-Schema

Registry-Version: **7**. Die kanonische, maschinenlesbare Registry liegt in `shared/schema/hockey-fit-schema.json`. Die frühere Watch schreibt weiterhin ihre eigene Schema-Version mit IDs 1–34. Die Watch-V2-Testversion legt genau 30 Felder an und kennzeichnet Schema 7 in Record-ID 73. Ältere V2-FITs mit Schema 4–6 bleiben lesbar; frühere IDs werden nicht umgedeutet.

## Kompatibilitätsvertrag

- IDs `1..94` sind appweit eindeutig. Die Bedeutung, Einheit und Breite vergebener IDs bleiben unverändert; Schema 7 verwendet für neue Inhalte ausschließlich IDs ab 73.
- Neue optionale Felder erhalten ausschließlich neue IDs. Ein Parser muss unbekannte IDs ignorieren und die frühere Version an Sitzungsfeld 24, die V2-Pilotversion an Sitzungsfeld 50 erkennen.
- Pro V2-`record` werden 9 Byte eigener Nutzdaten geschrieben. Die Session-Zusammenfassung benötigt 24 Byte in 16 Feldern.
- Numerische Entwicklerfelder werden als unskalierte Integer mit der dokumentierten Einheit abgelegt. `au_x100` bedeutet Wert geteilt durch 100, `ratio_x1000` Wert geteilt durch 1000.
- Die erste Gerätewelle verwendet einen vorzeichenbehafteten 32-Bit-`Number`-Wert. `uint32`-Felder akzeptieren deshalb sicher nur `0..2147483647`; größere Werte müssen vom Aufrufer skaliert oder aufgeteilt werden, statt zu überlaufen.

## Garmin-Connect-Metadaten

`watch/resources/fitfields.xml` enthält die auf der ersten Gerätewelle physisch geschriebenen IDs `1..34` als globale Garmin-Connect-`fitContributions`. Die SDK-Regel erlaubt keine sprachspezifische Überschreibung dieser Definitionen. Ihre `dataLabel`- und `unitLabel`-Verweise zeigen deshalb auf die parallelen englischen und deutschen String-Ressourcen; die angezeigten Bezeichnungen werden mit der App-Sprache lokalisiert.

Die Venu 2 Plus beendet eine Session im Simulator mit einem nicht abfangbaren Systemfehler, sobald ein 17. Session-Developer-Feld angelegt wird, auch wenn die dokumentierte 32-Byte-Grenze eingehalten ist. Schema 7 verwendet deshalb genau 16 Session-Felder und 30 Felder insgesamt. Die internen Shadow-Record-Felder 43–49, 53–54 und 64, die alten Session-Felder 57–61 und 67–70 sowie 90–92 werden in diesem Build nicht angelegt. Die Simulator-Allokation ist geprüft; die physische Uhr und Garmin Connect müssen getrennt abgenommen werden.

Nur numerisch sinnvoll darstellbare Felder sind als Diagramme oder Detailwerte freigegeben: Bewegungsintensität, geschätzte Distanz, Anschubfrequenz, Gleit-/Anschubverhältnis und Impact als Charts; Wechseldauer, Konfidenz und Intensität in Runden; Shiftzahl, Eis-/Bankzeit und Distanz in der Zusammenfassung. Rohcodes, Schema-Versionen und Bitmasken bleiben für den Parser erhalten, ohne die Garmin-Connect-Oberfläche mit unübersetzten Codes zu überladen.

## Feldgruppen

| IDs | FIT-Nachricht | Inhalt |
| --- | --- | --- |
| 1–15 | `record` | Modus, Shift-Zustand/-Konfidenz, Bewegungs- und Qualitätsdaten (typisch einmal pro Sekunde aktualisieren). |
| 16–23 | `lap` | Marker an jeder Shift-/Bankgrenze. Der `timestamp_ms` ist die Uhrzeit relativ zum Beginn der Session in Millisekunden. |
| 24–34 | `session` | Auf der Venu 2 Plus persistierte Zusammenfassung mit Schemaversion, Modus, Shifts, Spiel-/Bankzeit, Distanz, Qualität, Kalibrierung sowie Hits, Pässen und Schüssen. |
| 35–42 | `session` | Reservierte HR-Zusammenfassung: Stichproben, Erholung und Zeit in HR-Zonen 0–5; auf der Venu 2 Plus derzeit nicht als FIT-Feld angelegt. |
| 43–50 | historisch | V2-Pilotfelder; in Schema 7 nicht allokiert. |
| 51–52 | `lap` | Exakter manueller Grenzmarker: Millisekunden seit Aufzeichnungsbeginn und Zustand. |
| 53–54 | historisch | V2-Pilotfelder; in Schema 7 nicht allokiert. |
| 55–56 | `lap` | Automatischer Grenzvorschlag mit geschätztem Bewegungsbeginn in Millisekunden und Zustand. |
| 57–61 | historisch | Frühere Session-Zusammenfassung; in Schema 7 nicht allokiert und nicht umgedeutet. |
| 62–63 | `record` | Kumulierte Anschübe und geschätzte Distanz (cm). |
| 64 | historisch | Anschubkadenz; in Schema 7 nicht allokiert. |
| 65–66 | `lap` | Anschübe und geschätzte Distanz (cm) des beendeten manuellen Shifts. |
| 67–70 | historisch | Frühere Bewegungszusammenfassung; in Schema 7 nicht allokiert und nicht umgedeutet. |
| 71–72 | `lap` | Kurze Anschübe und Sensorabdeckung (%) des beendeten manuellen Shifts. |
| 73 | `record` | Schema-Version 7 (`uint8`, 1 Byte). |
| 74 | `session` | Anzahl Shifts (`uint8`, ungültig `255`). |
| 75–76 | `session` | Eiszeit und Bankzeit in Sekunden (`uint16`, ungültig `65535`). |
| 77 | `session` | Durchschnittliche Shiftdauer in Sekunden (`uint8`, ungültig `255`). |
| 78 | `session` | Durchschnittliche Herzfrequenz pro Shift in bpm (`uint8`, ungültig `255`). |
| 79–83 | `session` | Sekunden in HF-Zone 1–5 (`uint16`, ungültig `65535`). |
| 84 | `session` | Sekunden über 90 % HFmax (`uint16`, ungültig `65535`). |
| 85 | `session` | Work-to-Rest-Verhältnis ×10 (`uint8`, Einheit weist in Garmin Connect auf den Faktor ×0,1 hin; ungültig `255`). |
| 86 | `session` | Shifts pro Stunde, ganzzahlig (`uint8`, ungültig `255`). |
| 87–89 | `session` | Kürzester, längster und Median-Shift in Sekunden (`uint8`, ungültig `255`). |
| 90–92 | reserviert | Nicht allokiert; keine Umdeutung früherer oder geplanter IDs. |
| 93–94 | `lap` | HF-Abfall 30/60 Sekunden nach Shiftende in bpm (`sint16`, ungültig `32767`); negative Werte sind zulässig. |
| 95 | `lap` | Durchschnittliche HF des Shifts (`uint8`, ungültig `255`). Die intensivsten Shifts sind dadurch in der Rundentabelle direkt vergleichbar. |

Watch V2 legt in Schema 7 genau 30 Entwicklerfelder an. Die automatische Erkennung bleibt im Pilot **nicht autoritativ**; sie verändert weder Shiftzahl noch Time on Ice. Manuelle Grenzen stehen in Lap-Feldern 51–52, automatische Vorschläge in 55–56. Die Shiftwerte 65/66/71/72 und 93–95 gehören nur zu einem manuellen Ende (`manual_boundary_state=2`). Die Lap wird bis zu 65 Sekunden zurückgehalten, damit der HF-Abfall nach 30 und 60 Sekunden ergänzt werden kann; ein neuer Shift oder das Speichern beendet die Wartezeit mit ungültigen Werten für noch fehlende Ziele. Alle Lap-Werte werden danach zurückgesetzt. Ein beim Speichern offener Shift erhält vor `Session.stop()` genau eine manuelle Schluss-Lap. Record-Summen sind kumuliert, sodass ausgelassene Sekunden die Endsumme nicht zerstören.

Die 24 Session-Bytes setzen sich zusammen aus: Shiftzahl 1, Eis-/Bankzeit 4, mittlere Shiftdauer 1, mittlere Shift-HF 1, fünf Zonen 10, Zeit >90 % 2, Work/Rest 1, Shift-Dichte 1 und drei Shift-Zeitstatistiken 3. Werte außerhalb des darstellbaren Bereichs werden als ungültig geschrieben und niemals geklemmt. Millisekunden werden für FIT durch ganzzahlige Division in Sekunden umgerechnet. Die Top-Shifts werden nicht vorab auf drei Session-Felder reduziert: Feld 95 zeigt die Durchschnitts-HF für jeden Shift in Garmin Connect.

Die Distanz ist eine heuristische **Schätzung**, keine native GPS- oder Garmin-Distanz. Zentimeterfelder sind Integer; `≈` steht in den lokalisierten Garmin-Connect-Labels. `motion_coverage_percent=255` und `shift_motion_coverage_percent=255` bedeuten unbekannte Abdeckung, nicht 255 %. Fehlende uint16-Anschub- und Kadenzwerte verwenden den FIT-Invalidwert `65535`; fehlende uint32-Summen oder -Distanzen verwenden `4294967295`. Die Garmin-Simulator-API akzeptiert diesen uint32-Invalidwert als Monkey-C-`Long`. Gültige 32-Bit-Werte werden bei 2147483647 begrenzt, um auf diesem Gerät keinen Überlauf zu erzeugen. Ein Shift ohne einziges gültiges Bewegungssample liefert ungültige statt scheinbar gemessener Nullwerte. Sensorlücken behalten die letzte kumulierte Summe bei. Eine hohe Sensorabdeckung beweist noch keine Distanzgenauigkeit.

## Codes und Qualität

`hockey_mode`: 1 Eis, 2 Inline Halle, 3 Inline Outdoor. `shift_state`: 1 Bank, 2 Übergang, 3 Shift, 4 Unterbrechung, 5 unsicher. Spätere Quellen-, HR- und Qualitätsflag-Codes werden vor ihrer Verwendung versioniert ergänzt; `quality_flags` ist eine Bitmaske und niemals eine stillschweigende Qualitätsbehauptung.

## FIT-Prüfung

Die SDK-Referenz beschreibt die Aufzeichnung über `ActivityRecording.Session` und Felder über `Session.createField`. Beim Test muss die Simulator-Aktivitätsdaten-UI die Aufnahme starten/stoppen; danach ist die erzeugte FIT-Datei mit einem verfügbaren FIT-CSV-/FIT-SDK-Werkzeug auf CRC sowie die IDs 1, 2, 3, 5, 6 und 7 zu prüfen. Fehlt ein nicht-interaktives CSV-Werkzeug, wird das als Validierungsgrenze dokumentiert, nicht als erfolgreicher FIT-Export ausgegeben.
