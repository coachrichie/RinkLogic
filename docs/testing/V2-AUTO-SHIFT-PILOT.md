# V2-Pilot: automatische Shift-Vorschläge im Hintergrund

Stand: 2026-09-29. Der Nutzer bestätigte nach dem korrigierten Schema-6-Build den App-Start und die manuelle Shift-Zählung; die zugehörige kurze FIT-Datei wurde lokal geprüft. **Die automatische Shift-Erkennung ist weiterhin nicht validiert.** Sie ändert weder den Live-Shift-Zähler noch `TIME ON ICE`. Die untere Taste bleibt die einzige verbindliche Shift-Eingabe.

## Nächste vollständige Einheit: Montag, 05.10.2026

- ShiftSense selbst auf der Uhr starten. Vor Beginn Akkustand und gegebenenfalls die in Garmins Sensoreinstellungen bestätigte H10-Verbindung notieren; ein HR-Wert allein beweist die Brustgurtquelle nicht.
- Während des Trainings **jeden** Shift-Beginn und jedes Shift-Ende mit der unteren Taste markieren. Vergessene, doppelte oder verspätete Tastendrücke möglichst mit ungefährer Uhrzeit festhalten; eine dadurch lückenhafte Referenz nicht nachträglich als vollständig ausgeben.
- Kurz prüfen, ob Live-HR, HR-Zone, `SHIFT AVG HR`, Shift-Zähler und `TIME ON ICE` plausibel sind. Die obere Taste beendet und speichert die Aufzeichnung. Danach Akkustand und Sichtbarkeit auf Uhr beziehungsweise Garmin Connect notieren.
- Nach der Einheit die Uhr verbinden. Die Original-FIT-Datei bleibt ausschließlich lokal unter `analysis/private/`; erst dann CRC, Schema, Sensorlücken und automatische Vorschläge gegen die manuellen Marker auswerten. Ohne FIT oder bei unklaren Markern keine Genauigkeitsquote für den Pilot berichten.
- Das bereits eingerichtete Testprotokoll fragt am Dienstag nach dieser Einheit. Es startet keine Aufnahme auf der Uhr und ersetzt die eigenen Marker nicht.

## Freigabe vor längeren Tests

1. Installierte App auf der Venu 2 Plus öffnen. Ready-Bildschirm → Garmin-Dialog `Start recording?` → Live-UI prüfen.
2. Eine kurze Aufnahme (etwa 2–3 Minuten) durchführen. Mit der **unteren Taste** mindestens einen Shift starten und beenden. Live-HR, SHIFT AVG HR, Zone, Shifts, letzter/durchschnittlicher Shift, Time on Ice und Aufzeichnungszeit prüfen. Auf der zweiten, horizontal wischbaren HR-Seite den AVG-HR-Wert der gesamten Aufnahme prüfen.
3. Mit der **oberen Taste** `Stop & Speichern` ausführen. Prüfen, ob die Aktivität auf der Uhr und nach Synchronisation in Garmin Connect sichtbar ist.
4. Die originale FIT-Datei lokal exportieren und unter `analysis/private/` ablegen. Sie wird nicht ins Repository hochgeladen. Die Auswertung mit `python -m analysis.shift_pilot analysis/private/DATEI.fit` starten. Für den neuen Build CRC, Schema 6, 30 erwartete Entwicklerfeld-IDs 43–72, Standard-HR und Sitzungsdaten prüfen. Ältere Schema-4/5-Aufnahmen bleiben lesbar. Automatische Vorschläge erzeugen für den Pilot zusätzliche FIT-Runden; die Shiftzahl im Live-UI bleibt manuell.
5. Bei Start-, Live-UI- oder Speicherfehlern **keine** längeren Tests durchführen. Diagnose sichern und zur letzten funktionierenden Version zurückkehren. Referenz vor diesem Pilot: Commit `7791d1b` (V2 mit manuellen Shifts), aus dessen Stand bei Bedarf eine signierte PRG neu gebaut werden kann.

