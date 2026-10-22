# RinkLogic Beta 6 – Remote-Test mit manueller FIT-Rückgabe

**Stand:** 22. Oktober 2026

**Geplanter erster Mehrnutzer-Test:** ab Montag, 26. Oktober 2026

**Zielversion:** `0.2.0-beta.6`, Internal Version `6`, FIT-Schema `12`

**Status:** Gesprächsseitig freigegebener Entwurf; schriftliche Review ausstehend

## 1. Ziel

Mehrere räumlich getrennte Tester sollen RinkLogic auf unterstützten Garmin-Uhren installieren und nach einem einheitlichen Protokoll testen können. Die App zeichnet alle zur Bewertung der automatischen Shift-Erkennung und der Distanz pro erkanntem Anschub erforderlichen Diagnosedaten in die Original-FIT-Datei. Nach jeder Einheit exportiert und sendet der Tester diese Datei manuell über einen privaten Übertragungskanal.

Beta 6 verbessert nicht automatisch das Modell. Sie erzeugt eine nachvollziehbare, pseudonyme Datengrundlage, aus der spätere Modelländerungen getrennt entwickelt und auf zurückgehaltenen Spielern geprüft werden können.

## 2. Erfolgskriterien

Der Remote-Test darf beginnen, wenn:

- mindestens fünf volljährige Tester mit mindestens zwei unterstützten Garmin-Gerätefamilien registriert sind;
- für jedes gemeldete Gerät ein passender, signierter und geprüfter Build bereitsteht;
- ein entfernter Tester Installation, Aufzeichnung, Synchronisierung und Originalexport ohne Entwicklerzugriff vollständig durchführen konnte;
- manuelle Shift-/Bankmarker und automatische Kandidaten im FIT eindeutig getrennt sind;
- eine Einheit ohne manuelle Marker keine automatischen Kandidaten als bestätigte manuelle Shifts ausweist;
- FIT-Schemaversion in jeder Datei und App-Build, Commit sowie Modellkennung über das signierte Release-Manifest und das Referenzformular nachvollziehbar sind;
- geschätzte Distanz in den vorgesehenen RinkLogic-Developer-Feldern konsistent gespeichert wird;
- ein gültiges persönliches Kalibrierungsprofil einen Neustart überlebt, vor Trainingsstart sichtbar ist und nur nach ausdrücklicher Aktivierung die Distanz verändert;
- ein fehlendes, ungültiges oder beschädigtes Kalibrierungsprofil sicher auf das unveränderte Basismodell zurückfällt;
- das Kadenz-Shadow-Modell aus denselben Läufen reproduzierbar berechnet werden kann, ohne die angezeigte oder gespeicherte Distanz zu verändern;
- private FIT-Dateien weder in GitHub noch in öffentliche Chats oder Issues gelangen;
- Testanleitung, Einwilligung, Dateibenennung und Auswertungsprotokoll veröffentlicht beziehungsweise bereitgestellt sind.

Der Pilot ist kein wissenschaftlicher Genauigkeitsnachweis. Eine neue Distanz- oder Shifterkennungslogik wird erst nach getrenntem Training und Hold-out-Test aktiviert.

## 3. Umfang von Beta 6

### 3.1 Bestandteil

- Remote-Verteilung über Garmin Connect IQ Store, sobald verfügbar;
- gerätespezifische PRG-Dateien als dokumentierter Fallback für Tester mit Computer und Datenkabel;
- Shadow Mode für automatische Shift-/Bank-Kandidaten;
- unveränderte manuelle Shiftsteuerung als primäre Referenz;
- FIT-Schema 12 mit versionierter Diagnostik und aktivem persönlichem Kalibrierfaktor;
- korrekte geschätzte Distanz in den RinkLogic-Developer-Feldern;
- lokale, ausdrücklich aktivierte Kalibrierung auf einer bekannten Strecke;
- beschreibende Shadow-Auswertung der Beziehung zwischen Kadenz und effektiver Schrittlänge;
- Schutz gegen Pseudo-Shifts bei Einheiten ohne manuelle Marker;
- eindeutige Trennung von On-Ice-, Bench- und Garmin-Schluss-Lap;
- standardisiertes Eis-/Inline-Testprotokoll;
- manuelle private Rückgabe der Original-FIT-Datei und eines kurzen Referenzformulars;
- lokale, reproduzierbare Analysewerkzeuge für die eingesendeten Dateien.

