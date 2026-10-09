# Experimentelles Hockey-Bewegungsprofil (Venu 2 Plus)

Stand: 2026-09-28. Dieser Vorschlag wurde mit `hockey-evidence::render_algorithm_proposal` in Literaturbefund, Transferannahme, App-Modell und Validierung getrennt. **Er ist keine validierte Schritt- oder Distanzmessung.**

## 1. Literaturbefund

- **doi:10.1371/journal.pone.0127324** — Volltext in dieser Arbeitssitzung geprüft: Bei 30-m-Eishockey-Sprints unterscheiden sich Antritts- und spätere Skating-Strides biomechanisch. Gemessen wurde u. a. mit einem Beschleunigungssensor am Skate, Kraftsensorik und EMG, **nicht** mit einer Uhr am Handgelenk. [Primärstudie](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0127324)
- **hockey-skating-khandan-2022 / doi:10.1038/s41598-022-26777-9** — Der lokale Skill-Korpus führt diese Studie als `abstract_only`; der Methodenabschnitt wurde für dieses Design separat gelesen. Skate-/Becken-IMUs mit 100 Hz wurden auf synthetischem Eis mit Laborreferenzen verglichen. Diese Fehlerwerte sind nicht auf die Venu-Uhr übertragbar. [Primärstudie](https://pmc.ncbi.nlm.nih.gov/articles/PMC9790001/)
- **doi:10.3390/s21144650** — Abstract in dieser Arbeitssitzung geprüft: Ein 100-Hz-Sensor am Hockeyschläger unterschied Hockeyaktionen bei einem ungesehenen Spieler mit 76 % Genauigkeit. Das ist ein Hinweis auf relevante Stock-/Armbewegungen, kein validierter Ausschlussfilter für Skating-Anschübe an der Uhr. [Primärstudie](https://pmc.ncbi.nlm.nih.gov/articles/PMC8309498/)

## 2. Transferannahmen

Eine 10-Hz-Uhr am Handgelenk beobachtet weder Blattkontakt noch Beinanschub direkt. Drei regelmäßige Handgelenkspeaks könnten spezifischer als zwei sein, können aber echte kurze Antritte auslassen und rhythmische Stockarbeit weiterhin verwechseln. Diese Annahmen sind **nicht ausreichend belegt**. Die vom Nutzer vorgegebenen 1,25 m (frühe Anschübe) und 2,25 m (spätere Anschübe) sind vorläufige Modellparameter, keine sportwissenschaftlich nachgewiesenen individuellen Stridelängen. Eis und Inline dürfen ohne getrennte Kriteriumsdaten keine behauptete gleiche Genauigkeit erhalten.

## 3. ShiftSense-Modell

**Eingaben:** Beschleunigung und Gyroskop vom vorhandenen maximal 10-Hz-Sensorlistener, Millisekunden-Zeitstempel, manuelle Shift-Grenzen. Die App speichert keine Rohsensorserien.

- Kandidat: dynamischer Betrag mindestens 150 mg, nahe Gyroskopprobe mindestens 40 °/s innerhalb 100 ms, Sperrzeit 350 ms.
- Bestätigung: drei Kandidaten mit jeweils 350–1300 ms Abstand. Erst beim dritten werden die drei Ereignisse rückwirkend gezählt. Ein oder zwei Kandidaten bleiben `unconfirmed` und erzeugen keine Distanz.
- Antritt: erste vier **bestätigte** Ereignisse nach einem 2000-ms-Ruheübergang mit je 125 cm. Danach `rhythm` mit je 225 cm. Eine manuelle Shift-Grenze allein erzeugt keinen neuen Antritt.
- `no_push` bedeutet nur „im beobachteten Intervall kein bestätigter Anschub“, **nicht** eine bewiesene Gleitphase. Stopps, Richtungswechsel, Crossovers und Schüsse werden nicht eigenständig identifiziert.
- Distanz = Summe der bestätigten Anschub-Mittelpunkte; keine Extrapolation für Gleitstrecken. Die 10-s-Kadenz leitet sich aus denselben Ereignissen ab und treibt die Distanz nicht.
- Qualitätsgates: aktiver manueller Shift; beide Achsensätze und monoton steigende Zeitstempel; keine Interpolation über Datenlücken; fehlendes Signal als unbekannt statt als Nullleistung. HR ist kein Anschubsignal.

**Freie Parameter:** 150 mg, 40 °/s, 100 ms Ausrichtung, 350 ms Sperrzeit, 350–1300 ms Rhythmus, 2000 ms Ruhe, vier kurze Anschübe sowie 125/225 cm. Diese Werte sind technische Startwerte und später anhand unabhängiger Daten zu prüfen.

## 4. Validierungsplan

**Referenz:** Synchronisiertes Video mit unabhängig gezählten linken/rechten Skate-Anschüben und markierter 20–30-m-Strecke. Pro Oberfläche (Eis/Inline) Antritt, regelmäßiges Skaten, längeres Rollen/Gleiten, Stoppen, Crossovers, Schüsse und Stockhandling getrennt aufnehmen; mindestens eine komplette Einheit pro Oberfläche zurückhalten.

**Vorab festzulegende Fehlermaße:** Präzision/Recall des Anschubzählers, absoluter Zählfehler pro Shift, absoluter Distanzfehler in Metern, relativer Fehler nur für Strecken >0, Fehlzählungen bei Stockarbeit/Bank, Sensorabdeckung und Akkuverbrauch. Für 10-Hz-Handgelenk-Hockeysensorik liegen hier keine belastbaren Akzeptanzschwellen vor. Vor einer Genauigkeitsaussage müssen diese vorab festgelegt und an unabhängigen Kriteriumsdaten geprüft werden.
