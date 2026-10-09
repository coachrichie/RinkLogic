# V2-Live-UI – Pruefung Stufe 2

Datum: 2026-09-22
Geraet: Garmin Venu 2 Plus
Status: Simulator bestanden; Hardware-Sichttest des neuen Rund-Layouts offen
PRG SHA-256: `4870122398861D0AE38EDF704A93C59F828E7C5739C9F8E3EE270FDFE52CF552`

## Bedienung und Definitionen

- Obere Taste: Aufnahme stoppen und speichern.
- Untere Taste: Shift starten bzw. beenden. Tippen loest auf der Live-Seite keine Aktion aus; horizontales Wischen wechselt seit dem Build vom 27.09.2026 nur die Datenseite.
- Der Shift-Zaehler steigt beim Start eines Shifts.
- Eiszeit/Time on Ice ist die Summe abgeschlossener Shifts plus die laufende Shift-Dauer.
- Letzter Shift und Durchschnittsdauer beruecksichtigen nur abgeschlossene Shifts; vor dem ersten Abschluss erscheint `--`.
- Beim Speichern wird ein noch laufender Shift abgeschlossen.
- Automatische Shift-Zählung ist nicht aktiv. Die spätere Shadow-Erkennung schreibt nur Vorschläge in die FIT-Datei und ändert keine Live-Werte. Garmin Auto Lock und Display-Timeout bleiben Geraeteeinstellungen; die App aktiviert weder Dauerlicht noch eine eigene Sperre.
- Die Shift-Werte werden derzeit nur waehrend der Aktivitaet angezeigt. Ihre Persistenz in FIT ist ein spaeterer Schritt.

## Bisherige Verifikation

- 33 von 33 Monkey-C-Tests auf `venu2plus` bestanden.
- Signierter Release-Build erstellt.
- Der Review fand eine Touch-Gesten-Kollision in Garmins `BehaviorDelegate`. Der Live-Bildschirm verarbeitet nur rohe physische Tasten (`KEY_ESC`/`KEY_ENTER`) als Shift-/Speicheraktion. Wischen hatte in diesem damaligen Build keine Wirkung; seit dem 27.09.2026 kann horizontales Wischen ausschliesslich die Datenseite wechseln.
- Die finale signierte PRG wurde nach `GARMIN/APPS/ShiftSenseV2.prg` auf die verbundene Venu 2 Plus kopiert; die Geraeteansicht zeigt 123 KB und den aktualisierten Zeitstempel 22:14. Der Start nach sicherem Trennen ist noch nicht bestaetigt.
- Nicht physisch verifiziert: Lesbarkeit aller Felder auf dem AMOLED-Display, Zuordnung der unteren Taste, Eingaben bei gesperrtem Touchscreen und tatsaechliches Einsetzen von Auto Lock/Display-Timeout.

## Hardware-Testfolge

1. Unter `Einstellungen > System > Auto Lock` die automatische Touchsperre aktivieren und unter `Display > Waehrend Aktivitaet > Timeout` die gewuenschte Zeit waehlen.
2. App oeffnen und Aufnahme starten. Pruefen, ob alle sieben Felder ohne Abschneiden lesbar sind.
3. Untere Taste druecken: `SHIFTS` muss 1 zeigen und `TIME ON ICE` anwachsen. Nach etwa 20 Sekunden erneut druecken: letzter und durchschnittlicher Shift muessen etwa `00:20` anzeigen.
4. Nach Ablauf der eingestellten Zeit pruefen, ob Garmins Touchsperre/Display-Timeout greift. Anschliessend pruefen, ob die untere Taste weiterhin einen Shift schalten kann (gegebenenfalls erst nach dem von Garmin verlangten Entsperren).
5. Obere Taste druecken und pruefen, ob die Aktivitaet gespeichert wird. Falls der Shift dabei laeuft, muss die angezeigte Zeit bis zum Stopzeitpunkt zaehlen.

## Rund-Layout nach Nutzerreferenz (2026-09-22)

