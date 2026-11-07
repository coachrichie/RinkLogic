# Beta 7 – UI- und Responsive-Abnahme für Ring 1

Stand: 7. November 2026

Geprüfter Quellstand: Commit `7fef470` auf dem lokalen Beta-7-Strang

Umfang: Start → Training/Kalibrierung/Exit, verpflichtende Sportauswahl, geführte 20-m-Kalibrierung mit 5 Läufen ohne und 5 Läufen mit Stickhandling sowie Touch-/Tastenbedienung der 50 Ring-1-Zielgeräte.

Diese Prüfung autorisiert weder Merge noch Upload, Portal-Aktion, Verteilung oder Veröffentlichung.

## Kurzurteil

Die vier am 6. November gefundenen P0-Interaktionsfehler sind im korrigierten
Kandidaten geschlossen. Startmenü, Sportauswahl und Review reagieren nur auf
sichtbare Aktionen; die Accepted-Seite behält Lauf, Bedingung und Tempo bis zur
Bestätigung konsistent. Die Venu-2S-Sichtprüfung führte zusätzlich zu kurzen,
getrennten Status- und Aktionszeilen für kleine Runddisplays.

Der Stand ist damit **zur kontrollierten Remote-Hardwareabnahme freigegeben**.
Diese Freigabe ist kein Hardwareclaim und kein Portal-Upload. Die nachfolgenden
Befundabschnitte beschreiben zur Nachvollziehbarkeit den inzwischen gesperrten
Vorgängerstand.

Zusätzlich beweist der vorhandene Responsive-Test nur, dass Textanker und Rechtecke innerhalb eines quadratischen Koordinatenraums liegen. Er prüft keine Textbreiten, Font-Höhen, Runddisplay-Sicherheitszonen, deutsche Langtexte oder das 466-px-Ring-1-Ziel.

## Reproduzierter automatisierter Stand

| Nachweis | Ergebnis | Aussagegrenze |
| --- | --- | --- |
| Monkey-C-Gesamtsuite auf `venu2plus` | **275/275 bestanden** | Belegt Logik einschließlich P0-Grenzen und kleiner UI-Zeilen; kein Hardwarebeleg |
| Python-Gerätematrix-Vertrag | **4 Tests plus 104 Subtests bestanden** | Belegt eindeutige IDs, installierte Profile, Klassen/Status, Matrix-Manifest-Gleichheit und Profilmetadaten |
| Python-Buildvertrag | **8 Tests plus 8 Subtests bestanden** | Belegt Skript- und Paketkonfiguration, nicht die Lesbarkeit auf Geräten |
| Ring-1-Matrix | **50 release-enabled Ziele** | Zielmatrix, keine Behauptung über 50 physisch geprüfte Geräte |
| Lokale PRG-Artefakte | **50/50 vorhanden**, jeweils ungleich 0 Byte | Belegt lokale Kompilierbarkeit des aktuellen Stands; kein Installations-, Bedien- oder Hardwarebeleg |
| Visuelle Simulator-Stichprobe | **Venu 2S bestanden** | Ready, Menü, Sportauswahl, Intro und Laufseite geprüft; weitere reale Modelle bleiben offen |

Verteilung der Ring-1-Ziele:

- 41 Geräte mit `button-five`, 9 Geräte mit `touch-two-button`
- 32 AMOLED-, 18 MIP-Geräte
- quadratische Displaygrößen: 218, 240, 260, 280, 360, 390, 416, 454 und 466 px

## Gesperrter Vorgängerkandidat

Der signierte Export vom 5. November 2026 ist aufgrund der vier P0-Befunde **nicht zu installieren, zu verteilen oder für ein Go/No-Go zu verwenden**:

- Datei: `RinkLogic-0.2.0-beta.7.iq`
- Größe: 8.579.883 Byte
- SHA-256: `918F13E499F338B3F3D81EE1D564C445697F39EE99E290BD305E0195F48D6CB8`
- Exportnachweis: 69/69 Garmin-Paketbinärdateien