### 3.2 Nicht Bestandteil

- eigener Cloud-Upload aus der Watch-App;
- RinkLogic-Backend, Benutzerkonto oder Gerätetoken;
- Garmin Activity API;
- automatische Übertragung von FIT-, Herzfrequenz- oder Sensordaten;
- kontinuierlicher Rohsensorstream;
- globales Modelltraining;
- automatische Aktivierung persönlicher Kalibrierungswerte;
- distanzwirksame Kadenzkorrektur;
- GPS-Pflicht oder GPS-Kalibrierung;
- Trainer-, Team- oder Mehrnutzerportal;
- öffentlich gespeicherte Testerdaten.

Cloud- und Activity-API-Integration bleiben mögliche spätere Vorhaben und benötigen eine neue Architektur-, Datenschutz- und Implementierungsfreigabe.

## 4. Testerregistrierung und Datenschutz

Jeder Tester erhält eine zufällige Kennung wie `T7K4P9`. Kontaktdaten und Trainingsdateien werden getrennt geführt. Die Registrierung erfasst nur:

- Kontaktadresse für Testkommunikation;
- exaktes Garmin-Modell und Firmwareversion;
- Betriebssystem des Installationscomputers;
- Eis, Inline oder beide Oberflächen;
- dominante Hand und Uhrenarm;
- optionale Körpergröße für eine ausdrücklich experimentelle, getrennte Auswertung;
- Einwilligungsversion und Zeitstempel.

Gewicht und BMI verändern die Distanz pro erkanntem Anschub nicht. Herzfrequenzdaten sind Teil der Garmin-Aktivität; ihre Verarbeitung muss in der Testinformation ausdrücklich genannt werden. Video ist optional und benötigt eine separate Zustimmung. Ohne eigenen Prozess für Sorgeberechtigte nehmen am ersten Remote-Test nur Volljährige teil.

FIT-Dateien werden maximal 90 Tage für Pilotprüfung und reproduzierbare Analyse aufbewahrt. Ein Widerruf beendet die weitere Verwendung; noch zuordenbare Pilotdaten werden innerhalb von sieben Kalendertagen gelöscht, soweit keine gesetzliche Pflicht entgegensteht.

## 5. Remote-Verteilung

### 5.1 Bevorzugter Weg

Nach Freigabe im Garmin Connect IQ Store erhalten Tester den Store-Link und installieren die zum Gerät passende Version über Garmin Connect.

### 5.2 Fallback per PRG

Da Garmins Developer-Beta nicht außerhalb des Entwicklerkontos sichtbar ist, wird zusätzlich ein deutlich gekennzeichnetes GitHub-Pre-Release vorbereitet. Es enthält keine privaten Daten:

```text
RinkLogic-0.2.0-beta.6-remote-test/
├── README-FIRST.md
├── INSTALL-WINDOWS.md
├── INSTALL-MACOS.md
├── TEST-PROTOCOL.md
├── PRIVACY-AND-CONSENT.md
├── SHA256SUMS.txt
└── devices/
    ├── <garmin-product-id-a>/RinkLogic.prg
    └── <garmin-product-id-b>/RinkLogic.prg
```

Alle PRGs werden mit demselben langfristig gesicherten RinkLogic-Schlüsselpaar gebaut. Manifest, Dateiname und Release-Manifest nennen Garmin-Produkt-ID, Commit, App-Version, internen Build, Modellversion, FIT-Schema und SHA-256-Prüfsumme. Ein Tester erhält nur den für sein registriertes Gerät bestimmten Downloadlink.

Tester ohne Store-Zugang und ohne kompatiblen Computer samt Datenkabel können in dieser Runde nicht teilnehmen.

## 6. Watch-App-Verhalten

### 6.1 Startseite und Tastensteuerung

Nach dem App-Start besitzt die Startseite zwei eindeutige Hardwarepfade:

- die untere Taste startet unmittelbar ein normales Training mit der aktuell gewählten Oberfläche und dem dafür aktiven oder fehlenden Kalibrierungsprofil;
- die obere Taste öffnet eine Auswahlseite mit `KALIBRIERUNG` und `EXIT`.