## Sitzungsprotokoll

Für jede vollständige Sitzung eine Zeile beziehungsweise ein ausgefülltes Exemplar dieser Angaben festhalten. „Eis/Inline“ bezeichnet hier die tatsächliche Sportumgebung, **keine** Auswahl in der V2-App.

| Feld | Wert |
| --- | --- |
| Sitzung / Datum | offen |
| Uhrmodell, Firmware | Venu 2 Plus / offen |
| App-Build-Commit / PRG-SHA-256 | offen |
| Eis oder Inline; Hallen-/Außenumgebung | offen |
| Akkustand Start / Ende | offen / offen |
| HR verfügbar; Garmin-Sensorquelle bekannt? | offen; Polar H10 darf ohne Nachweis nicht behauptet werden |
| Dauer; Aufnahme gespeichert und in Garmin Connect sichtbar | offen |
| Bewegungssamples, gültige Sekunden, fehlende Sekunden | offen |
| Unbeobachtete Sekunden durch Smart Recording/Schreib- oder Sensorlücken | offen |
| Gyro verfügbar; Sensorabbrüche | offen |
| Manuelle Grenzmarker, automatische Vorschläge | offen |
| FIT-CRC, Schemaversion und Entwicklerfeld-IDs | offen |
| Precision / Recall | offen / offen |
| Median / P95 Grenzfehler | offen / offen |
| Falsche Trennungen pro Stunde | offen |
| Time-on-Ice-Abweichung | offen |
| Beobachtungen bei Spielunterbrechung, Stickhandling und Bewegung auf der Bank | offen |
| Unsichere oder verspätete manuelle Tastendrücke; ggf. Video-/Notizreferenz | offen |

## Pilotumfang und Entscheidung

- Mindestens **fünf vollständige Sitzungen** und **50 manuelle Grenzmarker** sammeln. Ganze Sitzungen auswerten, keine zufällig gewählten Sekunden.
- Für Akkuvergleich ungefähr 60 Minuten mit Schatten-Erkennung und eine vergleichbare nur manuelle Sitzung dokumentieren. Modell, Firmware, Helligkeit und HR-Quelle möglichst gleich halten.
- Vorläufige Zielwerte: Precision und Recall je mindestens 90 %, Median-Grenzfehler höchstens 10 s, höchstens eine falsche Trennung pro Stunde, kein verlorenes Recording. Diese Werte sind bisher **nicht erreicht oder gemessen**.
- Fehlende Sensorwerte und unklare manuelle Referenzen separat markieren; nicht als Bankzeit oder korrekte Automatik werten.
- Eine spätere automatische Live-Zählung erfordert eine eigene Entscheidung nach Sichtung des Berichts durch den Nutzer. Bis dahin bleibt V2 manuell mit Hintergrundvorschlägen.

## Aktueller Prüfstand

- Simulator: 78/78 Monkey-C-Tests; signierter `venu2plus`-Build erfolgreich (SHA-256 `65F411339F3325AB503127A09A29DDD4320B406A032EFCC1F71BA51F4E59A7AC`). Die zehn V2-Felder konnten in einer echten Garmin-Simulatorsession angelegt werden; Start/Save funktionierten.
- Lokale Python-Auswertung: 7/7 Tests; ein älteres Garmin-SDK-Beispiel-FIT wurde mit CRC gelesen und korrekt als „kein Schema 4“ abgewiesen.
- Offen: exportiertes Schema-4-FIT, CRC- und Feld-ID-Rundlauf, tatsächliche Bewegungsdaten auf der Venu 2 Plus, Akkueffekt und sämtliche Genauigkeitswerte. Der Windows-WPD-Status der Venu 2 Plus war beim Prüfversuch `Unknown`; eine Verbindung oder Installation ist damit nicht bestätigt.

## 2026-09-24 – Review-Nachbesserung und erste Übertragung

