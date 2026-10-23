# Beta 6 – Hardware-UI-Abnahme auf der Venu 2 Plus

Stand: 23. Oktober 2026

Prüfkandidat: Beta 6, Commit `43694fc`

Zielgerät: Garmin Venu 2 Plus

Automatisierter Ausgangsstand: 247/247 Watch-Tests grün; die Prüfung am physischen Gerät ist noch offen.

## Aktueller UI-Gate-Status

- **Quellcode-Gate: bestanden.** Commit `43694fc` zeichnet Bedingung, das zur laufenden Wiederholung gehörende Tempo und die Dauer in Minuten. Die obere Taste ist konsistent als `UPPER: CANCEL` beschriftet. Review-Touches führen nur innerhalb der beiden Optionszonen die direkt berührte Aktion aus.
- **Simulator-Gate: bestanden.** Die gemeldete vollständige Suite umfasst 247/247 grüne Watch-Tests; die neuen Fälle decken Run-Texte, Cancel-Beschriftung, beide Review-Zonen und Touches außerhalb der Zonen ab.
- **Hardware-Gate: offen.** Noch nicht nachgewiesen sind Lesbarkeit, reale Tastenbelegung, Treffergenauigkeit und Entprellung auf der Venu 2 Plus. Diese offenen Punkte sind unten als P0-Prüfungen aufgeführt.

## Zweck und Freigabegrenze

Diese Checkliste prüft ausschließlich Lesbarkeit, Bedienwege, Eingabekollisionen und Fehlermeldungen der bereits implementierten Beta-6-Oberfläche. Sie ist keine Grundlage für eine losgelöste Neugestaltung oder Veröffentlichung.

Beta 6 ist für den Gerätetest nur freigabefähig, wenn alle P0-Punkte bestanden sind. Ein einzelner Tastendruck oder Touch darf jeweils höchstens eine Aktion auslösen. Nach der Auswahl von **AKTIVIEREN** oder **VERWERFEN** und dem bestätigenden Tastendruck darf keine zusätzliche Bestätigungsabfrage erscheinen.

Ergebniskennzeichen:

- `[ ]` offen
- `[x]` bestanden
- `[!]` fehlgeschlagen; Fehler mit Foto oder kurzer Reproduktionsfolge dokumentieren
- `[–]` nicht anwendbar; begründen

## Vorbereitung

- [ ] Installierten Build eindeutig als Beta 6 und Commit `43694fc` dokumentieren.
- [ ] Uhr neu starten und sicherstellen, dass keine ältere App-Instanz im Speicher aktiv ist.
- [ ] Einen Durchlauf ohne persönliches Profil und einen Durchlauf mit gespeichertem lokalen Profil vorsehen.
- [ ] Einen Durchlauf mit verfügbarer HR-Quelle und einen ohne erkannte HR-Quelle vorsehen.
- [ ] Testdaten und FIT-Dateien nur lokal prüfen; diese Checkliste autorisiert keinen Upload und keine Veröffentlichung.

## P0 – Startseite und Eingabetrennung

- [ ] **Untere Taste:** Einmaliges Drücken startet unmittelbar das normale Training und öffnet weder Menü noch Kalibrierung.
- [ ] **Obere Taste:** Einmaliges Drücken öffnet ausschließlich das Menü mit **KALIBRIERUNG** und **EXIT**; das Training startet nicht.
- [ ] **Touch „Menü“:** Ein Touch im linken Touchbereich öffnet ausschließlich das Menü.
- [ ] **Touch „Ready/Start“:** Ein Touch im Startbereich startet ausschließlich das normale Training.
- [ ] **Neutraler Abstand:** Touches im Abstand zwischen den beiden Bereichen sowie außerhalb des unteren Bedienbands lösen keine Aktion aus.
- [ ] **Grenzbereiche:** Je drei Touches knapp innerhalb und außerhalb jeder Bereichsgrenze führen nie zu einer Doppelaktion oder zur benachbarten Aktion.
- [ ] **Entprellung:** Schnelles einmaliges Tippen oder Drücken erzeugt genau einen Seitenwechsel; gehaltene Taste und gleichzeitiger Touch erzeugen keine zweite Aktion.
- [ ] **Lesbarkeit:** `SOURCE UNKNOWN` und die Profilzeile überlappen einander, die unteren Schaltflächen oder den runden Displayrand nicht.
- [ ] **Ohne Profil:** `BASELINE · NO PERSONAL FACTOR` ist vollständig und ohne Abschneiden lesbar.
- [ ] **Mit Profil:** Oberfläche, Faktor und `LOCAL` sind vollständig lesbar; `SOURCE UNKNOWN` bleibt als getrennte Quellenanzeige erkennbar.

## P0 – Menü KALIBRIERUNG / EXIT

