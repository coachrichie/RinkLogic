# Entwicklungsjournal

Dieses Dokument begleitet die Entwicklung von ShiftSense Hockey. Es hält Entscheidungen, Implementierungsstände, Tests, Messergebnisse, Abweichungen und bekannte Risiken nachvollziehbar fest.

## 2026-09-15 – Projektanlage und Produktdesign

- Kanonischer Projektordner angelegt; sein lokaler absoluter Pfad bleibt privat.
- Bestehende Git-Historie und Designspezifikation übernommen.
- Arbeitsname `ShiftSense Hockey` gewählt; erweiterte Markenprüfung vor Veröffentlichung vorgesehen.
- Zwei getrennte Modi festgelegt: Eishockey und Inlinehockey.
- Garmin Venu 2 Plus und Polar H10 als primäre Referenzhardware benannt.
- Watch-first-Architektur, lokaler FIT-Import und lokale GPS-Kalibrierung freigegeben.
- Metrikkatalog, Gerätefreigabewellen, Datenschutz- und Validierungsstrategie freigegeben.
- Ausführliche Projektdokumentation und ein GitHub-Showcase nach Fertigstellung in den Lieferumfang aufgenommen.

## 2026-09-15 – Connect IQ-Watch-Grundlage

- SDK: Connect IQ SDK 9.2.0 (`connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2`).
- Java: Microsoft OpenJDK 17.0.20.1 LTS.
- Compiler: Connect IQ Compiler 9.2.0.
- Gerätepaket: `venu2plus`, Connect IQ API 5.0.0, Firmware 19.05 (Paket `006-B3851-00`).

## Dokumentationsregeln

- Jede wesentliche Architektur- oder Algorithmusentscheidung erhält Datum, Kontext, Entscheidung und Konsequenzen.
- Tests werden mit Gerät, Firmware, App-Version, Eingabedaten, Erwartung und Ergebnis protokolliert.
- Abgeleitete Metriken dokumentieren Formel, Einheit, Datenquelle, Qualitätsklasse und Modellversion.
- Fehlgeschlagene Versuche und bekannte Grenzen werden nicht aus der Historie entfernt.
- Personenbezogene Rohdaten werden nicht in das öffentliche Repository übernommen.
- Geheimnisse, Garmin-Schlüssel, Zertifikate und Kontodaten werden niemals eingecheckt.

## 2026-09-21 – Monkey-C- und Toybox-API-Abgleich

- Die Implementierung wurde gegen die lokal installierte Connect-IQ-API-Dokumentation geprüft.
- `UserProfile.Profile.weight` wird von Garmin in Gramm geliefert und nun korrekt in Kilogramm normalisiert; Größe bleibt gemäß API in Zentimetern.
- Das aktuelle Kalenderjahr für die Altersberechnung wird über `Time.Gregorian` ermittelt und ist nicht mehr fest codiert.
- Herzfrequenz-Events und hochfrequente Sensordaten verwenden getrennte, typisierte Callback-Methoden.
- RR-Intervalle des aktiven Herzfrequenzsensors werden aus `SensorData.heartRateData.heartBeatIntervals` gelesen. Dadurch kann der gekoppelte Polar H10 über Garmins aktiven HR-Kanal verwendet werden; die App kann den Sensorhersteller dabei nicht zuverlässig identifizieren.
- RR-only-Datenpakete bleiben gültig und aktualisieren die Datenqualität, ohne den zuletzt gemessenen Puls zu verwerfen.
- HR-Zonenzeiten, HR-Stichprobenzahl und Erholungsdauer werden beim Stoppen an die Sitzungszusammenfassung übergeben.
- Bekannte Plattformgrenze: Auf der Venu 2 Plus führt das Anlegen von mehr als 34 FIT-Contributor-Feldern zu einem nicht abfangbaren Systemfehler. Die neuen logischen IDs 35–42 sind deshalb registriert, werden auf diesem Gerät aber noch nicht physisch in FIT geschrieben.
- Noch nicht als vollständig angebunden zu bewerten sind Bewegungsmodell, GPS-Kalibrierloop, Schritte/Distanz/Kalorien sowie hockeyspezifische Trainings- und Ausdauerklassifikation. Diese benötigen die folgenden Implementierungs- und Hardware-Validierungsphasen.

## 2026-09-22 – V2-Aufzeichnung beenden

- Hardware-Rueckmeldung: Der native Startdialog fuehrt zur laufenden Live-Ansicht; Beenden war nicht moeglich, weil der Live-Delegate `onBack()` ohne Aktion quittierte und SessionRecorder weder Stop noch Save implementierte.
- Die Live-Ansicht zeigt nun „Stop & Speichern“. Touch, Select und Zurueck verwenden denselben Stopp- und Speicherpfad.
- Nach erfolgreichem Speichern erscheint „Gespeichert“. Bei einem Speicherfehler bleibt die gestoppte Session fuer einen erneuten Speicher-Versuch erhalten.
- Simulator: acht Tests bestanden, darunter eine echte Garmin-ActivityRecording-Session mit Start, Stop und Save. Hardwaretest auf der Venu 2 Plus steht noch aus.
- Hardware-Rueckmeldung des Nutzers: „Stop & Speichern“ funktioniert, und die Aktivitaet ist anschliessend auf der Venu 2 Plus sichtbar.

