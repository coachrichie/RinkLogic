# Beta 7: Remote-Kalibrierung und privater FIT-Rücklauf

Diese Anleitung gilt ausschließlich für den kontrollierten, nicht öffentlichen
Remote-Test von RinkLogic `0.2.0-beta.7`. Sie ersetzt keine Veröffentlichung im
Garmin Connect IQ Store. Es gibt keinen Portal-Upload, keine Cloud-Anbindung und
keinen automatischen Zugriff auf Garmin Connect.

## Verbindlicher Kandidat

| Merkmal | Freigegebener Wert |
| --- | --- |
| Quellcommit | `7fef4700d30088f9573cc41f1b14774b47bc4517` |
| Exportpaket | `RinkLogic-0.2.0-beta.7.iq` |
| Größe | `8.624.741` Byte |
| SHA-256 | `4E6A62C40B0AE9FB978CB702CF82854A784A9E98CD79FFF662C7DCC7A90D40DF` |
| App-ID | `4c7d5f9e2b484f0da6913b1c8e7f2a64` |
| FIT-Vertrag | Schema `12`, Modell `profile_height_v1+local_known_distance_v1` |

Der frühere Vorab-Build mit SHA-256
`918F13E499F338B3F3D81EE1D564C445697F39EE99E290BD305E0195F48D6CB8`
ist gesperrt und darf niemals verteilt oder installiert werden. Bei anderer
Größe, anderem Hash, anderer App-ID oder unbekannter Herkunft: Test stoppen.

Der freigegebene Container enthält 69 geprüfte, signierte Paketvarianten.
Automatisiert bestanden 275/275 Venu-2-Plus-Tests sowie zusätzliche
Responsive-Tests für Venu 2S, Forerunner 255S, Instinct 3 AMOLED und fēnix 9
Pro 51 mm. Die zuvor als P0 gesperrten Touchzonen und die semantische
Accepted-Laufanzeige wurden für diesen Kandidaten korrigiert. Der Remote-Test
prüft diese Gates trotzdem erneut auf echter Hardware. Das ist keine Behauptung,
alle 50 Ring-1-Modelle seien physisch getestet. `watch-v2/device-matrix.json`
bleibt die verbindliche Freigabematrix.

## Was der Testkoordinator vorbereitet

1. Den `.iq`-Container selbst gegen Größe und SHA-256 oben prüfen.
2. Produkt-ID der Uhr ermitteln und nur fortfahren, wenn sie in der Matrix als
   `release-enabled` in Ring 1 steht. Ring 2 ist ausgeschlossen.
3. Aus dem signierten Multi-Geräte-Container ausschließlich die zur Geräte-
   Part-Number gehörende PRG auswählen. Der `.iq`-Container wird nicht direkt
   nach `GARMIN/APPS/` kopiert.
4. SHA-256 der ausgewählten PRG berechnen und genau diesen Wert in den
   persönlichen Beta-7-Testauftrag eintragen. Der Auftrag verwendet
   Vertragsversion `3` und enthält in `return_email` genau eine geprüfte
   Rückgabeadresse des Koordinators. PRG, Auftrag und Windows-Testerassistent
   werden dem Tester über einen privaten Kanal bereitgestellt.
5. Für Eis und Inline getrennte Aufträge verwenden. Sportprofil, Kalibrierung
   und Rückgabepaket dürfen nicht zwischen den Sportarten vermischt werden.

Der Auftrag enthält nur eine pseudonyme Tester-ID, Geräte-ID, Sport, Protokoll,
erwarteten PRG-Hash und die Rückgabeadresse des Koordinators. Er enthält keine
Garmin-Zugangsdaten, Tester-Kontaktdaten oder Gesundheitsdaten. Eine echte
Rückgabeadresse bleibt ausschließlich im privaten lokalen Auftrag und wird
weder in den öffentlichen Beispielauftrag noch in das Rückgabe-ZIP übernommen.

## Installation durch den Tester

1. Uhr vollständig synchronisieren, mindestens 50 % laden und per USB mit dem
   Computer verbinden. Bei unbekanntem Modell oder nicht erreichbarem
   `GARMIN/APPS/`-Ordner stoppen und den Koordinator kontaktieren.
2. Hash der erhaltenen PRG berechnen:

   ```powershell
   Get-FileHash .\RinkLogic-0.2.0-beta.7.prg -Algorithm SHA256
   ```

   Er muss exakt dem `expected_prg_sha256` im persönlichen Auftrag entsprechen.
3. Die unveränderte PRG unter dem vom Koordinator vorgegebenen Dateinamen nach
   `GARMIN/APPS/` kopieren. Eine vorhandene RinkLogic-Version mit derselben
   App-ID wird ersetzt; keine zweite Kopie mit anderem Namen behalten.
4. Uhr sicher trennen, RinkLogic öffnen und prüfen, dass kein `IQ!`, kein
   abgeschnittener Pflichttext und keine überlappende Touchaktion erscheint.
5. Auf Touchgeräten jede sichtbare Aktion nur in ihrer beschrifteten Zone
   auslösen. Bei Tastenmodellen muss die Hervorhebung zur ausgeführten Aktion
   passen. Wenn ein Tap außerhalb der sichtbaren Aktion etwas auslöst: stoppen.

Die kompakte [Geräte-Installationscheckliste](../DEVICE-INSTALL-CHECKLIST.md)
begleitet diesen Schritt.

## Kalibrierung: genau 20,00 m und zehn akzeptierte Läufe

Die Strecke muss gerade, eben, sicher und mit Maßband oder verlässlichem
Messrad auf exakt 20,00 m markiert sein. Keine geschätzte Eislinien- oder
Hallendistanz verwenden. Vor jedem Lauf genug Platz zum Anfahren und Abbremsen
lassen; andere Personen dürfen nicht gefährdet werden.