- Helles rundes Zifferblatt mit sechs farbigen Ringsegmenten. Das zur aktuellen Garmin-HR-Zone passende Segment wird breiter gezeichnet; bei unbekannter Zone gibt es keine Hervorhebung.
- Oben steht kompakt `BENCH` bzw. `ON ICE`, darunter die HR-Zone oder ein Hinweis auf fehlenden HR-Sensor.
- Drei durch Linien getrennte Datenzeilen zeigen nebeneinander: Live HR / Avg HR, Shifts / Last Shift, Avg Shift / Time on Ice. Die gesamte Aufzeichnungsdauer steht gross unten.
- Die Anzeige verwendet in beiden Sprachressourcen ausdruecklich `TIME ON ICE`, nicht `Eiszeit`. Die englische Testressource prueft diese Zeichenfolge direkt.
- Tastenverhalten und automatische Geraete-Sperre wurden nicht veraendert. Die App erzwingt weder Dauerlicht noch eine eigene Entsperrung.
- 40 von 40 Monkey-C-Tests auf `venu2plus` bestanden, darunter Render-Tests fuer die Bezeichnung, den runden Hintergrund, sechs Ringsegmente, Trennlinien, kompakten Status, kurze nicht ueberlappende Boegen und die Hervorhebung der Garmin-Zonen 0 und 5. Der signierte Release-Build war erfolgreich.
- Der unabhaengige Code-Review fand zunaechst eine falsche Bogenrichtung und eine um eins verschobene Zuordnung der Garmin-HR-Zone zum Ring. Beides wurde mit zunaechst fehlschlagenden, danach bestandenen Tests korrigiert.
- Offene Abnahme: Das lokale Werkzeug zur Aufnahme des Simulatorfensters konnte nicht gestartet werden. Lesbarkeit, Kontrast und moegliches Abschneiden auf der echten Venu 2 Plus muessen deshalb anhand eines Fotos bestaetigt werden.

## Ergänzung vom 27.09.2026: SHIFT AVG HR

- Hauptseite: `SHIFT AVG HR` rechts oben zeigt den laufenden Mittelwert gültiger HR-Samples im aktuellen manuellen Shift, auf der Bank den Wert des letzten abgeschlossenen Shifts. Ohne gültigen Shift-Puls erscheint `--`.
- Ein horizontaler Wisch öffnet die HR-Seite mit `LIVE HR`, `AVG HR` der gesamten Aufnahme und `SHIFT AVG HR`. Ein weiterer horizontaler Wisch kehrt zurück. Shift- und Speicher-Tasten bleiben auf beiden Seiten gleich. Die Garmin-Touchsperre wird nicht ausgeschaltet; nach aktivem Auto Lock ist vor dem Wischen gegebenenfalls die übliche Entsperrung nötig.
- Für den nächsten Hardwaretest: nach Start zuerst `SHIFT AVG HR --` prüfen, mit der unteren Taste einen Shift starten und HR-Werte abwarten, Shift beenden und den stehenbleibenden Mittelwert prüfen; danach zur HR-Seite wischen und `AVG HR` der Gesamteinheit ablesen. Die Lesbarkeit beider Seiten und die unveränderte obere/untere Taste bitte auf der Uhr bestätigen.
- 84/84 Simulator-Tests und signierter Venu-2-Plus-Build bestanden; SHA-256 `F735E060FAC12A99A5E7CA942A9E290839E1880340ED240595DC8A59E5E0A0A5`. Zu diesem Zeitpunkt noch nicht auf der Uhr geprüft.
- Übertragung am 27.09.2026: Venu 2 Plus per Windows WPD als `OK` erkannt; `ShiftSenseV2.prg` ist nach dem Kopieren unter `Internal Storage/GARMIN/APPS/` sichtbar (MTP: `333 KB`, `27.09.2026 22:11`). Die MTP-Ansicht liefert keinen bytegenauen Rückvergleich. Nach sicherem Trennen bitte die oben beschriebene Hardware-Testfolge ausführen; die Funktion der neuen Version ist noch nicht auf der Uhr bestätigt.