Auf der Auswahlseite wechselt die obere Taste zyklisch zwischen den beiden Einträgen; die untere Taste bestätigt die hervorgehobene Auswahl. Eine direkte Touch-Auswahl bleibt zusätzlich möglich. `EXIT` beendet die App ohne Aktivitätsdatei. Ein Zurückkehren aus der Auswahlseite darf weder eine Session anlegen noch Kalibrierungsdaten verändern.

### 6.2 Manuelle Referenz

Manuelle Shift-/Bankmarker bleiben die angezeigte und gespeicherte operative Referenz. Ein On-Ice-Start, ein Bench-Start und ein Sitzungsende müssen monoton und eindeutig gespeichert werden. Die auf der Uhr angezeigte Shiftzahl zählt nur bestätigte On-Ice-Phasen. Für eine Genauigkeitsbewertung der tatsächlichen Übergangszeit reichen manuelle Tastendrücke allein nicht aus; dafür ist synchronisiertes Video oder eine unabhängige zweite Annotation erforderlich.

### 6.3 Shadow Mode

Die automatische Erkennung läuft parallel und ohne Einfluss auf die Bedienung. Sie schreibt nur experimentelle Kandidaten:

- `auto_on_ice_candidate`;
- `auto_bench_candidate`;
- Zeitstempel relativ zum Sitzungsbeginn;
- Konfidenz beziehungsweise Modellscore;
- auslösende versionierte Merkmalswerte;
- Modellversion.

Automatische Kandidaten dürfen weder die manuelle Shiftzahl noch die manuelle Eis-/Bankzeit verändern. Ohne manuelle Marker bleibt die bestätigte manuelle Shiftzahl null. Eine gesonderte Analyse kann Kandidaten später gegen Video prüfen. Schema 12 speichert dafür automatische Grenzzeitpunkte und Zustände, jedoch wegen des ausgeschöpften Geräte-Feldbudgets keine eigene Konfidenzzeitreihe.

### 6.4 Abschluss und bekannte Garmin-Lap

Bei 15 manuellen On-Ice-Phasen können technisch 15 On-Ice-, 15 Bench- und eine native Garmin-Schluss-Lap entstehen. FIT-Schema und Dokumentation müssen diese drei Kategorien unterscheidbar machen. Garmin Connect darf die Gesamtzahl der Phasen-Laps nicht als von RinkLogic bestätigte Shiftzahl ausgeben. Falls Garmin benutzerdefinierte Phasenbezeichnungen nicht sichtbar darstellt, wird dies als Plattformgrenze dokumentiert und die RinkLogic-Shiftzahl bleibt das maßgebliche Feld.

### 6.5 Distanz

Die experimentell geschätzte Distanz wird in Metern mit zwei Dezimalstellen angezeigt. Derselbe ungerundete Sitzungswert speist die RinkLogic-Developer-Felder auf Record-, Lap- und Session-Ebene; Rundung erfolgt nur für die Anzeige.

Der reale Hardwaretest hat gezeigt, dass die frühere `nativeNum=9`-Zuordnung Garmins natives `total_distance` nicht zuverlässig befüllt. Schema 12 übernimmt die Entfernung dieser nicht belegten Zuordnung aus Schema 11. Das native Garmin-Overview-Feld kann daher weiterhin `0,0` anzeigen und ist kein Abnahmekriterium für Beta 6. Dokumentation und Testerinformation benennen diese Plattformgrenze ausdrücklich; die RinkLogic-Felder bleiben die maßgebliche Distanzquelle.

Die Distanz bleibt als Schätzung gekennzeichnet. Das Release-Manifest ordnet jedem Beta-Build genau eine Modellkennung und einen Commit zu. Ohne vermessene Strecke wird kein persönlicher Kalibrierfaktor abgeleitet.

### 6.6 Persönliche Kalibrierung

Die Auswahl `KALIBRIERUNG` startet einen geführten, GPS-unabhängigen Ablauf. Der Tester wählt Eis oder Inline sowie eine bekannte Strecke von genau 20, 22, 25 oder 30 Metern. Die Kalibrierung verwendet immer die unkalibrierte Basisschätzung; ein bereits aktives persönliches Profil darf nicht in seine eigene Neuberechnung eingehen.

