# Venu 2 Plus: geschätzte Sensor-Zeitbasis (experimentell)

## 1. Wissenschaftliche Grundlage

Der lokale Hockey-Evidence-Datensatz führt `hockey-skating-khandan-2022` als `abstract_only`. Die Studie untersucht zeitliche und räumliche Parameter des Eishockey-Skatings mit tragbaren IMUs. Daraus folgt **keine** Validierung einer Anschuberkennung am Garmin-Handgelenk, der hier gewählten Schwellen oder einer Distanzschätzung beim Inlinehockey.

## 2. Übertragungsannahmen

- Die angeforderte Abtastrate nähert den Abstand der Samples **innerhalb** eines Sensorpakets an. Die tatsächliche Abtastrate wird von der Uhr nicht pro Sample bestätigt.
- Der Zeitpunkt des Connect-IQ-Callbacks nähert den Zeitpunkt des letzten Samples an. Verzögerungen und Paketverluste bleiben mögliche Fehlerquellen.
- Stickhandling, Pässe, Schüsse und Kontakte können Handgelenksspitzen erzeugen, die nicht von Anschüben stammen.

## 3. ShiftSense-Modell

Die Venu 2 Plus meldet Connect-IQ-API 5.0.0; `AccelerometerData.timestamp` und `GyroscopeData.timestamp` sind laut lokalem SDK erst ab API 5.1.1 verfügbar. Falls beide Zeitstempel-Arrays vorhanden sind, bleibt die gemessene Zeitbasis maßgeblich. Fehlt mindestens eines, werden die Beschleunigungs- und Gyroskop-Arrays nur bei plausibler Paketgröße auf ein regelmäßiges, **geschätztes** Raster abgebildet:

`sample_time_i = callback_elapsed_ms - (N - 1 - i) × 1000 / angeforderte_Abtastrate`

Die Uhr zeigt Distanzen dieses Pfads mit `~` an. Die Kennzeichnung `:estimated` wird intern bis zum Live-Dashboard weitergereicht; das derzeitige FIT-Schema 6 hat auf der Venu 2 Plus kein zusätzliches Qualitätsfeld. Exportierte FIT-Distanzen müssen deshalb zusammen mit Build-Version und Testprotokoll interpretiert werden.

Freie, bisher **nicht sportwissenschaftlich validierte** Parameter: maximal 10 Hz, mindestens fünf Samples pro Paket, höchstens angeforderte Abtastrate plus ein Sample bei einem 1-s-Callback, 150 mg Beschleunigungsabweichung, 40 °/s Rotation, 350–1300 ms rhythmischer Abstand sowie 1,25/2,25 m vorläufige Anschublängen. Sie dürfen nicht allein anhand eines einzigen 22-m-Laufs nachgestellt werden.

Qualitätsgrenzen: beide Sensorachsen vollständig; keine unplausiblen Paketgrößen; zeitlich zuordenbare Beschleunigungs-/Gyrospitzen; Lücken zurücksetzen; Abdeckung nur für beobachtete Intervalle; fehlende Daten nicht als null Anschübe interpretieren. Manuelle Shift-Marker und Garmin-ActivityRecording bleiben unabhängig von der Anschuberkennung funktionsfähig.

## 4. Validierung

1. Zuerst ein bis zwei kurze Geräteversuche auf der Venu 2 Plus. Die FIT-Datei muss gültige Anschub-, Distanz- und Abdeckungsfelder enthalten; andernfalls nicht den ganzen 10×22-m-Test wiederholen.
2. Dann fünf 22-m-Versuche ohne und fünf mit Puck/Stickhandling auf derselben Strecke. Pro Versuch Distanz-Fehler und Abdeckung ausweisen. Die zehn bestätigten 22-m-Referenzen vom 5. Oktober sind **keine** gemessenen Uhrdistanzen.
3. Wenn möglich, Anschübe unabhängig per Video oder Handzählung referenzieren. Ohne diese Referenz bleibt der Anschubzählfehler unbekannt, selbst wenn die geschätzte Distanz 22 m trifft.
4. Fehler vorab getrennt berichten: absoluter Distanzfehler pro Versuch, medianer absoluter Prozentfehler, Anschubzählfehler nur bei Referenzzählung, Signalabdeckung und Ausfallrate. Schwellen für eine Produktfreigabe sind noch nicht festgelegt; ein Profil wird nicht automatisch aktiviert.

**Status: experimenteller Algorithmus, nicht validiert und keine medizinische Aussage.**

## Implementierungsstand am 6. Oktober 2026

- Der bisherige Code verwarf auf API 5.0 jedes Sensorpaket ohne Zeitstempel für die Anschuberkennung. Der neue Fallback erzeugt nur bei plausibler Paketgröße eine geschätzte Zeitbasis; bei fehlendem Gyroskop bleibt die Anschub-/Distanzmetrik unbekannt.
- Simulator: 142 von 142 Monkey-C-Tests bestanden. Lokale FIT-Auswertung: 24 von 24 Python-Tests bestanden. Der signierte `venu2plus`-Build umfasst 387.660 Byte, SHA-256 `99C94D9C075E61A227EBD4708A446E55123EB5180F23DF658B7792FE7E74B7AE`.
- **Installation am 6. Oktober:** Windows erkannte `Venu 2 Plus` mit WPD-Status `OK` und `Internal Storage/GARMIN/APPS`. Dort war vorher keine `ShiftSenseV2.prg` sichtbar. Die signierte PRG wurde dorthin übertragen; die Geräteansicht meldete 387.660 Byte. Ein lokaler Rückleseabzug aus dem Geräteordner hatte ebenfalls 387.660 Byte und exakt denselben SHA-256 `99C94D9C075E61A227EBD4708A446E55123EB5180F23DF658B7792FE7E74B7AE`. Der Abzug liegt nur unter dem ignorierten `analysis/private/install-verification-2026-10-06/`.
- Ein **Start-, Speicher- und Sensorsignaltest auf der Uhr** steht noch aus. Die zuvor bestätigte manuelle Shift-Funktion gilt nicht automatisch als Hardware-Bestätigung dieser neuen Version.

## Kurzer Geräte-Smoke-Test nach Installation

1. Nach sicherem Trennen auf der Uhr eine **separate kurze** ShiftSense-Aufzeichnung starten, unteren Knopf für Shift-Start drücken, eine markierte Strecke von etwa 22 m fahren, Shift per unterem Knopf beenden, Aufnahme speichern. Keine volle Kalibrierungsserie nötig.
2. Auf der Bewegungsseite prüfen: Anschubzahl numerisch, Distanz mit `~`, Abdeckung nicht `--`. Ein Wert nahe 22 m ist erst ein Plausibilitätshinweis, kein Genauigkeitsnachweis.
3. Original-FIT nur lokal exportieren; CRC und Schema 6 sowie `shift_push_count`, `shift_estimated_distance_cm`, `shift_motion_coverage_percent` überprüfen. Falls diese Felder fehlen/ungültig sind oder die Uhr `IQ!` zeigt, vor einem weiteren Streckentest die Sensor- und Absturzdiagnose durchführen.