- Die Review fand vier Genauigkeitsrisiken: flüchtige Ereignisbits unter Smart Recording, veraltete Bewegungswerte, addierte statt eindeutig kombinierte Bits und um die Bestätigungszeit verschobene Vorschlagsgrenzen. Die automatischen Vorschläge stehen jetzt als eigene FIT-Lap-Marker mit geschätztem Grenzzeitpunkt; Ereignisbits werden nicht mehr für die Auswertung genutzt. `sample_seq` und `sample_at_ms` kennzeichnen frische Sensordaten; unbeobachtete Zeit wird konservativ als Lücke gezählt. Die Erkennung bewahrt die letzten 20 Samples korrekt per Array-Slice auf.
- Die vollständige Simulator-Suite bestand mit **80/80**, die lokale Auswertung mit **9/9** Tests. Signierter `venu2plus`-Build: SHA-256 `8A14EBE4D47E613A6E2631103DFB19724423C63934A87062BF35028888DAF305` (339292 Bytes). Die Venu 2 Plus wurde per Windows WPD als `OK` erkannt. Die Datei ist unter `Internal Storage/GARMIN/APPS/ShiftSenseV2.prg` sichtbar; die MTP-Ansicht meldet 331 KB und 24.09.2026 08:53. Ein Byte-für-Byte-Rückvergleich über MTP gelang nicht.
- Ausstehend: sicher trennen, auf der Uhr Start → Live-UI → manuellen Shift → Speichern prüfen, danach ein exportiertes FIT mit CRC und IDs 43–56 auswerten. Ohne diese Hardwarebestätigung und mindestens fünf Sitzungen/50 Referenzgrenzen bleibt der Pilot **nicht validiert**. Zusätzliche Garmin-Runden durch automatische Vorschläge sind für diesen Pilot zu erwarten und sollten beim Sichttest notiert werden.

## 2026-09-24 – Kurzer Hardware-Rundlauf

- Der Nutzer meldete für den ersten Test die vollständige Folge Startdialog → Live-UI → Shift-Taste → Speichern und eine auf der Uhr sichtbare Aktivität als funktionierend. Die Uhr war anschließend per USB verbunden; die neue Original-FIT-Datei wurde ausschließlich nach `analysis/private/` kopiert und bleibt per `.gitignore` außerhalb des Repositories.
- Die FIT-Datei ließ sich mit CRC-Prüfung dekodieren. Enthalten sind eine 27,571-s-Session, 27 FIT-Records mit 27 frischen Bewegungssamples ohne volle fehlende Sekunde, 27 Standard-HR-Samples, vier manuelle Grenzmarker und alle 14 Entwicklerfelder IDs 43–56 mit korrekten Namen/Message-Typen. Die anfänglich gemeldete Lücke war eine angebrochene letzte Sekunde; ein rot/grün getesteter Parser-Fix zählt nur vollständig abgelaufene Sekunden als fehlend (Python 10/10 Tests).
- Automatische Grenzvorschläge: **0**. Diese sehr kurze, überwiegend ruhige Bedienprobe ist kein repräsentativer Hockeytest; Precision/Recall und Zeitfehler sind daraus nicht belastbar. Der Pilot bleibt offen bis zu fünf vollständigen Sporteinheiten, mindestens 50 manuell markierten Grenzen und Akku-/Fehlerszenarien. Keine automatische Live-Zählung freigegeben.

## 2026-09-27 – Erste Inlinehockey-Einheit vom 26. September