Der Hash dient nur als Sperrkennung. Nach jeder Watch-Codeänderung sind Commit, Größe und SHA-256 eines neu signierten Pakets frisch zu ermitteln. Ein Prüfer muss beim alten Hash den Test vor der Installation abbrechen.

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

## Prüffähige Akzeptanzkriterien für die vier P0-Fixes

Die Kriterien gelten zuerst automatisiert und anschließend auf den unten zugeordneten realen Touch- beziehungsweise Tastenmodellen. Ein einzelner Eingabeimpuls darf höchstens eine Navigation oder Datenaktion auslösen.

### P0-A – Neutralzonen im Startmenü

Bestanden nur wenn:

- ein Touch direkt auf **TRAINING**, **KALIBRIERUNG** oder **EXIT** genau den berührten Eintrag ausführt;
- Touches oberhalb des ersten Eintrags, zwischen den drei sichtbaren Einträgen, auf dem Bedienhinweis und unterhalb des Hinweises keine Aktion ausführen;
- die Touchzonen einander nicht überlappen und an jeder Grenze je ein Testpunkt knapp innerhalb und knapp außerhalb existiert;
- die gleichen Grenztests für 360, 390, 416 und 454 px bestehen;
- Standardauswahl, unteres Weiterschalten und obere Bestätigung auf Tastenmodellen unverändert funktionieren;
- Touch oder Tastendruck weder zwei Seitenwechsel noch einen unbeabsichtigten Exit erzeugen.

Erforderliche Regressionstests: alle drei sichtbaren Einträge, jede Neutralzone, jede Zonengrenze sowie fehlende beziehungsweise zu kurze Touchkoordinaten.

### P0-B – Neutralzonen in der Sportauswahl

Bestanden nur wenn:

- ein Touch direkt auf **EIS** genau Eis und direkt auf **INLINE** genau Inline bestätigt;
- Titel, Fläche oberhalb/unterhalb der Einträge, Abstand zwischen den Einträgen und Bedienhinweis neutral bleiben;
- die letzte Sportart nur sichtbar vorgewählt wird und nie durch Öffnen der Seite automatisch bestätigt wird;
- die Touchgrenzen für 360, 390, 416 und 454 px geprüft sind;
- untere Taste weiterhin zwischen Eis/Inline wechselt und obere Taste ausschließlich die sichtbare Auswahl bestätigt;
- ungültiger Zweck, ungültige Sportart und ungültige Touchkoordinaten weiterhin keine Aktion auslösen.

### P0-C – Review-Touchflächen auf sichtbaren Aktionen

Bestanden nur wenn:

- ein Touch auf den sichtbaren Hinweis **OBEN: SPEICHERN** beziehungsweise dessen gezeichnete Aktionsfläche ausschließlich Speichern/Aktivieren ausführt;
- ein Touch auf **UNTEN: VERWERFEN** unmittelbar und ausschließlich verwirft;
- Faktor, Medianzeilen, Titel, Leerraum und Flächen außerhalb der beiden Aktionen neutral bleiben;
- beide Aktionszonen vollständig innerhalb des runden sicheren Bereichs liegen, sich nicht überlappen und eine neutrale Trennung besitzen;
- die Tests die tatsächlich gezeichneten Y-Positionen auf 360, 390, 416 und 454 px antippen, nicht frühere unsichtbare Prozentbereiche;
- obere Taste weiterhin unmittelbar speichert und untere Taste unmittelbar verwirft;
- nach Touch oder Tastendruck weder ein zusätzlicher Bestätigungsdialog noch eine zweite Aktion ausgelöst wird.

### P0-D – Konsistente Accepted-Seite

Die Accepted-Seite beschreibt immer den gerade abgeschlossenen gültigen Lauf. Bestanden nur wenn:

- nach Lauf 1 **OHNE STICK · 1/5 · LOCKER · LAUF 1/10** zusammen mit **GÜLTIG · UNTEN: WEITER** erscheint;
- erst nach der unteren Weiter-Aktion die nächste Vorgabe **OHNE STICK · 2/5 · SCHNELL** erscheint;
- nach Lauf 5 **OHNE STICK · 5/5 · SCHNELL · LAUF 5/10** angezeigt wird;
- nach Weiter der Block eindeutig zu **MIT STICK · 1/5 · LOCKER** wechselt;
- nach Lauf 6 **MIT STICK · 1/5 · LOCKER · LAUF 6/10** angezeigt wird;
- nach Lauf 10 **MIT STICK · 5/5 · SCHNELL · LAUF 10/10** und die vollständige Abschlussaktion erscheint;
- ein ungültiger Lauf Laufnummer, Bedingung und Tempo nicht weiterstellt und dieselbe Vorgabe als Wiederholung zeigt;
- die untere Taste pro Zustand genau eine Start-, Ende-, Weiter- oder Wiederholen-Aktion ausführt;
- die obere Taste vor Abschluss nur den Abbruchdialog und nach 10/10 nur Review/Speichern öffnet.

## Priorisierte reale Testmodelle

Jeder Tester verwendet genau den für sein Modell erzeugten PRG aus dem **neu signierten Fix-Paket**. Das alte Paket mit Hash `918F…6CB8` ist gesperrt. Die Sportzuordnung stellt sicher, dass Eis und Inline in jeder wesentlichen Gerätegruppe vorkommen.

| Tester | Reales Modell | Eingabe / Display | Sport | Review-Ausgang | Priorität und besonderer Fokus |
| --- | --- | --- | --- | --- | --- |
| T01 | `venu2plus` | Touch + 2 Tasten / AMOLED 416 px | Inline | Speichern | Hardware-Baseline; alle vier P0-Fixes und vollständiger End-to-End-Ablauf |
| T02 | `venu2s` | Touch + 2 Tasten / AMOLED 360 px | Eis | Verwerfen | kleinster Touch-Repräsentant; Touchgrenzen und deutsche Textbreite |
| T03 | `venu3` | Touch + 2 Tasten / AMOLED 454 px | Inline | Speichern | großes Touchdisplay; Skalierung, Neutralzonen und Randabstände |
| T04 | `fr255s` | 5 Tasten / MIP 218 px | Eis | Speichern | kleinstes Ring-1-Display; Clipping, obere/untere Taste, lange Fehlertexte |
| T05 | `fr955` | 5 Tasten / MIP 260 px | Inline | Verwerfen | mittleres MIP; Tastenfluss und Abschlussdialoge |
| T06 | `fenix7x` | 5 Tasten / MIP 280 px | Eis | Speichern | großes MIP; Lesbarkeit und Tastenentprellung |
| T07 | `instinct3amoled45mm` | 5 Tasten / AMOLED 390 px | Inline | Speichern | kleines AMOLED mit fünf Tasten; Ready-Auffindbarkeit und Langtexte |
| T08 | `epix2` | 5 Tasten / AMOLED 416 px | Eis | Verwerfen | mittleres AMOLED mit fünf Tasten; bislang fehlende Klassenabdeckung in der Kurzliste |
| T09 | `epix2pro51mm` | 5 Tasten / AMOLED 454 px | Inline | Speichern | großes AMOLED mit fünf Tasten; Abschluss- und Review-Seiten |
| T10 | `fenix9pro51mm` | 5 Tasten / AMOLED 466 px | Eis | Speichern | 466-px-Extremwert; im bisherigen Fake-Responsive-Test nicht enthalten |

T01 bis T04 sind das Mindestgate nach dem Fix. T05 bis T09 schließen die neun tatsächlich vorkommenden Kombinationen aus Display- und Eingabeklasse. T10 ist der verpflichtende 466-px-Randfall, sobald dieses reale Modell verfügbar ist. Ein Simulatorlauf darf einen realen Modelltest nicht als `hardware-verified` ersetzen.

## Eindeutiger Ablauf pro Tester

Jeder Tester protokolliert Modell-ID, Firmware, Sprache, Fix-Commit, PRG-Dateiname, PRG-SHA-256, Datum sowie Ergebnis jedes Schritts. Bei `IQ!`, falschem Hash, abgeschnittenem Pflichttext, falscher Aktion oder Doppelaktion wird sofort gestoppt.