## 2026-09-22 – V2-Profil und Live-Herzfrequenz

- Garmin-Alter, Gewicht, Groesse, Ruhepuls und generische HR-Zonengrenzen werden im Hintergrund importiert. Fehlende oder unplausible Werte bleiben explizit nicht verfuegbar.
- Die aktive Garmin-Herzfrequenzquelle liefert Live-HR; ein gekoppelter Polar H10 kann somit als Quelle dienen, ohne dass die App den Hersteller behauptet.
- Das Live-UI zeigt aktuelle HR, Durchschnittspuls und aus dem importierten HR-Maximum berechnete Zone 0–5. Fehlende Werte werden mit `--` angezeigt.
- Sensorereignisse werden nach dem Stoppen freigegeben. Der erste Simulatorlauf bestand 17 Tests; anschliessend wurde die physische HR-Anzeige auf der Venu 2 Plus bestaetigt.
- Hardware-Rueckmeldung des Nutzers: HR, AVG und ZONE zeigten Zahlenwerte; „Stop & Speichern“ speicherte eine auf der Uhr sichtbare Aktivitaet. Details stehen in `docs/testing/V2-STAGE1-HARDWARE.md`.
- Der Abschlussreview fand Fehler bei fehlgeschlagenem Stop/Save/Start. Die Fehleransicht bietet nun Wiederholung und ein bestaetigtes Verwerfen der noch offenen Session; ein fehlgeschlagener Start verwirft die erzeugte Session nach Moeglichkeit sofort.
- Individuelle Garmin-HR-Zonengrenzen erhalten Vorrang vor der prozentualen HR-Maximum-Naeherung. Ein fehlgeschlagener HR-Sensorstart wird in der Live-Ansicht angezeigt, waehrend die Aktivitaetsaufnahme weiterlaufen kann.
- Die neuen Fehlerwege sind im Simulator getestet. Sie wurden auf der echten Uhr nicht kuenstlich provoziert.
- V2-Live-UI Stufe 2: Die Anzeige enthaelt Aufnahmezeit, Live-HR, Durchschnitts-HR, HR-Zone, Shift-Anzahl, Dauer des letzten abgeschlossenen Shifts, Durchschnittsdauer abgeschlossener Shifts und kumulierte Spielzeit. Die untere Taste schaltet manuell zwischen Bank und Shift, die obere Taste speichert die Aufnahme. Touch-Eingaben auf der Live-Seite werden konsumiert, damit kein versehentliches Speichern durch Antippen erfolgt.
- Beim Start eines Shifts steigt der Zaehler. Die Spielzeit waechst waehrend des laufenden Shifts; letzter und durchschnittlicher Shift bleiben bis zum Abschluss unveraendert. Beim Speichern wird ein laufender Shift abgeschlossen. Die Uhr-eigene automatische Touchsperre und Display-Abschaltzeit werden nicht ueberschrieben.
- Der V2-Shift-Zaehler ist vorerst ausschliesslich manuell; Gyro-/Bewegungs- und HR-gestuetzte Auto-Erkennung ist nicht implementiert. Die Shift-Metriken sind in dieser Stufe Live-Werte und noch keine FIT-Developer-Felder. Ein Review zeigte, dass `BehaviorDelegate` auf der Venu 2 Plus auch Touch-Gesten als Auswaehlen/Zurueck abbildet. Die Live-Seite verwendet deshalb `InputDelegate` mit rohen physischen Tastenereignissen; Touch und Wischen werden ohne Aktion konsumiert. Simulator: 33 Tests bestanden; signierter Venu-2-Plus-Build erfolgreich. Hardwareabnahme steht aus.
- Das Live-UI erhielt auf Basis des Nutzerfotos ein helles Rund-Layout mit sechsteiligem Farbring, HR-Zonen-Hervorhebung, drei zweispaltigen Metrikzeilen und grosser Aufzeichnungsdauer. Die Bezeichnung lautet in beiden Sprachressourcen `TIME ON ICE`. Die obere Statuszeile ist bewusst kurz (`BENCH`/`BANK` oder `ON ICE`), damit sie im schmalen Kreisabschnitt lesbar bleibt.
- Die Darstellung wurde mit sieben neuen Monkey-C-Render-Tests entwickelt; alle 40 V2-Tests und der signierte Release-Build bestanden. Ein unabhaengiger Review fand zwei Fehler im Farbring (Bogenrichtung und Zonenzuordnung), die anschliessend testgestuetzt behoben wurden. Physische Sichtpruefung steht aus, da die Simulatorfenster-Aufnahme in dieser Umgebung nicht startete. Details: `docs/testing/V2-STAGE2-UI.md`.

## 2026-09-23 – HR-Zone im Farbring hervorheben