Pro Bedingung werden fünf gültige Läufe aufgezeichnet: zuerst ohne Stickhandling, danach mit Puck und Stickhandling. Um eine beobachtbare Kadenzspanne zu erzeugen, fordert die Uhr je Bedingung die Reihenfolge `LANGSAM`, `SCHNELL`, `NORMAL`, `LANGSAM`, `SCHNELL` an. Diese Begriffe sind subjektive Tempovorgaben und keine wissenschaftlich festgelegten Geschwindigkeitsklassen. Ein ungültiger Lauf wird verworfen und mit derselben Vorgabe wiederholt.

Ein Lauf ist nur gültig, wenn:

- seine Dauer 2 bis 30 Sekunden beträgt;
- die unkalibrierte Basisschätzung größer als null ist;
- mindestens ein Anschub erkannt wurde;
- die Bewegungssignalabdeckung mindestens 80 Prozent beträgt;
- die Zeitbasis als gemessen oder geschätzt bekannt ist;
- das Verhältnis aus Referenzdistanz und Basisschätzung zwischen 0,50 und 1,50 liegt.

Für jeden gültigen Lauf gilt:

```text
Lauffaktor = Referenzdistanz / unkalibrierte Basisschätzung
Kadenz = erkannte Anschübe / Laufdauer in Minuten
effektive Schrittlänge = Referenzdistanz / erkannte Anschübe
```

Je Bedingung wird der Median der fünf Lauffaktoren berechnet. Die relative mediane absolute Abweichung darf höchstens 15 Prozent betragen; die beiden Bedingungsmediane dürfen relativ zu ihrem Mittelpunkt höchstens 15 Prozent auseinanderliegen. Nur dann ist der auf vier Nachkommastellen gerundete Median aller zehn Lauffaktoren als Kandidat zulässig. Der Kandidat bleibt auf 0,50 bis 1,50 begrenzt und verändert die normale Distanz erst nach einer ausdrücklichen `AKTIVIEREN`-Bestätigung.

Die Uhr speichert höchstens ein aktives, oberflächenspezifisches Profil lokal. Vor Trainingsstart zeigt sie Oberfläche, aktiven Faktor und dessen lokalen Ursprung. Ersetzen, Deaktivieren und Zurücksetzen erfolgen ausschließlich über den Kalibrierungsbereich. Unvollständige, abgebrochene, inkonsistente oder nicht lesbare Profile werden niemals teilweise angewendet; die App verwendet dann das unveränderte Basismodell.

### 6.7 Kadenz-Shadow-Modell

Kadenz beeinflusst die Beta-6-Distanz noch nicht. Die zehn Kalibrierungsläufe liefern jedoch pro Lauf Referenzdistanz, Laufdauer, erkannte Anschübe, Kadenz, effektive Schrittlänge, Basisschätzung, Lauffaktor, Bedingung, Tempovorgabe, Signalabdeckung und Zeitbasis. Diese Werte werden offline getrennt für ohne und mit Stickhandling ausgewertet. Berichtet werden mindestens Streudiagramm, Spearman-Korrelation und eine robuste Theil-Sen-Steigung; wegen fünf Läufen je Bedingung sind sie rein beschreibend und kein Aktivierungsnachweis.

Ein möglicher späterer Kadenzterm wird ausschließlich als getrennte Shadow-Schätzung berechnet und gegen den aktiven Medianfaktor verglichen. Er darf weder Record-, Lap- oder Session-Distanz noch Uhr- oder Garmin-Connect-Anzeige verändern. Eine Aktivierung benötigt eine neue Modellversion, vorab begrenzte Parameter, unabhängige spielergruppierte Hold-out-Daten und nachweislich geringeren Distanzfehler. Eine Korrelation aus den eigenen zehn Kalibrierungsläufen genügt dafür nicht.

Alle benutzerdefinierten Zeitwerte auf der Uhr und in Garmin Connect werden in Minuten dargestellt. Interne Millisekunden- und Sekundenwerte bleiben ausschließlich Rechen- und Grenzwerte; beispielsweise entspricht die zulässige Kalibrierungslaufdauer von 2 bis 30 Sekunden einer gespeicherten Dauer von ungefähr 0,03 bis 0,50 Minuten.