### F00 – Kandidatenidentität

1. Prüfen, dass Commit und SHA-256 dem nach dem P0-Fix neu dokumentierten Kandidaten entsprechen.
2. Bei SHA-256 `918F13E499F338B3F3D81EE1D564C445697F39EE99E290BD305E0195F48D6CB8` nicht installieren und als **gesperrter Vorgängerkandidat** melden.
3. Prüfen, dass der PRG ausdrücklich für die eigene Produkt-ID erzeugt wurde.

### F01 – Ready-Seite

1. App auf Deutsch öffnen und READY/BEREIT, HR-Quellenstatus, Eis-/Inline-Status und Weiter-Aktion auf Clipping prüfen.
2. Tastenmodell: untere Taste darf nichts starten; obere Taste öffnet genau einmal das Startmenü.
3. Touchmodell: außerhalb der Continue-Fläche tippen – keine Aktion; innerhalb tippen – genau ein Wechsel zum Startmenü.

### F02 – Startmenü und P0-A

1. Tastenmodell: Ausgang **TRAINING**; untere Taste nacheinander Kalibrierung, Exit und Training; obere Taste bestätigt nur die sichtbare Auswahl.
2. Touchmodell: Training, Kalibrierung und Exit jeweils mittig antippen und nach jeder Aktion zum Menü zurückkehren.
3. Touchmodell: oberer Leerraum, alle Zwischenräume, Bedienhinweis und unterer Rand – jeder Touch muss neutral bleiben.
4. An jeder sichtbaren Touchgrenze einmal knapp innen und knapp außen tippen; keine Nachbar- oder Doppelaktion zulassen.

### F03 – Sportauswahl und P0-B

1. Training öffnen; prüfen, dass die zuletzt gewählte Sportart nur vorgewählt ist.
2. Tastenmodell: unten wechseln, oben bestätigen. Touchmodell: Eis und Inline jeweils direkt antippen.
3. Touchmodell: Titel, Zwischenraum, Bedienhinweis und Außenflächen antippen; keine Bestätigung darf erfolgen.
4. Zurück zum Menü, Kalibrierung öffnen und dieselben Prüfungen wiederholen.
5. Die laut Testertabelle zugewiesene Sportart für den folgenden Ablauf bestätigen.

### F04 – Training

1. Startbestätigung annehmen und prüfen, dass die Aufzeichnung genau einmal beginnt.
2. Untere Taste: Shift starten, erneut drücken: Shift beenden; mindestens zwei Shifts erfassen.
3. Touch/Swipe auf der Live-Seite darf die Aufzeichnung weder speichern noch beenden.
4. Obere Taste speichert genau einmal.
5. Abschlussseiten auf Trainingsdauer in Minuten, HR-Werte, Shiftzahl, Eis-/Bankzeit und Clipping prüfen; danach zum Startmenü zurückkehren.

### F05 – Kalibrierungs-Intro

1. Kalibrierung und die zugewiesene Sportart wählen.
2. Sichtbar bestätigen: **20,00 m**, **5 ohne Stick + 5 mit Stick**, richtige Sportart.
3. Obere Taste einmal testen und den Abbruchdialog mit **Nein** schließen; Kalibrierung muss erhalten bleiben.
4. Mit der unteren Taste beginnen.

### F06 – Geführte Läufe und P0-D

1. Einmal absichtlich unter zwei Sekunden markieren; die Seite muss denselben Lauf mit verständlicher Wiederholen-Meldung zeigen und darf keinen gültigen Lauf zählen.
2. Zehn gültige 20-m-Läufe durchführen: je Block locker, schnell, normal, locker, schnell; zuerst fünf ohne, danach fünf mit Stickhandling.
3. Jeder Lauf: unten Start, unten Ende, Ergebnis lesen, unten Weiter beziehungsweise Wiederholen.
4. Accepted-Seiten nach Lauf 1, 5, 6 und 10 wörtlich gegen P0-D prüfen und fotografisch oder schriftlich protokollieren.
5. Vor 10/10 obere Taste testen und den Abbruchdialog mit **Nein** schließen; sie darf nicht speichern.
6. Nach 10/10 muss die obere Taste ausschließlich Review/Speichern öffnen.