- Die Venu 2 Plus war wieder per USB erreichbar. Zwei neue FIT-Dateien wurden nur nach `analysis/private/` kopiert; die kurze Datei ohne manuelle Grenzmarker wird nicht bewertet. Die längere Datei enthält 78,71 Minuten Inlinehockey, gültige CRC, 14/14 erwartete App-Felder, 4.680 FIT-Records, 4.678 Standard-HR-Records, 30 manuelle Grenzmarker und 14 dauerhafte automatische Grenzvorschläge (45 FIT-Laps einschließlich Schlussrunde).
- Der automatische Detektor traf diagnostisch **6 von 30** manuell protokollierten Grenzen innerhalb von ±10 Sekunden (14 Vorschläge; rechnerisch Precision 43 %, Recall 20 %, Medianfehler der sechs Treffer 3,4 s). Insbesondere automatische Starts kamen vielfach deutlich nach manuellen Starts. Dies ist **keine valide Genauigkeitsfreigabe**: Der Nutzer bestätigte einen vergessenen manuellen Marker innerhalb eines als 14,4 Minuten aufgezeichneten Shifts. Die Session hat daher eine unvollständige Referenz und wird nicht als eine der fünf validen Piloteinheiten gezählt. Keine Live-Automatik aktivieren.
- Bewegungsdaten sind plausibel unterschiedlich: Median `motion_mg` während manuell markierter Spielfeldphasen 109, auf der Bank 12; die vom Detektor verlangte stärkere Bewegung (`≥180 mg`) trat in etwa 30 % der Spielfeld- und 11 % der Bankrecords auf. Das deutet auf Trennpotenzial, aber auch einen zu strengen Startfilter hin. Wegen der lückenhaften Referenz und nur einer echten Einheit werden Schwellenwerte noch nicht auf diese Datei angepasst.
- Die anfängliche Zählung von 141 fehlenden FIT-Sekunden war durch starre Ganzsekunden-Bins überhöht. Die Datei enthält 4.659 eindeutige Sample-Nummern und 63 übersprungene Nummern; 21 FIT-Records wiederholten eine bereits geschriebene Nummer. Ein rot/grün geprüfter Parser-Fix zählt Sequenz- und echte Zeitlücken ohne Schwankungen um Sekundengrenzen als Ausfall zu deuten. Neuer Befund: **63 ungefähr sekundenlange unbeobachtete Samples** (ca. 1,3 % der Einheit), keine längere zusammenhängende Lücke; Python 12/12 Tests. Diese Auslassungen verhindern weiterhin die Freigabe vollständiger Bewegungs-Evidenz.
- Nutzerangabe Akku: vor Start **über 90 %**, danach **etwa 83 %**. Ohne exakte Start-/Endwerte und vergleichbare manuelle Basiseinheit ist daraus kein verlässlicher Mehrverbrauch der Hintergrund-Erkennung ableitbar.

## 2026-09-28 – Neue Anschub- und Distanzmessung: Prüfverfahren

Die praktische 20–30-m-Vorlage mit Messdefinitionen und Fehlerkennzahlen liegt unter [20-30m-distance-evaluation.md](20-30m-distance-evaluation.md). Sie ist vor der ersten längeren Einheit auszufüllen; die Roh-FIT-Datei bleibt unter `analysis/private/`.