- Nach Sichtung des Hardwarefotos wurde der Farbring als aktive HR-Zonenanzeige praezisiert: ein helles, breites Segment fuer die aktuelle Zone; gedimmte, schmale Segmente fuer die anderen Zonen.
- Zonenschriftzug und Live-HR erhalten kontrastreiche Varianten derselben Farbfamilie. Bei `ZONE --` bleibt die Anzeige neutral und der Ring ohne Hervorhebung.
- 42 von 42 V2-Tests bestanden; signierter Venu-2-Plus-Build erstellt und am 23.09.2026 auf die verbundene Uhr kopiert. Hardware-Abnahme der Farbwirkung steht noch aus.

## 2026-09-23 – Sichtpruefung und vertikale Abstaende

- Ein neues Hardwarefoto bestaetigte den Live-Puls, Zone 0 und das dazugehoerige betonte blaue Ringsegment. Die Anzeige fuer andere Zonen muss noch real getestet werden.
- Der Zonenschriftzug und der Speicherhinweis waren auf dem runden Display zu dicht an Nachbartexten. Die Zoneneile sowie der Fehlerhinweis erhielten vertikale Zentrierung; der Timer wurde auf `FONT_MEDIUM` umgestellt und zusammen mit dem Speicherhinweis anhand der Geraete-Schrifthoehen positioniert.
- Drei gezielte Render-Tests wurden rot/gruen durchlaufen; 45 von 45 V2-Tests und der signierte Release-Build bestanden. Physische Sichtpruefung der neuen Abstaende steht noch aus.

## 2026-09-23 – Hockey-Ready-Bildschirm und Verbindungsstatus

- Vor Garmins unveraendertem Dialog `Start recording?` zeigt V2 jetzt einen eigenen Ready-Bildschirm mit Hockey-Hintergrund, Logo, Telefon- und Pulssignal sowie Startflaeche. Die obere Taste kann ebenfalls starten. Danach folgt bei Zustimmung das bestehende Live-UI.
- Das Telefon-Symbol liest `System.getDeviceSettings().phoneConnected`. Das Herz wird nur bei einem innerhalb von fuenf Sekunden empfangenen Garmin-HR-Sample gruen. Die Ready-Ansicht gibt den HR-Sensor vor dem Garmin-Startdialog frei; die Aufzeichnung uebernimmt ihn danach erneut.
- `Sensor.getRegisteredSensors()` kann ab API 3.2 ein in Garmin gespeichertes H10 anhand seines Namens melden. Ein deaktivierter Eintrag erscheint getrennt als `H10 GESPEICHERT / AUS`. Dies beweist **nicht**, dass der H10 aktuell verbunden ist oder den angezeigten Puls liefert; der aktive Eintrag zeigt deshalb `H10 GEKOPPELT / QUELLE ?`. Ohne eindeutig benannten Eintrag erscheint `H10 NICHT BESTAETIGT`; ein in Garmin umbenannter H10 kann dabei unerkannt bleiben.
- Neue originale Bildressourcen und wiederverwendbares Favicon liegen unter `shared/branding/`; Herkunft und Generierung sind in `docs/branding/READY-SCREEN.md` dokumentiert. Die Uhr verwendet angepasste kleine PNGs als Startbild und Launcher-Icon.
- Ein Code-Review bestaetigte den Startablauf, fand aber eine Mehrdeutigkeit bei gespeicherten/deaktivierten H10-Eintraegen und eine zu grosse Start-Touchflaeche. Beides wurde mit neuen Tests korrigiert. Die grossen Ready-Bildressourcen werden beim Redraw wiederverwendet und beim Verlassen freigegeben.
- Der Simulator bestand 59 von 59 V2-Tests. Signierter `venu2plus`-Build: SHA-256 `ED2F1227332B86A2BD0519D3D30DBFF57BA735C21DC153B3F9CE919D35BDDA55`. Physische Anzeige, Startfolge und Sensorstatus stehen noch zur Pruefung auf der Uhr aus.
- Die PRG wurde auf die per USB erkannte `Venu 2 Plus` nach `Internal Storage/GARMIN/APPS/ShiftSenseV2.prg` kopiert. Windows zeigte danach `313 KB` und `23.09.2026 21:29`; eine bytegenaue Rueckpruefung ist ueber MTP nicht moeglich. Sicheres Trennen und Nutzer-Sichttest stehen aus.

## 2026-09-23 – Korrektur nach Ready-Hardwaretest