### F07 – Review und P0-C

1. Sport, 10/10, Gesamtfaktor und beide Bedingungsmediane vollständig lesen können.
2. Touchmodell: Faktor und beide Medianzeilen antippen – keine Aktion.
3. Touchmodell: sichtbare Speichern-Aktion antippen – nur Speichern; bei T02 stattdessen sichtbare Verwerfen-Aktion antippen – unmittelbar verwerfen.
4. Tastenmodell: laut Testertabelle obere Taste für Speichern oder untere Taste für Verwerfen verwenden; genau der gewählte Pfad muss ohne weitere Bestätigung folgen.
5. Keine Aktion darf einen Bestätigungsdialog oder eine zweite Aktivierung durch denselben Tastendruck/Touch erzeugen.

### F08 – Ergebnis und Rückkehr

1. Speicherpfad: eindeutige Erfolgsmeldung, danach Select/Back zum Startmenü; Ready muss nur für die getestete Sportart einen lokalen Kalibrierstatus zeigen.
2. Verwerfen-Pfad: Rückkehr ohne neuen Faktor; zuvor vorhandene Profile der anderen Sportart bleiben unverändert.
3. Fehler- und Ergebnistext auf Abschneiden, Rundrandkontakt und Überlagerung prüfen.
4. Ein kurzes Training mit der geprüften Sportart starten und speichern; keine `IQ!`-Anzeige und keine falsche Sportzuordnung zulassen.

### F09 – Ergebnisprotokoll

Pro Schritt `PASS`, `FAIL` oder `N/A` mit Begründung erfassen. Ein `FAIL` in F00, F02, F03, F06 oder F07 blockiert das Modell und den gesamten Fix-Kandidaten. Ein bestandener Test gilt nur für das tatsächlich geprüfte Modell, nicht automatisch für seine Klasse oder alle 50 Ring-1-Ziele.

## Priorisierte Restpunkte

### P0 – vor Task-7-Abschluss

- [x] Review-Touchzonen auf die sichtbaren Aktionen legen und Tests direkt auf den gezeichneten Speichern-/Verwerfen-Hinweisen ausführen.
- [x] Laufnummer, Bedingung und Tempo auf der Accepted-Seite semantisch auf denselben Lauf beziehen; Übergänge 1→2, 5→6 und 9→10 explizit testen.
- [x] Touchflächen im Startmenü auf die sichtbaren Einträge begrenzen; Touch auf Bedienhinweis und Leerraum darf Exit nicht auslösen.
- [x] Touchflächen der Sportauswahl auf Eis/Inline begrenzen; Titel, Leerraum und Bedienhinweis müssen neutral bleiben.
- [x] Responsive-Test um 466 px und kurze getrennte Runddisplay-Zeilen in englischen und deutschen Ressourcen erweitern.
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
| Signiertes Paket `918F…6CB8` | **gesperrt – enthält die vier P0-Befunde** |
| Neuer Fix-Kandidat | **Commit `7fef470`, SHA-256 `4E6A62C4…D40DF`, 69/69 Varianten** |
| Responsive Koordinatenprüfung | **bestanden einschließlich 466 px** |
| Touch-Interaktion | **275/275 Gesamttests bestanden** |
| Semantische Laufsynchronität | **über alle zehn Läufe bestanden** |
| Visuelle Simulatorabnahme | **Venu 2S bestanden; weitere Modelle im Remote-Test** |
| Physische Hardwareabnahme | **offen** |

Task 7 bleibt bis zu realen Testergebnissen **in Arbeit**. Der eindeutig
identifizierte Fix-Kandidat ist zur kontrollierten Remote-Abnahme freigegeben;
Portalveröffentlichung und pauschale Hardwarefreigabe bleiben offen.