### 6.8 Beta- und Zustandsklarheit

Die Startseite zeigt dauerhaft `BETA TEST`, App-Version und Modellkennung aus einer zentralen Buildkonfiguration sowie `SHADOW ON · NO AUTO SHIFTS`. Vor dem ersten manuellen Marker steht `NO SHIFT`. Ein Tastendruck startet `ON ICE`; jeder weitere wechselt unmittelbar zwischen `ON ICE` und `BENCH`. Farbe ist nur ergänzend, der Zustand bleibt als Text lesbar.

Die Abschlussseite verwendet `MANUAL SHIFTS`. Ohne manuellen Marker zeigt sie `MANUAL SHIFTS 0`; Eiszeit, Bankzeit und Shiftstatistiken erscheinen als `--`, während allgemeine Trainingsdauer und verfügbare Gesamt-HR sichtbar bleiben. Distanz trägt ausgeschrieben `ESTIMATED` oder `EXPERIMENTAL`. Es gibt keine Cloud-, Upload-, Synchronisierungs- oder FIT-Senden-Schaltfläche. Ein Telefonstatus darf nicht als Uploadbestätigung missverstanden werden.

## 7. FIT-Schema 12

Der isolierte Schema-11-Stand aus Commit `500e163` ist die technische Ausgangsbasis und muss vor Beta 6 kontrolliert in den Release-Branch übernommen werden. Die Kalibrierung erfordert anschließend eine neue, unverwechselbare Schemaversion 12: Das bisherige Session-Feld 108 `time_above_90_percent_hrmax_minutes` wird nicht mehr angelegt und bleibt mit seiner historischen Bedeutung reserviert. Der neue persönliche Kalibrierungsfaktor erhält die neue Session-ID 115 `personal_calibration_factor`. Eine Umdeutung von ID 108 ist verboten.

Schema 12 verwendet weiterhin genau 34 aktive Feldzuweisungen und genau 16 Session-Felder, die auf der Venu 2 Plus geprüften Grenzen. Die aktiven Session-IDs sind `74, 78, 85, 86, 96, 97, 98, 101–107, 109, 115`. Die numerischen Lap-Felder 113 und 114 unterscheiden On-Ice- und Bench-Minuten, weil das frühere Stringfeld 112 in Garmin Connect nicht verlässlich sichtbar war. Record-ID 73 kennzeichnet den Wert `12`.

### 7.1 Sitzungsebene

- FIT-Schema;
- bestätigte manuelle Shiftzahl;
- manuelle Eis- und Bankzeit in Minuten;
- geschätzte Gesamtdistanz in Metern;
- aktiver persönlicher Kalibrierungsfaktor als `float32` mit vier Nachkommastellen Anzeigepräzision; fehlt ein gültiges aktives Profil, bleibt das Feld FIT-ungültig;
- erkannte Anschübe;
- durchschnittliche Shiftdauer und durchschnittliche Shift-HR;
- Eiszeit, Bankzeit, Work-to-Rest, Shift-Dichte und Median-Shiftdauer;
- Zeit in den HR-Zonen 1 bis 5.

`Zeit über 90 % HRmax` erscheint ab Schema 12 nicht mehr als eigenes RinkLogic-Developer-Feld in Garmin Connect. Die lokale Analyse darf sie bei ausreichenden nativen HR-Records weiterhin berechnen und muss dabei die verwendete HRmax-Definition ausweisen.

### 7.2 Phasen-/Lap-Ebene

- Phase `ON_ICE`, `BENCH` oder `NATIVE_FINAL`;
- manuell bestätigt oder automatisch vorgeschlagen;
- Start, Ende und Dauer;
- durchschnittliche HR;
- erkannte Anschübe;
- geschätzte Distanz;
- automatische Grenzzeit und automatischer Zielzustand, sofern ein Kandidat vorliegt.

### 7.3 Record-Ebene

Für spätere Offline-Analysen werden höchstens einmal pro Sekunde geräteverträgliche, quantisierte Merkmale geschrieben:

- Bewegungsintensität in Milligravity;
- Rotationsrate;
- kumulierte erkannte Anschübe;
- kumulierte geschätzte Distanz;
- kumulierte Rohkandidatenzahl;
- FIT-Schemaversion.