- [ ] Beim Öffnen ist **KALIBRIERUNG** eindeutig ausgewählt.
- [ ] Die obere Taste wechselt sichtbar und genau einmal zwischen **KALIBRIERUNG** und **EXIT**.
- [ ] Die untere Taste führt die aktuell sichtbare Auswahl sofort aus; es erscheint keine zusätzliche Bestätigung.
- [ ] Ein direkter Touch auf die obere Hälfte öffnet ausschließlich **KALIBRIERUNG**.
- [ ] Ein direkter Touch auf die untere Hälfte führt ausschließlich **EXIT** aus.
- [ ] Touches unmittelbar oberhalb und unterhalb der Bildschirmmitte lösen nie den falschen Eintrag oder zwei Aktionen aus.
- [ ] Auswahlmarkierung, beide Beschriftungen und Bedienhinweis sind ohne Überlagerung oder Abschneiden lesbar.

## P0 – Kalibrierungs-Setup

- [ ] Alle acht Kombinationen sind erreichbar: Eis und Inline jeweils mit 20, 22, 25 und 30 m.
- [ ] Vorwärts- und Rückwärtswechsel laufen in der erwarteten Reihenfolge und überspringen keine Kombination.
- [ ] Oberfläche und Distanz sind jederzeit vollständig sichtbar; `20 m`, `22 m`, `25 m` und `30 m` sind eindeutig unterscheidbar.
- [ ] Tasten, Wischgesten und der sichtbare Bedienhinweis beschreiben dieselbe Bedienung.
- [ ] Start per unterer Taste oder direktem Touch beginnt genau einen Testdurchlauf.
- [ ] Touches auf Überschrift oder Optionsanzeige starten nicht unbeabsichtigt. Falls sie den Test auslösen, als P0-Eingabekollision protokollieren.

## P0 – Laufende Kalibrierung

- [ ] Die aktuelle Bedingung ist sichtbar: **ohne Stickhandling** oder **mit Stickhandling**.
- [ ] Das geforderte Tempo ist sichtbar und eindeutig der aktuellen Wiederholung zugeordnet.
- [ ] Die Dauer wird sichtbar in Minuten dargestellt; Einheit und Zahlenwert sind ohne Interpretation verständlich.
- [ ] Wiederholungsnummer und Zustand **Ready**, **Run** oder **End** bleiben getrennt und gut lesbar.
- [ ] Die untere Taste setzt pro Druck genau eine Start- beziehungsweise Endmarke.
- [ ] Direkter Touch setzt pro Touch genau eine Marke; Wischen, Randberührung und Handballen erzeugen keine unbeabsichtigte Marke.
- [ ] Gleichzeitiger Touch und Tastendruck erzeugen keine doppelte Marke und überspringen keine Wiederholung.
- [ ] Die Funktion der oberen Taste stimmt mit dem eingeblendeten Text überein. Eine Anzeige `UPPER: SAVE` darf nicht abbrechen oder verwerfen.
- [ ] Nach der letzten gültigen Wiederholung öffnet sich genau einmal die Review-Seite.

Quellstand-Hinweis: Bedingung, Tempo und Minuten werden nun gezeichnet; die
obere Taste und der Hinweis lauten konsistent `UPPER: CANCEL`. Simulatorisch
ist dies abgedeckt, die Lesbarkeit und das tatsächliche Tastenverhalten auf der
Venu 2 Plus bleiben P0-Hardwareprüfungen.

## P0 – Review und Ergebnis

- [ ] Faktor sowie **AKTIVIEREN** und **VERWERFEN** sind gleichzeitig, vollständig und ohne Randbeschnitt lesbar.
- [ ] Die obere Taste wechselt die Auswahl genau einmal; die Markierung ist auch ohne Farberkennung eindeutig.
- [ ] Die untere Taste führt die sichtbare Auswahl unmittelbar aus; es folgt keine zusätzliche Bestätigung.
- [ ] Direkter Touch auf **AKTIVIEREN** aktiviert und speichert ausschließlich diesen Kandidaten.
- [ ] Direkter Touch auf **VERWERFEN** verwirft ausschließlich diesen Kandidaten.
- [ ] Ein Touch auf **VERWERFEN** darf niemals die zuvor ausgewählte Aktion **AKTIVIEREN** auslösen.
- [ ] Nach Aktivierung erscheint eindeutig **CALIBRATION ACTIVATED** und die Startseite zeigt anschließend Oberfläche, Faktor und `LOCAL`.
- [ ] Nach Verwerfen bleibt das bisherige Profil unverändert; ohne vorhandenes Profil erscheint weiterhin die Baseline-Anzeige.
- [ ] Nach Auswahl und Tastendruck gibt es keinen zusätzlichen Bestätigungsdialog und keinen zweiten erforderlichen Tastendruck.

Quellstand-Hinweis: `CalibrationSummaryView.onTap()` wertet nun die vertikale
Touchposition aus und führt die berührte Option aus. Beide Zielbereiche sind
simulatorisch abgedeckt; die reale Treffergenauigkeit bleibt eine
P0-Hardwareprüfung.

## P0 – Fehlermeldungen und sichere Zustände