- Der Nutzer sah nach dem nativen `Start recording?` erneut den Ready-Bildschirm statt des Live-UI. Garmins Bestätigungsdialog entfernt sich nach `onResponse()` automatisch aus dem View-Stack. V2 startet die Aufnahme nun erst aus einem einmaligen Timer-Callback nach dieser Dialog-Rueckkehr; der Ready-Bildschirm gibt zuvor HR-Ereignisse und Bildressourcen frei. Dadurch kann er die Live-HR-Quelle beim anschliessenden View-Wechsel nicht mehr deaktivieren.
- Die namensabhaengige Suche nach `H10` in registrierten Garmin-Sensoren wurde entfernt. Sie erkannte umbenannte Brustgurte nicht und sagte nichts ueber die aktive HR-Quelle aus. Das Herz ist bei frischen HR-Daten jetzt blau statt gruen; `QUELLE UNBEKANNT` macht klar, dass Garmin den Wert auch vom optischen Sensor liefern kann. Nur das Telefon-Symbol zeigt weiterhin seine echte Verbindungsinformation gruen.
- Die neuen Start- und Status-Regressionstests wurden zunaechst rot und nach der Korrektur gruen ausgefuehrt. Die physische Abnahme des UI-Wechsels und der HR-Anzeige bleibt erforderlich; ein Simulator-Test beweist die Garmin-Dialog-Reihenfolge auf der Venu 2 Plus nicht.
- 60 von 60 V2-Simulatortests und der signierte `venu2plus`-Build bestanden. SHA-256 der Release-PRG: `CF4D67E4151F5AC61EEEE3F8CC3EFC09E4966BD0870B606B8E513B5F433A85CA`. Die Datei wurde auf die per USB erkannte Venu 2 Plus in `Internal Storage/GARMIN/APPS/ShiftSenseV2.prg` kopiert; Windows zeigte sie dort als `312 KB` mit Aenderungszeit `23.09.2026 22:03`. Ein Byte-fuer-Byte-Vergleich der MTP-Datei ist nicht erfolgt. Nach sicherem Trennen muss der Nutzer Ready → Garmin-Dialog → Live-UI, laufende Aufzeichnungsdauer sowie Stop/Speichern auf der Uhr pruefen.

## 2026-09-23 – Shift-Status vor dem ersten Wechsel

- Der Nutzer bestaetigte, dass Start, Live-UI und Speichern auf der Venu 2 Plus funktionieren. `BENCH` unmittelbar nach Aufzeichnungsbeginn war missverstaendlich: Es ist zu diesem Zeitpunkt noch kein Shift absolviert, und die App ermittelt keine tatsaechliche Bankposition.
- Die Live-Statuszeile zeigt jetzt `NO SHIFT`/`KEIN SHIFT` vor dem ersten manuellen Shift, `ON ICE` waehrend eines laufenden Shifts und erst danach `BENCH`/`BANK`. Der Anfangszustand hat eine neutrale Textfarbe. `UPPER: SAVE`/`OBEN: SPEICHERN` bleibt als Hinweis auf die obere Taste unveraendert.
- Der Regressionstest wurde rot/gruen ausgefuehrt; die komplette V2-Suite bestand mit 60 von 60 Tests. Signierter `venu2plus`-Build: SHA-256 `98DFD14F61638DE963C94914635A1AE673F6481E9B6CDC21B9769033B6FF3B5A`. Die Uhr war zum Zeitpunkt dieses Builds nicht per USB erkennbar; diese Version wurde noch nicht auf sie kopiert.

## 2026-09-23 – Automatische Shift-Vorschläge als Pilot

- Die bestehende manuelle Shift-Zeitachse ist in einen eigenen Baustein ausgelagert. Vorschläge der Bewegungserkennung beeinflussen weder den Live-Zähler noch `TIME ON ICE`.
- Das Armband-Bewegungssignal wird, falls von Garmin verfügbar, in kurzen Intervallen ohne GPS verarbeitet. Die Erkennung verlangt mehrere zusammenhängende aktive beziehungsweise ruhige Sekunden; Sensorausfälle erzeugen keinen Bankwechsel. Ein Startfehler der Bewegungsschnittstelle lässt Aufzeichnung und manuelle Taste funktionsfähig.
- Zehn neue, optionale FIT-Felder mit den stabilen IDs 43–52 und Schema 4 speichern kompakte Bewegungsmerkmale, Vorschlagsgrenzen und manuelle Tastengrenzen. Die alte Registry 1–42 blieb unverändert. Ein Fehler der optionalen FIT-Schreibfunktion darf Stop/Speichern nicht blockieren.
- Die lokale Python-Auswertung prüft FIT-CRC, lehnt alte Dateien ohne Schema 4 ab und vergleicht manuelle Grenzen mit automatischen Vorschlägen. Personenbezogene FIT-Dateien bleiben unter dem ignorierten Ordner `analysis/private/`.
- 78/78 Connect-IQ-Simulatortests, signierter Venu-2-Plus-Build und 7/7 Python-Tests bestanden. Die Anlage aller zehn Felder in einer echten Garmin-Simulatorsession wurde geprüft. Ein exportiertes Schema-4-FIT wurde noch nicht dekodiert; entsprechend sind die Feldwerte auf der Uhr und die Genauigkeit **nicht validiert**.
- Der Hardware-Testbogen steht in `docs/testing/V2-AUTO-SHIFT-PILOT.md`. Die Venu 2 Plus meldete beim Verbindungscheck Windows-WPD-Status `Unknown`; es erfolgte noch keine Installation dieses Pilot-Builds. Die ursprüngliche V2-Start-/Speicherfolge wurde zuvor vom Nutzer bestätigt, muss nach diesem Umbau aber erneut geprüft werden.

## 2026-09-24 – Review-Härtung des Shadow-Pilots