Hochfrequente Rohbeschleunigung und eine automatische Konfidenzzeitreihe werden in Beta 6 nicht dauerhaft gespeichert. HR-Abfall nach 30 und 60 Sekunden wird bei ausreichender nativer HR-Aufzeichnung offline aus der Original-FIT berechnet; die in Schema 10 nicht belegten historischen Developer-Felder 93 und 94 werden nicht reaktiviert.

### 7.4 Kalibrierungsdatei

Eine abgeschlossene Kalibrierung wird als eigene Garmin-Aktivität gespeichert. Ihre zehn gültigen Referenzläufe erscheinen in festgelegter Reihenfolge als Laps; verworfene Wiederholungen zählen nicht zu diesen zehn. Die Lap-Felder liefern Dauer, erkannte Anschübe, Basisschätzung und Signalabdeckung. Oberfläche, bekannte Referenzdistanz, Tempovorgabe und Bedingung werden zusätzlich im privaten Referenzformular festgehalten, weil das Gerätefeldbudget dafür keine weiteren FIT-Felder erlaubt. Der gespeicherte Session-Faktor in ID 115 und die lokal aktivierte Profilkopie müssen übereinstimmen; eine Abweichung quarantänisiert die Datei für die Kalibrierungsanalyse.

## 8. Testprotokoll

Jeder Tester führt möglichst drei Einheiten durch.

### 8.1 Technik-Smoke-Test

- App-Version kontrollieren;
- HR-Empfang prüfen;
- einen manuellen Shift und eine Bankphase aufzeichnen;
- Aktivität speichern und synchronisieren;
- Abschlussseiten und Garmin Connect öffnen;
- Original-FIT exportieren.

### 8.2 Kalibrierungs- und bekannte-Distanz-Protokoll

Auf einer vermessenen 20–30-m-Strecke:

- Kalibrierung über die obere Taste und die Auswahlseite starten;
- Oberfläche und exakte Referenzstrecke auswählen;
- fünf gerade Läufe ohne Stickhandling in der vorgegebenen Temporeihenfolge durchführen;
- fünf gerade Läufe mit Stickhandling in derselben Temporeihenfolge durchführen;
- Ergebnis prüfen und den Faktor nur bei erfolgreicher Qualitätsprüfung ausdrücklich aktivieren;
- Kalibrierungsaktivität speichern und als separate Original-FIT exportieren;
- tatsächliche Strecke dokumentieren;
- Anschübe manuell zählen oder per Video prüfen;
- Oberfläche, Startart und Auffälligkeiten notieren;
- zusätzlich eine hockeyähnliche Sequenz mit Kurven, Bremsen und Richtungswechseln.

Die bekannten geraden Strecken bewerten Anschuberkennung und Distanzmodell getrennt. Die hockeyähnliche Sequenz bewertet Übertragbarkeit, ersetzt aber keine Referenzstrecke.

### 8.3 Kontrollierte und reale Shifts

- sechs bis zehn klar getrennte Shift-/Bankintervalle mit manuellen Markern;
- danach eine normale Trainings- oder Spieleinheit mit manuellen Markern;
- optional eine Einheit ohne manuelle Marker nur dann, wenn Video oder eine andere unabhängige Annotation verfügbar ist.

Für die formale Bewertung automatischer Shiftgrenzen benötigt auch die kontrollierte Einheit synchronisiertes Video oder eine unabhängige zweite Person. Manuelle Marker bleiben für die Bedien- und Zählprüfung maßgeblich, sind aber kein fehlerfreies Zeitkriterium.

## 9. Manuelle FIT-Rückgabe

Nach jeder Einheit synchronisiert der Tester die Uhr mit Garmin Connect, öffnet die Aktivität in Garmin Connect Web und lädt über `Export Original` das unveränderte ZIP beziehungsweise die FIT-Datei herunter.

Der Tester sendet:

1. den unveränderten Originalexport;
2. ein Referenzformular mit Tester-ID, Sitzungscode, App-Version, Build-Commit, Modellkennung, FIT-Schema, Uhrmodell, Firmware, Testzeitpunkt, Oberfläche, Referenzdistanz, Laufreihenfolge, aktivem Kalibrierungsfaktor und Aktivierungsstatus;
3. optional ein separat freigegebenes Video.