- [ ] `FIT SAVED · STORAGE ERROR · QUARANTINE` ist vollständig lesbar, läuft nicht über den runden Rand und überlappt keine Bedienfläche.
- [ ] Bei Speicherfehler wird der Kandidat nicht als lokales Profil angezeigt und nicht stillschweigend aktiviert.
- [ ] Fehlerzustand und Erfolgsmeldung sind textlich klar unterscheidbar; Farbe ist nicht das einzige Signal.
- [ ] Fehlende Bewegungsdaten oder eine ungültige Wiederholung führen nicht zu einem scheinbar erfolgreichen Ergebnis.
- [ ] Ein allgemeiner Aufnahmefehler zeigt einen lesbaren Fehlercode sowie die tatsächlich verfügbaren Aktionen.
- [ ] **Retry** startet genau einen Wiederholungsversuch und erzeugt keine zweite Aufnahme.
- [ ] Das Verwerfen einer noch ausstehenden normalen Trainingsaufnahme bleibt durch die vorhandene Sicherheitsabfrage geschützt; dies ist getrennt von der bestätigungsfreien Kalibrierungs-Review.
- [ ] Nach jedem Fehler ist eine definierte Rückkehr zu Startseite, Review oder Aufnahme möglich; kein schwarzer Bildschirm, keine Endlosschleife und kein Absturz.

## P1 – Lesbarkeit unter realen Bedingungen

- [ ] Alle P0-Seiten bei Hallenlicht, direkter Beleuchtung und reduzierter Displayhelligkeit prüfen.
- [ ] Kleine Schrift aus normalem Blickabstand am Handgelenk lesen; keine wichtige Information darf nur beim Heranführen der Uhr erkennbar sein.
- [ ] Runde Displayränder schneiden keine Buchstaben, Zahlen, Einheiten oder Auswahlrahmen ab.
- [ ] Schnelle Zustandswechsel flackern nicht und hinterlassen keine Textreste der vorherigen Seite.
- [ ] Nach Display-Timeout oder automatischer Sperre bleibt der aktuelle Zustand erhalten und der erste Eingabeimpuls erzeugt keine unbeabsichtigte Aktion.
- [ ] Bedienung mit Handschuh und feuchtem Display erzeugt keine Doppelaktivierung oder falsche Auswahl.
- [ ] Deutsche und englische Texte passen in dieselben Bereiche; besonders lange Fehler- und Profiltexte werden nicht abgeschnitten.

## P1 – Durchgängiger Ablauf

- [ ] Setup → Run → Review → Aktivieren → Startseite einmal vollständig ohne Zurückspringen oder zusätzliche Bestätigung durchlaufen.
- [ ] Setup → Run → Review → Verwerfen → Startseite einmal vollständig ohne Profiländerung durchlaufen.
- [ ] Menü → EXIT kehrt ohne versehentlichen Trainingsstart oder Kalibrierungsstart zurück.
- [ ] Normales Training bleibt unabhängig vom Kalibrierungsmodul über die untere Taste erreichbar.
- [ ] Auf der Startseite ist die HR-Quelle eindeutig erkennbar; unbekannte Herkunft wird weiterhin ehrlich als `SOURCE UNKNOWN` angezeigt.

## P2 – Beobachtungen ohne Freigabeblockade

- [ ] Subjektive Verständlichkeit der Begriffe, Abstände und visuellen Gewichtung notieren.
- [ ] Reaktionszeit zwischen Eingabe und Seitenwechsel notieren, falls sie die Bedienung verunsichert.
- [ ] Verbesserungsvorschläge getrennt von reproduzierbaren Fehlern erfassen; keine spontane UI-Neugestaltung in diesen Prüflauf aufnehmen.

## Ergebnisprotokoll

| Priorität | Seite | Prüfschritt | Ergebnis | Beobachtung / Reproduktion |
| --- | --- | --- | --- | --- |
| P0 |  |  |  |  |
| P0 |  |  |  |  |
| P1 |  |  |  |  |
| P2 |  |  |  |  |

## Freigabeentscheidung

- [ ] Alle P0-Punkte bestanden.
- [ ] Keine überlappenden oder abgeschnittenen Pflichtinformationen.
- [ ] Keine falsche, doppelte oder unbeabsichtigte Aktion durch Taste oder Touch.
- [ ] Run zeigt Bedingung, Tempo und Dauer in Minuten tatsächlich auf dem Gerät.
- [ ] Review-Touch führt direkt die berührte Aktion aus.
- [ ] Die obere Run-Aktion und ihre Beschriftung stimmen überein.
- [ ] Fehlermeldungen sind lesbar und führen in einen sicheren, nachvollziehbaren Zustand.
- [ ] Offene P1-/P2-Beobachtungen sind dokumentiert und einer späteren Entscheidung zugeordnet.

Die drei zuvor auf Quellstand-Ebene sichtbaren P0-Konflikte sind behoben. Es
verbleiben ausschließlich Hardware-Nachweise: Lesbarkeit und Randabstände aller
Pflichttexte, tatsächliche Zuordnung und Entprellung der oberen und unteren
Taste, sichere Trennung aller Touchbereiche, direkte Treffergenauigkeit der
Review-Zonen, bestätigungsfreie Ausführung der gewählten Review-Aktion sowie
vollständig lesbare und sicher verlassbare Fehlerzustände. Bis diese Punkte auf
der echten Venu 2 Plus bestanden sind, bleibt die Hardware-UI-Freigabe
**offen**.