## Uebertragung auf die Venu 2 Plus (2026-09-23)

- Die per USB verbundene Uhr wurde als `Venu 2 Plus` erkannt (Windows-WPD-Status `OK`).
- Der signierte Build mit dem oben angegebenen SHA-256 wurde nach `Internal Storage/GARMIN/APPS/ShiftSenseV2.prg` kopiert. Die Geraeteansicht zeigte danach `125 KB` und den Zeitstempel `23.09.2026 08:22`.
- Die Geraeteansicht liefert fuer MTP-Dateien keine verlaessliche bytegenaue Groesse oder Ruecklese-Hash. Daher gilt die Uebertragung als sichtbar, aber nicht als bytegenau verifiziert.
- Noch ausstehend: sicheres Trennen, Start der App auf der Uhr, Foto des Live-UI und physische Pruefung der Tasten und der automatischen Sperre.

## HR-Zonenfarben nach Hardwarefoto (2026-09-23)

- Das Foto `UI live.jpg` zeigte eine laufende Aufzeichnung mit `LIVE HR --`, `AVG HR 72` und `ZONE --`. Der Durchschnitt bleibt nach einer frueheren Messung erhalten; die Zone benoetigt dagegen einen aktuellen HR-Wert. Bei fehlendem aktuellem Wert sind alle Ringsegmente gedimmt.
- Fuer Garmin-Zonen 0 bis 5 bleibt die bestehende Reihenfolge der Ringfarben erhalten: Blau, Gruen, Gelb, Orange, Rot, Violett. Nur das Segment der aktuellen Zone wird hell und 16 Pixel breit gezeichnet; die anderen sind abgedunkelt und 6 Pixel breit.
- Der Zonenschriftzug und der Live-Puls verwenden einen dunkleren, auf dem hellen Zifferblatt lesbaren Farbton derselben Farbfamilie. Die Zonen-Zahl bleibt zusaetzlich sichtbar, damit die Information nicht allein von Farbe abhaengt.
- Die Ermittlung der Zone, die Tastensteuerung und die Uhr-Sperre wurden nicht geaendert. Zwei neue Render-Tests wurden vor der Implementierung fehlschlagend und danach bestanden ausgefuehrt; die vollstaendige V2-Suite bestand mit 42 von 42 Tests.
- Signierter `venu2plus`-Build: SHA-256 `37B29367840E0B4AB44A4E8A6F48725ACDECD0D027F5D41C982825934D8E3F61`. Die PRG wurde auf die per USB verbundene Venu 2 Plus nach `GARMIN/APPS/ShiftSenseV2.prg` kopiert; die Geraeteansicht zeigte `126 KB` und `23.09.2026 08:46`. Bytegenaue Rueckpruefung ist ueber MTP nicht verfuegbar. Sicheres Trennen und Hardware-Sichttest der neuen Farbwirkung stehen aus.
- Der Code-Review fand keine kritischen oder wichtigen Fehler. Die gedimmten blauen und violetten Segmente koennten auf dem AMOLED wegen ihres geringen Kontrasts schwer zu sehen sein; das bleibt Teil der physischen Sichtpruefung.

## Vertikale Abstaende nach Hardwarefoto (2026-09-23)