- Der neue V2-Build berechnet live erkannte Anschübe, eine gleitende Kadenz und eine mit einem **nicht kalibrierten** Hockey-Bewegungsmodell geschätzte Distanz. Der Wert ist weder GPS-Distanz noch ein Garmin-nativer Distanzwert. Die dritte Uhrseite zeigt fehlende Daten als `--`, gültige Null als `0` und eine Teilabdeckung sichtbar an. Die manuellen Shift-Tasten bleiben maßgeblich.
- Für jede bekannte Strecke von **20–30 m** den Anfang und das Ende unabhängig markieren und die tatsächliche Strecke mit Hallenmarkierungen oder Maßband festlegen. Pro Versuch Anschübe unabhängig zählen (idealerweise Video oder zweite Person), nicht aus der Uhr ablesen. Mindestens fünf Wiederholungen je Eis und Inline getrennt sammeln; Antritt, Gleitphase, Richtungswechsel und Stickhandling getrennt notieren. Nur vollständig manuell markierte Shifts vergleichen. Fehler pro Versuch als `geschätzt − Referenz` in Metern und als prozentuale Abweichung berichten; Erkennungsfehler `erkannte − gezählte Anschübe` separat ausweisen. Aus einer guten Sensorabdeckung folgt **keine** hohe Messgenauigkeit.
- Die lokale Auswertung prüft FIT-CRC und Schema 4/5/6. Bei Schema 6 kommen Session-Gesamtsummen für Anschübe, geschätzte Zentimeter, kurze Anschübe und Sensorabdeckung hinzu; manuelle Schluss-Laps liefern Shift-Werte. Automatische Vorschlags-Laps mit FIT-Invalidwerten sind keine gemessenen Shifts. Ein fehlender FIT-Wert bleibt `null` statt `0`. Kumulierte Record-Werte werden nicht über einzelne gespeicherte Sekunden summiert, da Smart Recording Sekunden auslassen kann.
- Prüfstand vor Hardware: **119/119** Venu-2-Plus-Simulatortests und **19/19** Python-Tests. Der neue signierte App-Build wird nach der unabhängigen Review erneut erstellt. Eine vorhandene private Schema-4-Aufnahme wurde erneut mit CRC gelesen: 30 manuelle Marker, 4.722.428 ms Dauer; die neuen Anschubfelder bleiben erwartungsgemäß unbekannt. Das ist ein Kompatibilitätsnachweis, **kein** Distanz-Nachweis auf der Uhr.
- Für eine Abnahme fehlen noch ein auf der Venu 2 Plus erzeugtes Schema-6-FIT, ein Hardware-Rundlauf aller drei Seiten, bekannte Strecken mit unabhängig gezählten Anschüben sowie – nach Freigabe zur Connect-IQ-Beta-Verteilung – der sichtbare Garmin-Connect-Test. Die USB-Installation allein belegt keine Darstellung benutzerdefinierter Werte in Garmin Connect Mobile.

## 2026-09-28 – Schema-6-Testversion auf die Venu 2 Plus übertragen

- Release am Commit `bc979fe`: 369.804 Byte, SHA-256 `A06E8802191150811739AE817C97F26870CA63935EB4E378EC31803C6A4D0F9A`; separate lokale Kopie unter `watch-v2/bin/venu2plus/release-schema6/ShiftSenseV2.prg`. Der Build und die Tests waren vor der Übertragung erfolgreich.
- Windows erkannte die Venu 2 Plus als WPD-Gerät mit Status `OK`. Der Ordner `Internal Storage/GARMIN/APPS` war erreichbar, enthielt davor jedoch keine sichtbare `ShiftSenseV2.prg` für eine Binärsicherung. Nach dem Kopieren zeigte MTP die neue Datei mit 361 KB und Zeitstempel 28.09.2026 15:22. Ein Bytevergleich war nicht möglich.
- **Noch keine Hardware-Funktionsfreigabe:** Start, drei Live-Seiten, Tasten, Speicherung und FIT-Werte muss der Nutzer nach sicherem Trennen bestätigen. Vorher weder Sensor- noch Distanzgenauigkeit oder Garmin-Connect-Mobile-Anzeige als bestanden werten.

## 2026-09-28 – Geräteabsturz und Zeitstempel-Kompatibilität

