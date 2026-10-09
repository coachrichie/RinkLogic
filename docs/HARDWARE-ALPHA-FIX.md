# Hardware-Alpha-Korrektur, 17.09.2026

Auslöser: Beim ersten physischen Venu-2-Plus-Test waren Profilbearbeitung und Navigation unklar; eine Aufnahme ließ sich aus Nutzersicht nicht starten.

## Nachgewiesene Ursachen und Grenzen der Diagnose

- Profil- und Modus-Delegates ignorierten Touch-Koordinaten. Jeder Tap führte weiter bzw. öffnete den Startdialog. Die Profilbearbeitung hing von verborgenen Page/Menu-Aktionen ab; Rücksetzen der getesteten HF max fehlte.
- Feste Pixelpositionen und lange Hinweise nutzten runde Displays schlecht aus. Rechtecke für Darstellung und Touch-Routing werden jetzt aus derselben Bildschirmgeometrie berechnet; Textbreite wird vor der Fontwahl gemessen.
- Die Liveansicht zeigte weder laufende Zeit noch HR. Es gab keinen Aktualisierungstimer. Der bisherige SensorData-Listener liefert Bewegungs-/RR-Batches; für HR ist der dokumentierte `Sensor.enableSensorEvents`-Listener mit `Sensor.Info.heartRate` nötig.
- Der bisher irreführend benannte Test `confirmedStartUsesTheRealSessionController` benutzte einen Fake. Er heißt jetzt `confirmedStartInvokesControllerAndEntersRecording`; zwei separate Tests verwenden tatsächlich `FitSessionFactory`, einer davon zusätzlich die echten Sensoradapter.
- Alle Startfehler waren undifferenziert. Eine Ursache des konkreten Garmin-Gerätefehlers wurde noch nicht anhand eines Geräte-Logs bestätigt. Stufen-/Feldcodes machen einen Wiederholungsversuch auswertbar.

## Umsetzung

Profil: klar hervorgehobene Alter-/HF-max-Zeilen, sichtbare Minus/Plus-/Auto-Steuerung, separates Weiter. Modus: drei wählbare Zeilen und separater Start. Auf runden Anzeigen bleiben die zentralen Bedienelemente innerhalb der runden Fläche.

Live-Leistung: REC, verstrichene Dauer, aktuelle HR, Prozent-/HF-Zone, durchschnittliche HR, Shifts, Eiszeit. Live-Events: getrennte manuelle Hits/Pässe/Schüsse. Beide Seiten besitzen eigene Shift- und Stoppflächen; der Stopp erfordert weiterhin eine Bestätigung. Die blaue Auswahl ermöglicht die Tastenbedienung. Der Timer wird bei `onShow` gestartet und bei `onHide` oder erfolgreichem Stop beendet; Sensoraufzeichnung läuft während eines offenen Bestätigungsdialogs weiter.

Die Live-Zonen verwenden die aufgelöste Spieler-HF-max (getestet > Garmin > altersbasiert). Die Grenzen und Mittelwertdefinition stehen in der Gerätecheckliste. Standard-HR in der Garmin-Aufzeichnung bleibt die von Garmin gewählte Quelle; die App behauptet keine bestätigte H10-Quellenidentifikation.

FIT-Schema v2 erweitert die v1-Registry ohne Änderung bestehender Bedeutungen um UINT16-Sessionfelder 32=manuelle Hits, 33=manuelle Pässe, 34=manuelle Schüsse. Der Record-Payload bleibt 26 Byte. 14 Pflichtfelder werden vor optionalen Analytikfeldern reserviert. Scheitert ein optionales Feld, endet die optionale Allokation; Pflichtaufzeichnung/Marker/Summary bleiben nutzbar. Fehlende optionale Felder bleiben fehlend, werden nicht unter anderen IDs geschrieben. Scheitert ein Pflichtfeld, blockiert der Start mit genau dieser ID. Unverfügbare optionale Felder werden protokolliert.

## SDK-Referenzen

Verwendet wurden die installierten Connect-IQ-9.2.0-Dokumente zu `WatchUi.BehaviorDelegate`, `WatchUi.ClickEvent.getCoordinates`, `Graphics.Dc.getTextWidthInPixels`, `Sensor.enableSensorEvents`, `Sensor.Info.heartRate`, `Timer.Timer`, `System.println`, `ActivityRecording.Session.createField/start/stop/save` und `FitContributor`.

Garmins dokumentiertes Watch-App-Limit ist 256 Byte pro FIT-Nachricht. Der Venu-2-Plus-Simulator akzeptierte beim echten Sitzungsversuch sowohl die bisherigen 31 als auch die erweiterten 34 Felder. Daraus folgt keine physische Garantie; es gibt hier aber keinen Beleg für eine pauschale 16-Feld-Grenze.

## Verifikation und noch offene Gerätetests

Regressionsfälle wurden vor ihrer Implementierung im Simulator rot ausgeführt: Profil-Tap, Modus-Tap, fehlende Live-HR/Eventdaten, optionaler FIT-Feldausfall, Event-Summary, Start-Fehlercodes und Profilrücksetzung per Taste. Bestehende Tests bleiben erhalten; schemaabhängige Tests prüfen jetzt v2 und adressieren Fake-Felder anhand stabiler IDs statt einer Allokationsreihenfolge.

Der Simulator bestätigte echte Session-/Live-Lebenszyklen mit Start, Marker, Stop, Save. Das ersetzt weder eine echte H10-Verbindung noch einen Geräte-FIT-Export. Eine exportierte FIT-Datei war bei den automatischen Simulatorläufen zunächst nicht vorhanden; API-Erfolg und tatsächlich exportierte Datei werden ausdrücklich getrennt dokumentiert.

Physische Abnahme: lesbare DE-Anzeige, Touch-Treffer, Tastenfallback, sekündlich laufende REC-Zeit, HF mit/ohne H10 und bei Aussetzern, Profileinstellung dauerhaft gespeichert, Marker/Bankzeit, Events, Stop-Abbruch/Save und tatsächliche Garmin-Connect/FIT-Übernahme. Erst diese Abnahme kann bestätigen, dass der gemeldete Recording-Fehler auf der Uhr behoben ist.