- Die Review deckte vier Risiken auf: nur kurz gesetzte FIT-Ereignisbits, veraltete Sensordaten bei ausbleibenden Callbacks, arithmetisch addierte Ereignisbits und zeitlich zu spät markierte Bewegungsgrenzen. Die manuelle Live-Zählung bleibt unverändert.
- Neu sind dauerhafte FIT-Lap-Marker für automatische Vorschläge (IDs 55–56) und frische Sample-Identität/-Zeit (IDs 53–54). Die Registry umfasst damit 14 physisch angelegte V2-Felder 43–56; frühere Feld-IDs wurden nicht umgedeutet. Das Ereignisbit-Feld 48 bleibt reserviert, wird aber nicht mehr ausgewertet. Automatische Vorschläge erzeugen zusätzliche Garmin-Runden; ob die Uhr diese wie erwartet exportiert, ist noch unbestätigt.
- Die 20-Sample-Auswertung verwendet jetzt `slice` statt `Array.remove(0)`, das in Monkey C einen Wert und keinen Index entfernt. Vorschlagszeit ist der geschätzte Bewegungsbeginn, nicht erst die spätere Bestätigung. Tests: 80/80 Monkey C, 9/9 Python; signierter Build SHA-256 `8A14EBE4D47E613A6E2631103DFB19724423C63934A87062BF35028888DAF305`. Die PRG ist auf der per WPD als `OK` erkannten Venu 2 Plus im Ordner `GARMIN/APPS` sichtbar (MTP: 331 KB, 24.09.2026 08:53), aber der Hardware-Start und FIT-Rundlauf stehen noch aus.

## 2026-09-24 – Erster Hardware-FIT-Rundlauf

- Der Nutzer bestätigte die Bedienfolge einschließlich Speicherung auf der Venu 2 Plus. Die unmittelbar danach auf der Uhr gefundene FIT-Datei wurde in den ignorierten lokalen Ordner `analysis/private/` kopiert. CRC und Schema 4 sind lesbar; IDs 43–56 erscheinen vollständig in den vorgesehenen FIT-Nachrichtentypen.
- Die Testsession dauerte 27,571 Sekunden und enthält 27 Standard-HR- und 27 frische Bewegungsrecords sowie vier manuelle Shift-Grenzen. Es wurden keine automatischen Grenzen vorgeschlagen; die ruhige Kurzbedienung erlaubt noch keine Genauigkeitsbewertung. Der Parser hatte die angebrochene letzte Sekunde zunächst als volle Lücke gezählt; ein reproduzierender Test schlug vor der Korrektur fehl und besteht danach zusammen mit der vollständigen Python-Suite (10/10). Für die abgeschlossenen 27 Sekunden zeigt der Report jetzt keine fehlende volle Sekunde.
- Hardware-Start und FIT-Rundlauf sind damit erstmals belegt. Empirische Hockey-Genauigkeit, zusätzliche Lap-Marker bei echten Automatikvorschlägen, Langzeitakku und weitere Garmin-Modelle bleiben ungeprüft.

## 2026-09-27 – Erste lange Inlinehockey-FIT-Datei

- Eine 78,71-minütige Inlinehockey-Aktivität vom 26. September wurde von der Venu 2 Plus in den ignorierten lokalen Ordner `analysis/private/` übernommen. Die CRC-Prüfung bestand; die FIT-Datei enthält alle 14 Entwicklerfelder, 30 manuelle und 14 automatische Lap-Grenzen sowie 4.680 Records. Damit ist auch der automatische Lap-Export erstmals hardwareseitig belegt.
- Der lokale Diagnose-Score trifft nur 6/30 manuelle Grenzen innerhalb von 10 s; automatische Starts kommen oft zu spät. Der Nutzer bestätigte einen vergessenen manuellen Marker in einem scheinbar 14,4-minütigen Shift. Deshalb ist diese Einheit keine vollständige Referenz und zählt nicht zum Fünf-Sitzungen-/50-Grenzen-Freigabegate. Die Live-Zählung bleibt manuell, die Erkennung wird nicht anhand dieser einen lückenhaften Referenz getunt.
- Ein Datenqualitätscheck fand 4.659 eindeutige Sample-Nummern und 63 übersprungene Nummern. Die bisherige Sekunden-Binning-Methode meldete 141 Lücken, weil geringe Zeitjitter an Sekundengrenzen als ganze Ausfälle erschienen. Zwei neue Tests reproduzierten falsch-positive und übersehene FIT-Lücken vor der Korrektur; danach 12/12 Python-Tests. Der Bericht meldet nun 63 annähernd sekundenlange Auslassungen, ohne sie als Bankbewegung zu interpretieren. Akkustand laut Nutzer vor Start über 90 %, danach etwa 83 %; ein exakter Verbrauch oder Automatik-Mehrverbrauch lässt sich daraus nicht bestimmen.

## 2026-09-27 – Shift-Durchschnittspuls im Live-Dial