- Die zuerst übertragene Schema-6-Version zeigte nach der Garmin-Startbestätigung `IQ!`. Das Uhr-Log lokalisiert den Absturz auf `MotionSource.onData`: `Could not find symbol 'timestamp'`. Das Venu-2-Plus-Gerätepaket bietet API 5.0.0; die Sensordaten-Zeitstempel sind laut Garmin erst ab 5.1.1 dokumentiert.
- Eine korrigierte, signierte Version prüft beide Zeitstempelfelder. Die Simulation bestand **121/121**, die lokale FIT-Auswertung **19/19** Tests. SHA-256 der neuen PRG: `19F291FDDE0E9C3A8B991186B1C1C228CEA1020EE38A2C7C72F2F53127A49425`; sie wurde unter `GARMIN/APPS/ShiftSenseV2.prg` sichtbar. Zum Zeitpunkt der Übertragung stand der Hardware-Rundlauf noch aus.
- Auf der Venu 2 Plus sind ohne Sensordaten-Zeitstempel Anschubanzahl, Kadenz und geschätzte Strecke **nicht verfügbar**, nicht `0`. Die Hauptseite mit HR und manuell markierten Shifts soll trotzdem vollständig funktionieren. Für diese Bewegungsmetriken braucht es einen gesondert entworfenen und validierten Zeitbasis-Fallback oder ein Gerät mit bestätigter 5.1.1-Sensor-API.
- **Nachtest auf der Uhr:** Der Nutzer meldete die angefragte App-Prüfung als positiv; der manuelle Shift-Zähler funktioniert ausdrücklich wieder. Kein erneutes `IQ!` wurde gemeldet. HR-Quelle und -Zahlen, neues Schema-6-FIT, Bewegungsseite und Garmin Connect Mobile sind dadurch noch nicht gesondert verifiziert.

## 2026-09-28 – Lokaler Schema-6-FIT-Rundlauf nach dem Fix

- Die neueste Uhrdatei `2026-09-28-21-25-03.fit` wurde ausschließlich unter `analysis/private/2026-09-28-confirmed-test/` abgelegt (8.662 Byte; SHA-256 `AF3E63D3BBF6C583A41E7BDD83A2F57063DEE15545DF71E8E9FA503BB5EA1B79`). Sie wird nicht ins Repository oder auf GitHub übernommen. Die FIT-CRC-Prüfung und strikte Dekodierung bestanden.
- Eine Schema-6-Sitzung begann um 19:25:03 UTC (21:25:03 MESZ) und dauerte 11,444 s. Enthalten sind elf FIT-Records, alle 30 erwarteten Entwicklerfeld-Beschreibungen und sämtliche IDs 43–72 in den vorgesehenen Record-/Lap-/Session-Nachrichten. Der Parser meldet elf frische aggregierte Bewegungssamples und keine volle Sample-/FIT-Lücke. Das belegt den FIT-Schreibpfad, nicht die Genauigkeit einer Bewegungsmessung.
- Zwei manuelle Grenzmarker (`ice` bei 4,860 s, `bench` bei 8,362 s) ergeben einen abgeschlossenen Shift von 3,502 s. Die Session speichert `shift_count = 1`, `time_on_ice = 3 s` und `average_shift_duration = 3 s`; die ganzzahligen FIT-Felder runden die Grenzzeiten ab. Sechs der elf Records enthalten Standard-HR-Werte von 73–78 bpm; die Session enthält AVG HR 75 bpm und Shift AVG HR 74 bpm. Die FIT-Daten identifizieren die aktive HR-Quelle **nicht**; ein Polar-H10-Einsatz ist damit nicht nachgewiesen.
- Anschübe, Kadenz und geschätzte Distanz sind im FIT ungültig/unbekannt (`null`), nicht als gemessene Null gespeichert. `motion_coverage_percent = 0` bezieht sich auf den zeitstempelabhängigen Anschubpfad; es widerspricht nicht den elf vorhandenen 1-Hz-Bewegungsmerkmalen des Shadow-Pilots. Diese Unterscheidung muss auch in Garmin Connect sichtbar bleiben.
- Es gibt keinen automatischen Grenzvorschlag. Precision/Recall `0` aus einem rein mechanisch erzeugten Kurzreport wären irreführend und werden für diese 11-s-Bedienprobe **nicht** als Leistungswerte berichtet. Die Datei zählt nicht als vollständige Hockey-Pilotsitzung. Ein lokales FIT belegt die gespeicherte Aktivität auf der Uhr, aber nicht ihre Anzeige in Garmin Connect Mobile, die dritte Live-Seite, die Polar-H10-Quelle oder eine Distanzgenauigkeit.