1. Auf der Uhr das zum Auftrag passende persönliche Profil **Eis** oder
   **Inline** auswählen. Bei falschem Profil abbrechen und neu beginnen.
2. Kalibrierung starten. Jeder Lauf muss auf der Uhr genau einmal als
   **akzeptiert** erscheinen und den Zähler um genau eins erhöhen. Fehlender,
   doppelter oder unlesbarer Accepted-Status ist ein Stopgrund.
3. Läufe 1–5 ohne Puck- oder Stickhandling durchführen:

   | Lauf | Tempo |
   | --- | --- |
   | 1 | langsam |
   | 2 | schnell |
   | 3 | normal |
   | 4 | langsam |
   | 5 | schnell |

4. Läufe 6–10 mit Puck und Stickhandling in derselben Tempofolge durchführen:
   langsam, schnell, normal, langsam, schnell.
5. Nur bei zehn akzeptierten Läufen speichern. Eis- und Inline-Kalibrierung
   sind getrennte persönliche Profile; ein Faktor darf nicht übertragen werden.

Die 20 m und die Bedingung werden im Rückgabepaket als Protokollmetadaten
festgehalten. Sie sind keine unabhängige Streckenmessung durch die Uhr.

## Kontrolliertes Training

Nach erfolgreicher Kalibrierung wird ein separater Auftrag für
`normal-training` verwendet. Sportprofil erneut prüfen, Aktivität starten,
Shifts wie angeleitet markieren, anschließend stoppen und speichern. Absturz,
`IQ!`, Datenverlust, falsche Touchaktion oder unplausible Accepted-/Shiftanzeige
sofort notieren und keinen weiteren Lauf mit derselben Installation beginnen.

RinkLogic schreibt Distanz in eigene Connect-IQ-Entwicklerfelder. Beta 7
befüllt Garmins natives `total_distance` nicht. Eine leere native Garmin-
Distanz oder Garmin-Overview-Karte ist deshalb kein Null-Messwert; maßgeblich
sind die RinkLogic-Entwicklerfelder im Original-FIT. Die Distanz bleibt eine
experimentelle Schätzung und ist keine Leistungs- oder Gesundheitsdiagnostik.

## Original exportieren und lokal prüfen

1. Synchronisierung der gespeicherten Aktivität abwarten.
2. In Garmin Connect Web die richtige Aktivität öffnen und **Original
   exportieren** wählen. Die erhaltene FIT- oder ZIP-Datei nicht öffnen,
   konvertieren, neu packen oder inhaltlich bearbeiten.
3. Nur den Dateinamen nach dem Muster aus dem Auftrag anpassen; Umbenennen
   verändert die Bytes nicht:

   `<assignment-id>_<JJJJ-MM-TT>_<ice|inline>_<protocol>_original.<fit|zip>`
4. Den lokalen Windows-Testerassistenten öffnen und nacheinander Auftrag,
   Originalexport und den selbst gewählten lokalen Zielordner wählen. Der
   Assistent prüft lokal Schema, Identität, zehn Kalibrierungsabschnitte und
   Faktor. Er meldet sich nicht bei Garmin an und sendet nichts im Hintergrund.
5. Genau zehn deutsche Feedbackfragen beantworten. Keine Namen,
   E-Mail-Adressen, Gesundheitsangaben oder Informationen über Dritte in den
   Freitext schreiben.
6. Nach erfolgreicher Erstellung zeigt der Assistent einmal als Erinnerung und
   dauerhaft auf der Abschlussseite den vollständigen ZIP-Pfad, dessen SHA-256
   und die geprüfte `return_email` aus dem Auftrag. Genau dieses ZIP manuell als
   E-Mail-Anhang an die angezeigte Adresse senden.

Das Rückgabe-ZIP enthält den Originalexport byte-identisch, sichere
Diagnoseaggregate, die zehn Antworten und bei Kalibrierung eine lokal erzeugte,
analysevalidierte 10-Zeilen-Referenz. Der Fragebogen liegt darin als
`feedback.json`; zusätzliche lose FIT- oder Fragebogenkopien werden nicht
erzeugt. Das ZIP enthält weder Garmin-Anmeldedaten noch die Rückgabeadresse.
Der Assistent versendet keine E-Mail, öffnet weder Mailprogramm noch Browser,
lädt nichts hoch und bestätigt keinen Eingang.

## Sofort stoppen und nichts senden, wenn …

- Hash, Dateigröße, App-ID, Produkt-ID oder persönlicher Auftrag nicht passen;
- der gesperrte Hash `918F13E4…D6CB8` auftaucht;
- die Uhr nicht als Ring-1-Gerät freigegeben ist;
- Touchzonen überlappen oder die ausgeführte Aktion nicht zur Beschriftung passt;
- Accepted-Zähler oder Laufanzeige fehlt, doppelt zählt oder unlesbar ist;
- Eis-/Inline-Profil, Strecke, Reihenfolge oder Tempo nicht eingehalten wurden;
- `IQ!`, Absturz, Speicherfehler oder Datenverlust auftritt;
- der Assistent die Diagnose nicht mit **bestanden** abschließt;
- das Rückgabe-ZIP unerwartete Dateien enthält oder der Assistent einen Upload,
  Browserstart, Mailprogrammstart oder automatischen Versand anbietet.

In diesen Fällen nur Fehlercode, Uhrmodell, Firmware, sichtbaren Schritt und
den Zeitpunkt pseudonym an den Koordinator melden. FIT- und Logdateien bleiben
privat und werden nur nach ausdrücklicher Absprache übermittelt.