- Der Nutzer gab den Entwurf frei: Rechts oben auf der Hauptseite steht nun `SHIFT AVG HR` statt des Durchschnittspulses der gesamten Aufnahme. Er wird aus gültigen HR-Samples seit dem letzten manuellen Shift-Start berechnet. Auf der Bank bleibt der Wert des zuletzt beendeten Shifts stehen. Vor dem ersten gültigen Shift-Sample und zu Beginn eines neuen Shifts steht `--`; ein bei Stop/Speichern noch offener Shift wird abgeschlossen.
- Der bisherige `AVG HR`-Wert für die gesamte Aufnahme bleibt auf einer zweiten HR-Seite erhalten. Horizontales Wischen wechselt zwischen beiden Seiten, vertikales Wischen bleibt ohne Wirkung auf die Aufnahme. Untere und obere Taste behalten Shift-Umschaltung beziehungsweise Stop/Speichern. Die automatische Shadow-Erkennung beeinflusst keinen der angezeigten Shift-Werte.
- Rot/grün geprüft: neue Tests für nur innerhalb des Shifts gezählte HR-Samples, Zurücksetzen bei neuem Shift, Abschluss beim Speichern, Hauptseiten-Beschriftung und Seitenwechsel ohne Aufnahme-/Shift-Änderung. Gesamte Monkey-C-Suite: 84/84; signierter `venu2plus`-Build SHA-256 `F735E060FAC12A99A5E7CA942A9E290839E1880340ED240595DC8A59E5E0A0A5`. Zum Zeitpunkt des Builds war die Version auf der echten Uhr noch nicht visuell geprüft.
- Nach dem Build wurde die Venu 2 Plus am 27.09.2026 von Windows als WPD-Gerät mit Status `OK` erkannt. Der oben genannte Build wurde nach `Internal Storage/GARMIN/APPS/ShiftSenseV2.prg` kopiert; die MTP-Ansicht zeigt `333 KB` und `27.09.2026 22:11`. Die Quelle hatte 341.148 Byte und den genannten SHA-256. Ein bytegenauer Rückvergleich der MTP-Datei war nicht möglich. Sicheres Trennen und Sicht-/Bedientest auf der Uhr stehen noch aus.

## 2026-09-27 – Hardware-Testlauf nach Upload

- Der Nutzer meldete den Testlauf des auf die Venu 2 Plus übertragenen Builds als `okay`.
- Einzelne Prüfkriterien wurden in dieser Kurzmeldung nicht separat aufgeschlüsselt; die detaillierte Evidenz bleibt der Simulator-Suite, dem Build-Hash und dem dokumentierten Geräte-Upload zugeordnet.

## 2026-09-28 – Schema-6-Bewegungspilot vorbereitet und übertragen

- Auf der dritten Live-Seite werden erkannte Anschübe, gleitende Kadenz sowie geschätzte Shift-/Gesamtdistanz angezeigt. Der Modellansatz ist unkalibriert und benötigt reale Hockey-Referenzen. Die manuellen Shift-Grenzen bleiben maßgeblich.
- FIT-Schema 6 belegt 30 optionale V2-Felder 43–72. Die Record-Zähler sind kumuliert; nur manuelle Schluss-Laps erhalten Shift-Metriken, automatische Vorschlags-Laps FIT-Invalidwerte. Ohne gültige Bewegungssamples bleiben Anschub- und Distanzwerte unbekannt statt scheinbar gemessen null. Fehlgeschlagene optionale Schreibvorgänge verhindern Speichern nicht.
- Nach Review-Korrekturen bestanden **119/119** Venu-2-Plus-Simulatortests und **19/19** Python-Tests. Der signierte Release-Build am Commit `bc979fe` hatte **369.804 Byte**, SHA-256 `A06E8802191150811739AE817C97F26870CA63935EB4E378EC31803C6A4D0F9A`, und liegt lokal unter `watch-v2/bin/venu2plus/release-schema6/ShiftSenseV2.prg` (Git-ignoriert). Eine ältere private Schema-4-FIT-Datei wurde erneut mit gültiger CRC dekodiert; neue Felder bleiben darin korrekt unbekannt.
- Am 28.09. wurde die Venu 2 Plus per Windows-WPD als `OK` erkannt. Vor dem Kopieren war unter `Internal Storage/GARMIN/APPS` keine `ShiftSenseV2.prg` sichtbar, die hätte gesichert werden können; eine Sicherung der tatsächlich installierten vorherigen Binärdatei war deshalb nicht möglich. Die neue Datei erschien nach der Übertragung als `ShiftSenseV2.prg` mit **361 KB** und Windows-Zeitstempel `28.09.2026 15:22`. MTP ermöglicht hier keinen verlässlichen Byte-für-Byte-Rückvergleich. Der Nutzertest auf der Uhr, ein Schema-6-FIT-Rundlauf, bekannte Strecken und die Garmin-Connect-Mobile-Darstellung stehen noch aus.

## 2026-09-28 – Startabsturz auf der Venu 2 Plus