Bevorzugt wird ein privater Upload-only-Dateianforderungslink, bei dem Tester keine Dateien anderer Teilnehmer sehen können. Ein individuell adressierter verschlüsselter Übertragungsweg ist der dokumentierte Fallback. Öffentliche GitHub-Issues, Pull Requests, öffentliche Drive-Ordner und normale Chat-Anhänge sind für reale Testerdateien ausgeschlossen.

Dateinamen folgen:

```text
<tester-id>_<yyyy-mm-dd>_<surface>_<protocol>_original.zip
<tester-id>_<yyyy-mm-dd>_<surface>_<protocol>_reference.csv
```

Der öffentliche Repository-Bestand enthält ausschließlich synthetische oder vollständig künstlich erzeugte Testdateien.

## 10. Eingangskontrolle und Analyse

Die lokale Analysepipeline verarbeitet einen privaten Eingangsordner außerhalb des Git-Repositorys. Vor jeder Auswertung prüft sie:

- Datei- und FIT-CRC;
- unterstützte App-, Modell- und Schemaversion;
- Pflichtfelder und plausible Zeitreihenfolge;
- eindeutige Tester- und Sitzungszuordnung;
- manuelle Marker oder unabhängige Annotation;
- Bewegungssignal- und HR-Abdeckung;
- Konsistenz der RinkLogic-Distanz zwischen Record-, Lap- und Session-Ebene;
- Trennung von On-Ice, Bench und nativer Schluss-Lap;
- Duplikate anhand kryptografischer Prüfsumme.

Fehlerhafte oder unvollständige Dateien kommen in Quarantäne und verändern keine bestehenden Analyseergebnisse.

### 10.1 Shift-Erkennung

Berichtet werden spielergruppiert und getrennt nach Eis/Inline:

- Precision, Recall und F1 getrennt für Shiftstart und Shiftende;
- verpasste und zusätzliche Übergänge;
- Fehlwechsel pro Stunde;
- Median und 95. Perzentil des absoluten Zeitfehlers bei Start und Ende;
- Fehler der Shift-Dauer;
- Abstentionsrate des Detektors;
- Unterschiede mit und ohne Stickhandling.

Das Zuordnungsfenster für einen Treffernachweis wird vor Sichtung der Testergebnisse festgelegt und versioniert.

### 10.2 Distanz pro erkanntem Anschub

Getrennt berichtet werden:

- Fehler der Anschubzählung;
- Distanzfehler bei korrekt annotierten Anschüben;
- MAE in Metern;
- relativer Fehler mit vorab definiertem Nenner;
- vorzeichenbehafteter Bias;
- Unterschiede nach Oberfläche, Spieler und Stickhandling;
- Anteil gültiger Signalabschnitte.

Mindestens 25 % der Spieler bleiben für den Pilot als unangetastete Hold-out-Gruppe. Die wissenschaftliche Aktivierungsschwelle bleibt mindestens zwölf Spieler je Oberfläche, drei gerade 20–30-m-Läufe und eine hockeyähnliche Sequenz pro Spieler mit eingefrorenem, spielergruppiertem Vergleich. Beta-6-Daten allein aktivieren keine neuen Produktionswerte.

### 10.3 Persönliche Kalibrierung und Kadenz

Für jede Kalibrierung werden der aktive Medianfaktor, die zehn Lauffaktoren, Gültigkeitsentscheidungen und die beiden Bedingungsmediane reproduziert. Die Auswertung vergleicht zunächst Basismodell gegen einfachen persönlichen Faktor. Zusätzlich beschreibt sie je Bedingung und gemeinsam mit ausgewiesener Bedingungszugehörigkeit den Zusammenhang zwischen Kadenz und effektiver Schrittlänge. Der Shadow-Kadenzterm wird nur gegen dieselben Referenzläufe und später gegen unabhängige Läufe bewertet; er bleibt klar von der tatsächlich auf der Uhr verwendeten Distanz getrennt.

Berichtet werden mindestens MAE, Bias und relativer Fehler des Basismodells und des einfachen Faktors, Kadenzspanne, Spearman-Korrelation, Theil-Sen-Steigung, Signalabdeckung sowie fehlende oder verworfene Läufe. Ergebnisse aus weniger als fünf gültigen Läufen pro Bedingung oder ohne ausreichende Kadenzvariation werden als unzureichend markiert und nicht durch einen scheinbaren Koeffizienten ersetzt.