- Das Foto `20260923_084852.jpg` bestaetigte `LIVE HR 91`, `ZONE 0` und das betonte blaue Ringsegment auf der Venu 2 Plus. Der Farbring funktioniert damit sichtbar fuer Zone 0; andere Zonen bleiben hardwareseitig ungetestet.
- Das Foto zeigte zugleich zu geringe Abstaende zwischen `ZONE 0` und den HR-Ueberschriften sowie zwischen Aufzeichnungsdauer und `UPPER: SAVE`.
- Der Zonentext und der Hinweis auf fehlenden HR-Sensor werden nun vertikal zentriert. Der Timer verwendet `FONT_MEDIUM`; Timer und Speicherhinweis werden anhand der realen Schrift-Hoehen des Geraets mit einer Luecke platziert. Messwerte und Tastenbelegung bleiben unveraendert.
- Drei neue Render-Tests schlugen vor der jeweiligen Korrektur fehl und bestanden danach. Die komplette V2-Suite bestand mit 45 von 45 Tests. Signierter Build: SHA-256 `717C0E5E9126123C2627FAC9520CE975F50603B470E3EF39158BAEEA76E37FB0`.
- Die korrigierten Abstaende sind noch nicht auf der echten Uhr bestaetigt.

## Neuer Ready-Bildschirm (2026-09-23)

- Referenz: Nutzerfoto `cardio statr.jpg`; die neue Eishockeygrafik und das Logo sind eigenstaendige, neu generierte Assets und keine Kopie des Garmin-Bildes.
- Ablauf: Ready-Bildschirm -> Startflaeche/obere Taste -> nativer `Start recording?`-Dialog -> Live-UI. Ablehnung fuehrt zur Ready-Ansicht zurueck.
- Das Telefon-Symbol ist nur bei `phoneConnected` gruen. Das Herz-Symbol zeigt nur ein frisches, systemseitig geliefertes HR-Signal, **keine verifizierte Brustgurtquelle**. Die H10-Zeile beschreibt ausschliesslich den Garmin-Pairing-Eintrag; `QUELLE ?` macht die offene Herkunft sichtbar. Ein gespeicherter, aber deaktivierter H10 wird als `H10 GESPEICHERT / AUS` unterschieden. Ein umbenannter H10 kann als nicht bestaetigt erscheinen.
- Testfolge auf der Venu 2 Plus: H10 angelegt und in Garmins Sensor-Menue verbunden, App starten, Telefon- und Herzfarbe beobachten, H10-Hinweis lesen, Start druecken, Dialog bestaetigen, Live-HR/Zone pruefen, Shift per unterer Taste starten/beenden, per oberer Taste speichern. Danach denselben Startbildschirm ohne H10 testen; Herz darf nicht allein wegen des gespeicherten Pairings als H10-Nachweis interpretiert werden.

Nachtrag vom 23.09.2026: Die vorstehenden H10-Ready-Anzeigen wurden nach dem Hardwaretest entfernt. Die aktuelle Ready-Ansicht zeigt bei frischen HR-Werten ein blaues Herz und stets `QUELLE UNBEKANNT`; gruen bleibt allein dem bestaetigten Telefonstatus vorbehalten. Nach `Start recording?` muss unmittelbar das Live-UI mit laufender Dauer erscheinen. Diese konkrete Venu-2-Plus-Abnahme steht fuer den korrigierten Build noch aus.
- Simulator: 59 von 59 V2-Tests bestanden, darunter Status- und Startflaechen-Grenzfaelle. Release-PRG: SHA-256 `ED2F1227332B86A2BD0519D3D30DBFF57BA735C21DC153B3F9CE919D35BDDA55`.
- Diese PRG wurde auf die per USB erkannte `Venu 2 Plus` nach `Internal Storage/GARMIN/APPS/ShiftSenseV2.prg` kopiert. Windows zeigte dort `313 KB` und `23.09.2026 21:29`. Die MTP-Ansicht erlaubt keine bytegenaue Ruecklesepruefung. Sicheres Trennen und Hardware-Sichttest stehen noch aus.

## Hardware-Abnahme nach Upload (2026-09-27)

- Der Nutzer meldete den Testlauf des zuletzt übertragenen Builds als `okay`.
- Einzelne Kriterien wurden in dieser Kurzmeldung nicht getrennt protokolliert. Der Build gilt damit als praktisch bestätigt; bei späteren Problemen bitte den betroffenen Schritt (Start, Live-UI, SHIFT AVG HR, Wischen, Shift-Taste oder Speichern) separat melden.