- Der Nutzer sah unmittelbar nach dem bestätigten Aufnahmestart `IQ!`. Die Uhr lieferte `GARMIN/APPS/LOGS/CIQ_LOG.BAK` mit `Symbol Not Found Error: timestamp` in `MotionSource.onData` (Zeile 80 des fehlerhaften Builds). Die private Logkopie liegt ausschließlich unter `analysis/private/diagnostics/` und wird nicht veröffentlicht.
- Ursache: Der neue Anschubpfad griff ohne Fähigkeitsprüfung auf `AccelerometerData.timestamp` beziehungsweise `GyroscopeData.timestamp` zu. Die Garmin-API dokumentiert diese Felder erst ab API-Level 5.1.1; das für die Venu 2 Plus installierte Gerätepaket ist API 5.0.0. Trotz angeforderter Zeitstempel lieferte der reale Callback das Symbol nicht. `try/catch` fing diesen Laufzeitfehler auf der Uhr nicht ab.
- Regressionstests mit Sensorobjekten ohne jeweiliges Zeitstempelfeld reproduzierten den Symbolfehler vor dem Fix. Der neue Pfad prüft jetzt beide Felder vor dem Zugriff. Ohne sie bleiben Bewegungsmerkmale für den Shadow-Shift-Pilot verfügbar, Anschub-/Distanzwerte dagegen ausdrücklich unbekannt; HR, manuelle Shifts und Garmin-Aufnahme laufen unabhängig davon.
- Nach dem Fix bestanden **121/121** Venu-2-Plus-Simulatortests und **19/19** Python-Tests. Signierter Gerätebuild: 370.156 Byte, SHA-256 `19F291FDDE0E9C3A8B991186B1C1C228CEA1020EE38A2C7C72F2F53127A49425`, lokale Sicherung `watch-v2/bin/venu2plus/release-timestamp-guard/ShiftSenseV2.prg`. Die Uhr zeigte die neue PRG im App-Ordner als 361 KB mit Zeitstempel `28.09.2026 21:14`; ein MTP-Bytevergleich war nicht möglich.
- **Zum Zeitpunkt des Uploads noch offen:** Nutzer bestätigt nach sicherem Trennen Start → Live-UI → Speichern ohne `IQ!`; anschließend neues FIT und Anzeige in Garmin Connect prüfen. Keine Aussage zur Genauigkeit der Anschub-/Distanzschätzung auf der Venu 2 Plus, solange dort keine Zeitstempel verfügbar sind.

### Hardware-Rückmeldung nach dem korrigierten Build

- Der Nutzer meldete die angefragte App-Prüfung auf der Venu 2 Plus als **positiv** und bestätigte ausdrücklich, dass der **manuelle Shift-Zähler wieder funktioniert**. Damit ist der zuvor reproduzierte `IQ!`-Startabsturz in diesem Kurztest nicht erneut aufgetreten. Die einzelnen HR-Zahlen, ein neues Schema-6-FIT, die dritte Bewegungsseite und die Garmin-Connect-Mobile-Darstellung wurden in dieser Rückmeldung nicht separat belegt.
- Der Start-/Bedienungsfehler kann für diesen Gerätebuild als behoben protokolliert werden; die sportwissenschaftliche Genauigkeit der automatischen Vorschläge oder Distanz wird daraus nicht abgeleitet.

## 2026-09-29 – Schema-6-FIT des korrigierten Gerätebuilds geprüft

- Nach erneuter USB-Verbindung wurde die neueste FIT-Datei der Venu 2 Plus vom 28.09. um 21:25 MESZ nur in den ignorierten privaten Analyseordner kopiert. SHA-256 der 8.662-Byte-Originaldatei: `AF3E63D3BBF6C583A41E7BDD83A2F57063DEE15545DF71E8E9FA503BB5EA1B79`. Die strikte FIT-Dekodierung einschließlich CRC bestand.
- Die 11,444-s-Sitzung enthält elf Records, sechs Standard-HR-Records (73–78 bpm), alle 30 Schema-6-Feldbeschreibungen/IDs 43–72, zwei manuelle Grenzmarker und einen abgeschlossenen Shift von 3,502 s. Session-Werte: ein Shift, 3 s `TIME ON ICE`, AVG HR 75 bpm, Shift AVG HR 74 bpm. Die HR-Sensorquelle ist im FIT nicht belegt.
- Anschubzahl, Kadenz und Distanz sind erwartungsgemäß unbekannt, während die älteren aggregierten Bewegungsmerkmale elf frische Samples ohne volle Lücke liefern. `0 %` Anschubabdeckung bedeutet deshalb nicht `0` Bewegung. Keine automatischen Vorschläge in diesem Kurztest; keine auswertbare Precision/Recall und keine Distanzvalidierung. Detailbefund und nächster Test im Pilotprotokoll.

## 2026-10-06 – Zeitstempellose Venu-2-Plus-Sensorpakete

