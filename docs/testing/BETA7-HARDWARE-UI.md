# Beta 7 – UI- und Responsive-Abnahme für Ring 1

Stand: 5. November 2026

Geprüfter Quellstand: Commit `18355e9` auf dem lokalen Beta-7-Strang

Umfang: Start → Training/Kalibrierung/Exit, verpflichtende Sportauswahl, geführte 20-m-Kalibrierung mit 5 Läufen ohne und 5 Läufen mit Stickhandling sowie Touch-/Tastenbedienung der 50 Ring-1-Zielgeräte.

Diese Prüfung autorisiert weder Merge noch Upload, Portal-Aktion, Verteilung oder Veröffentlichung.

## Kurzurteil

Die Zustands- und Tastenlogik des geführten Ablaufs ist automatisiert gut abgedeckt. Der aktuelle Stand ist trotzdem **nicht UI-freigabefähig**, weil zwei konkrete P0-Interaktionsfehler und mehrere noch offene Responsive-Nachweise bestehen:

1. Die sichtbaren Touch-Aktionshinweise der Review-Seite liegen außerhalb ihrer aktiven Touchzonen.
2. Nach einem gültigen Kalibrierlauf zeigt die Ergebnisansicht bereits die nächste Laufnummer, aber noch Bedingung und Tempo des soeben beendeten Laufs.

Zusätzlich beweist der vorhandene Responsive-Test nur, dass Textanker und Rechtecke innerhalb eines quadratischen Koordinatenraums liegen. Er prüft keine Textbreiten, Font-Höhen, Runddisplay-Sicherheitszonen, deutsche Langtexte oder das 466-px-Ring-1-Ziel.

## Reproduzierter automatisierter Stand

| Nachweis | Ergebnis | Aussagegrenze |
| --- | --- | --- |
| Monkey-C-Gesamtsuite auf `venu2plus` | **266/266 bestanden** | Belegt Logik und den vorhandenen Fake-Responsive-Test auf einem Testziel; kein visueller Gerätebeleg |
| Python-Gerätematrix-Vertrag | **4 Tests plus 104 Subtests bestanden** | Belegt eindeutige IDs, installierte Profile, Klassen/Status, Matrix-Manifest-Gleichheit und Profilmetadaten |
| Python-Buildvertrag | **8 Tests plus 8 Subtests bestanden** | Belegt Skript- und Paketkonfiguration, nicht die Lesbarkeit auf Geräten |
| Ring-1-Matrix | **50 release-enabled Ziele** | Zielmatrix, keine Behauptung über 50 physisch geprüfte Geräte |
| Lokale PRG-Artefakte | **50/50 vorhanden**, jeweils ungleich 0 Byte | Belegt lokale Kompilierbarkeit des aktuellen Stands; kein Installations-, Bedien- oder Hardwarebeleg |
| Visuelle Simulator-Stichprobe | **nicht durchgeführt** | Die Windows-Simulatorerfassung war in diesem Prüflauf nach Wiederholungsversuch nicht erreichbar |

Verteilung der Ring-1-Ziele:

- 41 Geräte mit `button-five`, 9 Geräte mit `touch-two-button`
- 32 AMOLED-, 18 MIP-Geräte
- quadratische Displaygrößen: 218, 240, 260, 280, 360, 390, 416, 454 und 466 px

## Ablaufbewertung

### 1. Ready → Auswahl

Automatisiert bestätigt:

- Ready besitzt genau eine Aktion **WEITER/CONTINUE**.
- `KEY_ENTER` öffnet das Startmenü; `KEY_ESC` startet nichts und umgeht das Menü nicht.
- Touch reagiert nur innerhalb des gezeichneten Continue-Rechtecks.
- Eis- und Inline-Kalibrierstatus werden getrennt dargestellt.

Offener Punkt:

- Auf 41 reinen Tastenmodellen sieht die Continue-Fläche wie eine Touch-Schaltfläche aus, nennt aber nicht die zu drückende obere Taste. Die Funktion ist vorhanden, ihre Auffindbarkeit auf fünf Tasten ist nicht nachgewiesen.

### 2. Training / Kalibrierung / Exit

Automatisiert bestätigt:

- Standardauswahl ist **TRAINING**.
- Untere Taste (`KEY_ESC`) wechselt zyklisch Training → Kalibrierung → Exit.
- Obere Taste (`KEY_ENTER`) führt die sichtbare Auswahl aus.
- Touch wählt alle drei Einträge direkt.

Konkreter P0-Befund:

- Der Touchbereich für **EXIT** umfasst pauschal die unteren 35 Prozent des Displays. Der Bedienhinweis liegt bei 84 Prozent und damit ebenfalls in der Exit-Zone. Ein Touch auf den Hinweis führt unmittelbar **EXIT** aus. Der Test prüft nur je einen Mittelpunkt und erkennt diese Kollision nicht.

### 3. Verpflichtende Sportauswahl

Automatisiert bestätigt:

- Training und Kalibrierung verlangen beide eine Auswahl zwischen Eis und Inline.
- Die zuletzt gewählte Sportart dient nur als Vorbelegung.
- Untere Taste wechselt, obere Taste bestätigt.
- Ungültige Zwecke und Sportwerte führen keine Aktion aus.

Konkreter P0-Befund:

- Auf Touchgeräten bestätigt jede Berührung in der oberen Bildschirmhälfte sofort **EIS**, jede Berührung in der unteren Hälfte sofort **INLINE**. Damit lösen auch Touches auf Titel, Leerraum oder Bedienhinweis eine Auswahl aus. Es gibt keine auf die sichtbaren Optionen begrenzten Touchzonen und keine neutrale Fläche.

### 4. Kalibrierungs-Intro

Automatisiert bestätigt:

- Strecke ist fest auf **20,00 m** gesetzt.
- Pro Sport werden **5 ohne Stick + 5 mit Stick** angekündigt.
- Untere Taste beginnt; obere Taste öffnet den abgesicherten Abbruch.
- Touchzonen 60–79 Prozent für Start und ab 80 Prozent für Abbruch liegen auf den sichtbaren Aktionshinweisen.

### 5. Zehn geführte Läufe

Automatisiert bestätigt:

- Reihenfolge: fünf `skate_only`, danach fünf `puck_stickhandling`.
- Tempo je Fünferblock: locker, schnell, normal, locker, schnell.
- Untere Taste setzt Start- und Endmarke und bestätigt anschließend **Weiter/Wiederholen**.
- Ungültige Läufe erhöhen nicht den gültigen Zähler und behalten dieselbe Vorgabe.
- Nach genau zehn gültigen Läufen öffnet die obere Taste Review/Speichern; vorher führt sie in den abgesicherten Abbruch.
- Touch im Bereich 55–79 Prozent entspricht der unteren Aktion, ab 80 Prozent der oberen Aktion.

Konkreter P0-Befund:

- Nach einem akzeptierten Lauf ist `acceptedCount` bereits erhöht. Die Anzeige `withinConditionIndex` wird deshalb aus dem nächsten Lauf berechnet, während Bedingung und Tempo bis zur unteren Weiter-Aktion zwischengespeichert beim beendeten Lauf bleiben. Beispiel nach Lauf 1: Anzeige **2 / 5** zusammen mit dem Tempo von Lauf 1. Nach dem fünften Lauf kann **OHNE STICK 1 / 5** erscheinen, obwohl der nächste Block **MIT STICK 1 / 5** ist. Das ist eine semantisch widersprüchliche Führung und wird von den aktuellen Tests nicht geprüft.

### 6. Review, Speichern und Rückkehr

Automatisiert bestätigt:

- Review zeigt Sport, 10/10, Gesamtfaktor und beide Bedingungsmediane.
- Obere Taste speichert/aktiviert unmittelbar.
- Untere Taste öffnet die Bestätigung zum Verwerfen.
- Nach Ergebnis führt Select/Back zum Startmenü zurück.

Konkreter P0-Befund:

- Sichtbarer Hinweis **OBEN: SPEICHERN** liegt bei 74 Prozent, **UNTEN: VERWERFEN** bei 84 Prozent. Die Touchlogik akzeptiert jedoch nur 45–72 Prozent und teilt bei 58 Prozent. Dadurch sind beide sichtbaren Hinweise nicht antippbar. Stattdessen aktiviert ein Touch auf die Medianzeile bei 51 Prozent das Speichern und ein Touch auf die Medianzeile bei 60 Prozent das Verwerfen. Die bestehenden Touchtests verwenden genau 52 und 64 Prozent und bestätigen damit die unsichtbaren Zonen statt der sichtbaren Aktionen.

## Bewertung des vorhandenen Responsive-Tests

`ResponsiveUiTest.mc` ruft sechs Ansichten mit Fake-Displays der Größen 218, 240, 260, 280, 360, 390, 416 und 454 px auf. Er speichert ausschließlich die Y-Koordinate jedes `drawText`-Aufrufs sowie die Rechtecke und prüft, ob diese Koordinaten innerhalb des quadratischen Displays liegen.

Damit nachgewiesen:

- keine negativen oder unterhalb des Displays liegenden Textanker
- das Ready-Rechteck bleibt innerhalb der geprüften Breiten und Höhen
- die sechs Ansichten lassen sich auf den acht Fake-Größen ohne Testfehler zeichnen

Nicht nachgewiesen:

- Textbreite und tatsächliche Font-Höhe
- Abschneiden an runden Displayrändern
- Überlappungen zwischen benachbarten Textzeilen
- deutsche Langtexte und Fehlermeldungen
- Bitmap-Skalierung beziehungsweise absichtliches Clipping des 416×416-Ready-Hintergrunds auf 218–390 px
- Touchgrenzen auf 360, 390 und 454 px
- 466×466 px des Ring-1-Geräts `fenix9pro51mm`
- tatsächliche Lesbarkeit auf MIP und AMOLED

Die grüne Responsive-Prüfung darf daher nicht als visuelle Freigabe der 50 Geräte bezeichnet werden.

## Priorisierte Restpunkte

### P0 – vor Task-7-Abschluss

- [ ] Review-Touchzonen auf die sichtbaren Aktionen legen und Tests direkt auf den gezeichneten Speichern-/Verwerfen-Hinweisen ausführen.
- [ ] Laufnummer, Bedingung und Tempo auf der Accepted-Seite semantisch auf denselben Lauf beziehen; Übergänge 1→2, 5→6 und 9→10 explizit testen.
- [ ] Touchflächen im Startmenü auf die sichtbaren Einträge begrenzen; Touch auf Bedienhinweis und Leerraum darf Exit nicht auslösen.
- [ ] Touchflächen der Sportauswahl auf Eis/Inline begrenzen; Titel, Leerraum und Bedienhinweis müssen neutral bleiben.
- [ ] Responsive-Test um 466 px, Textausdehnung, Font-Höhe, Runddisplay-Sicherheitszone und deutsche Ressourcen erweitern.
- [ ] Visuelle Simulatorprüfung mindestens auf kleinstem MIP (`fr255s`, 218 px), 240-/260-/280-px-MIP, kleinem Touch-AMOLED (`venu2s`, 360 px), 390-/416-/454-px-AMOLED und dem 466-px-Extrem durchführen.

### P1 – vor Ring-1-Go/No-Go

- [ ] Auf Tastenmodellen einen eindeutigen Hinweis für **obere Taste: Weiter** auf der Ready-Seite prüfen.
- [ ] Reine Tastenflüsse auf mindestens einem kleinen MIP- und einem großen AMOLED-Fünf-Tasten-Modell vollständig durchspielen.
- [ ] Touchgrenzen knapp beidseits von 40/65 Prozent im Startmenü, 50 Prozent in der Sportauswahl, 60/80 Prozent im Intro, 55/80 Prozent im Lauf und den korrigierten Review-Grenzen testen.
- [ ] Lange deutsche Fehlertexte auf 218/240/260 px auf Abschneiden und Überlagerung prüfen.
- [ ] Die Repräsentantenliste vereinheitlichen: Die Matrix markiert 11 Geräte als `representative`, der bisherige Ausführungsplan nennt neun.
- [ ] `StartMenuInputDelegate` und `SportSelectionInputDelegate` gegen fehlende oder zu kurze Touchkoordinaten absichern und testen.

### P2 – Beobachtung im Hardwaretest

- [ ] Kontrast und Lesbarkeit bei Hallenlicht sowie mit reduzierter Displayhelligkeit prüfen.
- [ ] Entprellung und unbeabsichtigte Doppelaktionen mit Handschuhen und feuchtem Touchscreen prüfen.
- [ ] Ready-Hintergrund und Logo auf kleinen Displays auf störendes Clipping prüfen.

## Gate-Status

| Gate | Status |
| --- | --- |
| Zustands-/Tastenlogik | **automatisiert bestanden** |
| 20-m-5+5-Protokoll | **automatisiert bestanden** |
| Ring-1-Matrixvertrag | **automatisiert bestanden** |
| 50 Ring-1-Buildziele | **lokale PRGs vorhanden; kein Hardwareclaim** |
| Responsive Koordinatenprüfung | **bestanden, aber methodisch unvollständig** |
| Touch-Interaktion | **nicht bestanden – P0-Kollisionen vorhanden** |
| Semantische Laufsynchronität | **nicht bestanden – P0-Widerspruch vorhanden** |
| Visuelle Simulatorabnahme | **offen** |
| Physische Hardwareabnahme | **offen** |

Task 7 bleibt damit **in Arbeit**. Task 8, signierter Kandidat und jede Veröffentlichung bleiben bis zur Behebung und erneuten Prüfung blockiert.