## 11. Fehlerbehandlung

- Falscher PRG-Build: Installation abbrechen und richtigen gerätespezifischen Download bereitstellen.
- App-Absturz oder unvollständiges Speichern: Datei quarantänisieren; keine Modellbewertung.
- Fehlende manuelle Marker: nur technische Stabilität auswerten, sofern keine unabhängige Annotation existiert.
- Fehlende Referenzdistanz: keine Kalibrierungs- oder Genauigkeitsaussage.
- Beschädigtes oder widersprüchliches lokales Profil: Profil nicht anwenden, Basismodell verwenden und sichtbaren Hinweis ausgeben.
- Unzureichende Kadenzspanne: persönlichen Medianfaktor zulassen, sofern dessen eigene Qualitätsregeln erfüllt sind; Kadenzkorrelation als nicht auswertbar kennzeichnen.
- Doppelte Einsendung: identische Prüfsumme einmal verarbeiten.
- Unbekanntes FIT-Schema: nicht interpretieren; Parser zuerst explizit erweitern.
- Private Datei versehentlich öffentlich: Zugriff sofort entfernen, betroffene Person informieren und Ursache vor Fortsetzung beheben.

## 12. Verifikation und Go/No-Go

Vor Veröffentlichung der Beta 6 müssen bestanden sein:

- Unit- und Simulator-Tests aller unterstützten Profile;
- FIT-Encoder-/Parser-Vertragstests für Schema 12 einschließlich reserviertem Feld 108, neuem Feld 115 und Rückwärtskompatibilität zu Schema 4–11;
- Tasten- und Touchtests für `untere Taste → Training`, `obere Taste → Auswahlseite`, Auswahlwechsel, Bestätigung und `EXIT` ohne Aktivitätsdatei;
- Unit-Tests aller Kalibrierungsgates, Median-/MAD-Berechnung, ausdrücklicher Aktivierung, Neustart-Persistenz, Deaktivierung und sicherem Basismodell-Fallback;
- Test, dass das Kadenz-Shadow-Modell keine Distanz auf Uhr oder FIT verändert;
- Test ohne manuelle Marker mit manueller Shiftzahl null;
- Test mit 15 manuellen Shifts und eindeutig erklärbarer Lap-Struktur;
- Test, dass Record-, Lap- und Session-Distanz dieselbe RinkLogic-Schätzung konsistent fortschreiben;
- Test der Offline-HR-Recovery-Berechnung für fehlende und ausreichende native HR-Daten;
- 60-minütiger Hardware-Smoke-Test auf Venu 2 Plus;
- Hardware- oder begründeter Simulator-Smoke-Test für jede weitere freigegebene Gerätefamilie;
- Remote-Installation und Originalexport durch mindestens einen unabhängigen Tester;
- Prüfsumme und reproduzierbarer Buildnachweis;
- dokumentierter Rollback auf die vorherige stabile Beta.

Kein Rollout erfolgt, wenn Aktivitätsdaten verloren gehen können, manuelle und automatische Shifts vermischt werden, private Daten öffentlich gelangen, die RinkLogic-Developer-Distanz fehlt oder die getestete Binärdatei nicht eindeutig auf Commit, Modellkennung und Schlüssel zurückgeführt werden kann. Ein natives Garmin-`total_distance` von `0,0` bleibt eine dokumentierte Plattformgrenze und blockiert Beta 6 nicht.

## 13. Abnahme

Beta 6 ist bereit für mehrere Remote-Tester, wenn der vollständige Ablauf ohne physischen Entwicklerzugriff reproduziert wurde:

```text
Registrierung
→ passender Download
→ Installation
→ Smoke-Test
→ standardisierte Einheit
→ Garmin-Synchronisierung
→ Export Original
→ private manuelle Einsendung
→ Eingangskontrolle
→ pseudonyme Analyse
```

Die Ergebnisse werden als experimenteller Pilotbericht veröffentlicht, ausschließlich mit aggregierten oder synthetischen Daten. Reale FIT-Dateien, Testerkennungen und Videos bleiben privat.