- Nach dem 22-m-Referenztest wurde die technische Ursache der leeren Anschub-/Distanzfelder eingegrenzt: Die Venu 2 Plus meldet Connect-IQ-API 5.0.0, während die Sensor-Sample-Zeitstempel laut lokalem SDK erst ab API 5.1.1 verfügbar sind. Der bisherige `MotionSource` gab daher trotz vorhandener Bewegungs- und Rotationsmittelwerte kein Paket an den `PushDetector` weiter.
- Der neue, ausdrücklich experimentelle Fallback ordnet zeitstempellose Beschleunigungs- und Gyroskop-Samples nach angeforderter Abtastrate relativ zum Callback an. Zu große, unvollständige, überlappende oder nicht paarbare Pakete werden nicht als volle gültige Messzeit ausgegeben. Das Live-Distanzfeld zeigt bei dieser Zeitbasis `~`; die manuelle Shift-Bedienung und das FIT-Schema bleiben unverändert. [Methodik und kurzer Hardwaretest](testing/venu2plus-estimated-sensor-timebase.md).
- Simulator und lokale Auswertung sind grün (142/142 Monkey C, 24/24 Python). Der signierte Gerätebuild wurde am 6. Oktober auf die Venu 2 Plus übertragen und aus dem Geräteordner mit identischem SHA-256 zurückgelesen. Der Start-, Speicher- und Sensorsignaltest **auf der Uhr** steht noch aus. Die 22-m-Genauigkeit und die Anschubzählung bleiben unvalidiert.

## 2026-10-06 – Lokale Kalibrierungsauswertung für den Samstagstest

- Die CSV-Auswertung akzeptiert eine **leere** unabhängig gezählte Anschubzahl. Distanzfehler bleiben auswertbar, der Anschubfehler bleibt dann unbekannt statt als Null oder Uhrwert erfunden zu werden. Gruppenmediane verwenden nur vorhandene unabhängige Anschub-Referenzen.
- 0 % oder ungültige Sensorabdeckung schließt einen Versuch von der Distanzbewertung aus. Die `session_id` des CSV-Protokolls wird als zeitlich äquivalenter, zeitzonenbewusster Startzeitpunkt gegen die eingelesene FIT-Sitzung geprüft; fremde oder fehlende Sitzungen werden abgewiesen.
- Ein Gesamtergebnis wird erst als `eligible` markiert, wenn für jede protokollierte Sportart **beide** Bedingungen (ohne Puck / mit Puck und Stickhandling) mindestens fünf gültige Wiederholungen enthalten. `eligible` bedeutet nur ausreichend Material zur Prüfung, keine wissenschaftliche Freigabe. Das [Samstagsprotokoll](testing/2026-10-10-inline-distance-test.md) beschreibt den Probe- und Streckentest. Keine Uhr-Datei wurde in diesem Schritt verändert.

## 2026-10-08 – Trainingszusammenfassung auf Uhr und in Garmin Connect

- Nach erfolgreichem Speichern zeigt V2 drei Seiten: Trainingsdauer/Ø Puls/Maximalpuls, Shiftzahl/Eiszeit/Bankzeit sowie Ø Shift/längster Shift/Ø Puls pro Shift. Fehlende Werte erscheinen als `--`; ab einer Stunde wird `HH:MM:SS` verwendet. Wischen und Hardwaretasten wechseln die Seiten. Auch ein erfolgreicher Speicher-Retry öffnet denselben eingefrorenen Snapshot.
- Schema 7 berechnet Shiftstatistik, Median, Work-to-Rest, ganzzahlige Shift-Dichte, HF-Zonen, Zeit über 90 % HFmax, qualifizierte Shift-HF und Recovery nach 30/60 Sekunden. Eine Shift-HF benötigt mindestens 70 % gültige Sekunden. Recovery-Laps werden bis zum abgeschlossenen Fenster, zum nächsten Shift oder zum Speichern zurückgehalten und höchstens einmal geschrieben.
- Der Venu-2-Plus-Simulator erzeugt beim 17. Session-Developer-Feld einen nicht abfangbaren Systemfehler, obwohl die dokumentierte 32-Byte-Grenze noch nicht überschritten ist. Das produktive Testschema verwendet deshalb 16 Session-Felder mit 24 Byte und 30 Contributor-Felder insgesamt. Durchschnittliche, kürzeste, längste und Median-Shiftdauer sind kompakte UINT8-Sekundenwerte; Werte über 254 Sekunden werden ungültig statt geklemmt. Der Schemamarker steht in Record-ID 73.
- Garmin Connect erhält alle gewünschten Session-Kernwerte in IDs 74–89. Statt drei zusätzlicher Top-3-Session-Felder zeigt Lap-ID 95 die Ø HF jedes qualifizierten Shifts; die intensivsten drei sind dadurch direkt in der Rundentabelle vergleichbar. Lap-IDs 93/94 enthalten den vorzeichenbehafteten HF-Abfall nach 30/60 Sekunden. Die alten Connect-Bewegungssummen 67–70, interne Shadow-Records 43–49/53–54 und die Anschubkadenz 64 werden in diesem Build nicht angelegt; kumulierte Anschübe/Distanz und Shift-Bewegungswerte bleiben erhalten.
- Frische Nachweise auf dem lokal zusammengeführten `master`: **163/163** Venu-2-Plus-Simulatortests und signierter Build bestanden. PRG: 405.404 Byte, SHA-256 `D516AC7EA48FEE2A5CD7F04EED99F9038F1A866B37D2B96B73594F4C69F02DF6`. Der genaue [Hardware- und Garmin-Connect-Test](testing/V2-POST-TRAINING-SUMMARY.md) ist dokumentiert. Installation, physische Drei-Seiten-Anzeige, synchronisierte Connect-Felder und exportiertes Schema-7-FIT sind noch nicht bestätigt.
