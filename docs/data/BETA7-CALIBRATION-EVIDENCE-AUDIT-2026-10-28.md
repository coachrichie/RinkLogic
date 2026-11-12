# Beta 7: Evidenz- und Methodenaudit der 20-m-Kalibrierung

Stand: 28. Oktober 2026  
Autor: Richard Dominik Haimerl Schwarzwaldau  
Geprüfter Implementierungsstand: `3059786`

## Kurzurteil

Das Beta-7-Protokoll mit einer unabhängig vermessenen geraden 20-m-Strecke,
fünf gültigen Läufen ohne Stickhandling und fünf gültigen Läufen mit
Stickhandling ist als **standardisierte lokale persönliche Kalibrierung
plausibel**. Es ist aber kein in der Literatur validierter Kalibrierstandard.
Die zehn Läufe dürfen technische Konsistenz und einen lokalen Medianfaktor
begründen, nicht Genauigkeit, Übertragbarkeit oder einen populationsweiten
Koeffizienten.

Die getrennten Eis- und Inline-Profile sind wissenschaftlich vorsichtiger als
ein gepoolter Faktor. Ähnliche Grundmuster des Gleitens reichen wegen anderer
Reibung, Ausrüstung, Geschwindigkeit und Bewegungsausführung nicht aus, um
beide Oberflächen gleichzusetzen. Die Literatur validiert jedoch auch nicht,
dass je Oberfläche genau ein Multiplikator alle Fehlerquellen korrigiert.

Die Beta-7-Kadenzanalyse bleibt zu Recht Shadow-Evidenz. Die App-Kadenz
`erkannte Anschübe / Zeit` und die sogenannte effektive Schrittlänge
`Referenzdistanz / erkannte Anschübe` teilen denselben erkannten Zähler. Eine
negative Beziehung kann dadurch schon algebraisch entstehen. Ohne unabhängige
Skate-Ereignisse oder eine räumliche Referenz darf daraus kein
kadenzabhängiger Live-Distanzterm entstehen.

## Verbindliche Produktgrenze

Beta 7 besteht aus zwei experimentellen, aber getrennten Ebenen:

1. **Schätzmodell:** Die unkalibrierte Distanz entsteht aus erkannten
   Handgelenkereignissen und einem begrenzten Basismodell. Körpergewicht und
   BMI verändern die Distanz nicht.
2. **Persönliche Kalibrierung:** Ein ausdrücklich aktivierter lokaler Faktor
   korrigiert die Basisschätzung nur für die gewählte Oberfläche.

Der Stand enthält keinen GPS-Zwang, keine automatische Cloud-Übertragung, kein
globales Modelltraining und keine automatische Aktivierung. Ein fehlendes,
beschädigtes oder zur Oberfläche unpassendes Profil muss auf das Basismodell
zurückfallen. Ein Eisfaktor darf nicht für Inline verwendet werden und
umgekehrt.

## Rechercheumfang

Am 28. Oktober 2026 wurden PubMed, Crossref und OpenAlex mit vier fokussierten
englischen Suchanfragen geprüft. Die APIs lieferten bibliografische
Kandidaten; relevante Aussagen wurden anschließend an Primärquellen oder
systematischen Reviews geprüft. Crossref und OpenAlex waren jeweils auf 100
Treffer begrenzt und enthielten zahlreiche thematisch unpassende Einträge.
Nicht gefundene Direktstudien sind daher ein begrenztes Suchergebnis, kein
Beweis universeller Abwesenheit.

Das vollständige maschinenlesbare Suchprotokoll liegt in
[`BETA7-EVIDENCE-SEARCH-2026-10-28.jsonl`](BETA7-EVIDENCE-SEARCH-2026-10-28.jsonl).

| Suchanfrage | PubMed | Crossref | OpenAlex | Grenze |
|---|---:|---:|---:|---|
| `ice hockey 20 m skating sprint reliability` | 1 | 100 | 100 | Crossref/OpenAlex gekappt |
| `ice hockey puck stickhandling skating performance` | 0 | 100 | 100 | geringe bibliografische Präzision |
| `ice hockey skating stride length cadence wearable` | 0 | 100 | 43 | Wrist-Transfer nicht abgedeckt |
| `inline hockey inline skating stride cadence biomechanics` | 0 | 100 | 10 | überwiegend Inline-Speedskating |

## Relevante Evidenz

| Evidenz-ID | Reviewstatus | Befund | Grenze für RinkLogic |
|---|---|---|---|
| `hockey-sprint-distance-stastny-2023` | relevante Volltextteile geprüft | Meta-Analyse von 60 Studien: Geschwindigkeit steigt bis etwa 26 m; 30 m wird für Maximalgeschwindigkeit empfohlen. | 20 m erfasst einen relevanten Beschleunigungs-/Übergangsabschnitt, aber keine sichere Maximalgeschwindigkeit. |
| `hockey-20m-jablonka-2026` | Abstract und Repository-Metadaten geprüft | 60 männliche Spieler absolvierten 20-m-On-Ice-Sprints; kontinuierliche Geschwindigkeitsprofile unterschieden Leistungsgruppen. | Belegt 20 m als brauchbare Testdistanz, nicht als Garmin-Kalibrierstandard oder bekannte-Distanz-Faktorverfahren. |
| `hockey-sprint-imu-khandan-2026` | Abstract geprüft | 19 Eis-Skater; IMUs unterschieden Kaliber und Skatingtyp über Stride-Länge und -Geschwindigkeit. | Sensororte und Ereignisdefinitionen sind nicht mit einer Garmin-Uhr am Handgelenk gleichzusetzen. |
| `hockey-skating-khandan-2022` | relevante Volltextteile geprüft | Zehn Skater auf 14 m synthetischem Eis; Skate-/Schienbein-/Becken-IMUs gegen Motion Capture und Drucksohlen. | Zeigt, dass räumlich-zeitliche Skatingparameter kriteriumsbezogen messbar sind; validiert keine Wrist-Push-Distanz. |
| `hockey-testing-bournival-2023` | relevante Volltextteile geprüft | Systematischer Review von 107 Studien und 55 On-Ice-Tests; Tests mit und ohne Puck können unterschiedliche leistungsrelevante Aspekte zeigen. | Unterstützt getrennte Aufgabenbedingungen, nicht die konkrete Zahl fünf oder den Garmin-Detektor. |
| `rink-hockey-stick-arboix-2024` | Abstract geprüft | 49 Rink-Hockey-Spieler; Stickhalten veränderte den 10-m-Sprint nicht relevant, eine COD-Richtung geringfügig. | Nur indirekt: Rink Hockey, Stickhalten statt aktives Puckhandling, keine Wrist-Sensorik. |
| `ice-stride-upjohn-2008` | Abstract geprüft | Hochklassige Hockeyspieler zeigten größere Bewegungsumfänge und größere Stride-Länge bei ähnlichen groben Stride-Raten. | Stützt keine einfache universelle Kadenz-zu-Länge-Funktion. |
| `ice-cadence-marino-1977` | Abstract geprüft | Bei drei Eis-Skating-Geschwindigkeiten änderte sich die Stride-Rate, die Stride-Länge nicht signifikant. | Zeigt kontextabhängige Kadenzbeziehungen und widerspricht einem naiven monotonen Längenterm. |
| `ice-inline-deboer-1987` | Abstract geprüft | Bei trainierten Speedskatern waren mehrere physiologische Größen und Stroke-Frequenz ähnlich; Roller-Skating hatte geringere Maximalgeschwindigkeit und einen anderen Oberschenkelwinkel. | Begründet Ähnlichkeit und zugleich Oberflächentrennung; kein Inline-Hockey-Faktor. |
| `inline-speed-wu-2025` | relevante Volltextteile geprüft | Scoping Review: begrenzte und heterogene Inline-Speedskating-Biomechanik. | Keine direkte Inline-Hockey- oder Garmin-Validierung. |

Primärlinks:

- [Stastny et al. 2023, Sprintdistanzen](https://pmc.ncbi.nlm.nih.gov/articles/PMC10286618/)
- [Jablonka et al. 2026, 20-m-Geschwindigkeitsprofile](https://doi.org/10.3390/sports14070290)
- [Khandan et al. 2026, Wearable-Sprintmetriken](https://doi.org/10.1007/s10439-026-04146-1)
- [Khandan et al. 2022, räumlich-zeitliche Skatingparameter](https://pmc.ncbi.nlm.nih.gov/articles/PMC9790001/)
- [Bournival et al. 2023, On-Ice-Tests](https://www.frontiersin.org/journals/sports-and-active-living/articles/10.3389/fspor.2023.1252093/full)
- [Arboix-Alió et al. 2024, Stickhalten im Rink Hockey](https://doi.org/10.3390/biomechanics4010009)
- [Upjohn et al. 2008, Hockey-Skating-Kinematik](https://pubmed.ncbi.nlm.nih.gov/18610773/)
- [Marino 1977, Stride-Rate und -Länge](https://doi.org/10.1080/10671315.1977.10762155)
- [de Boer et al. 1987, Eis versus Roller](https://pubmed.ncbi.nlm.nih.gov/3653098/)
- [Wu et al. 2025, Inline-Speedskating-Review](https://doi.org/10.3390/app15147994)

## Claim-Audit

### 1. Feste 20-m-Strecke

**Claim:** 20 m sind eine plausible kontrollierte Distanz für eine lokale
Hockey-Kalibrierung.  
**Bewertung:** `gestützt`, aber nur als Teststrecke.  
**Begründung:** Direkte Hockeyarbeiten verwenden 14, 20 und 30 m; die
Sprintdistanz-Meta-Analyse ordnet 20 m in den Beschleunigungs-/Übergangsbereich
ein. Der feste Wert reduziert Eingabe- und Referenzfehler und passt praktisch
auf viele gerade Hallenabschnitte.

**Nicht zulässiger Claim:** 20 m repräsentieren Maximalgeschwindigkeit, eine
komplette Hockeyschicht oder die optimale universelle Kalibrierstrecke.  
**Bewertung:** `nicht ausreichend belegt`. Geschwindigkeit kann bis etwa 26 m
weiter steigen; Kurven, Stopps, Crossovers, Rückwärtsfahren und Neustarts
fehlen.

### 2. Fünf Läufe ohne und fünf mit Stickhandling

**Claim:** Beide Bedingungen getrennt zu prüfen ist methodisch sinnvoll.  
**Bewertung:** `nur indirekt gestützt`.  
**Begründung:** Puck-/Stickaufgaben können eine andere sportartspezifische
Leistung abbilden. Für eine Handgelenkerkennung ist die Trennung besonders
vorsichtig, weil Stock- und Armbewegung Ereignisse erzeugen, verdecken oder
verdoppeln kann.

**Claim:** Fünf Läufe je Bedingung sind eine wissenschaftlich validierte
Mindestzahl.  
**Bewertung:** `nicht ausreichend belegt`.  
**Begründung:** Fünf Werte erlauben einen persönlichen Median und eine grobe
MAD-Konsistenzprüfung. Sie tragen keine belastbare Inferenz, keine
Populationsschätzung und keine zuverlässige Korrelation. Die feste Reihenfolge
`locker, schnell, normal, locker, schnell` vermischt Tempovorgabe mit
Reihenfolge, Lernen und Ermüdung.

### 3. Kadenz und effektive Schrittlänge

**Claim:** Skatinggeschwindigkeit, Ereignisfrequenz und räumliche
Skatingparameter stehen grundsätzlich in Beziehung.  
**Bewertung:** `gestützt` für kriteriumsbezogene Skate-/Körpermessungen.

**Claim:** RinkLogic-Kadenz kann die individuelle biomechanische Schrittlänge
aus fünf Läufen je Bedingung bestimmen.  
**Bewertung:** `nicht ausreichend belegt`.  
**Begründung:** Ein erkanntes Wrist-Ereignis ist weder Skate-Step noch
Same-Skate-Stride oder Glide. Zudem gilt:

```text
Kadenz = erkannte Anschübe / Zeit
Referenzmeter je erkanntem Ereignis = 20 m / erkannte Anschübe
```

Der gemeinsame Zähler erzeugt mathematische Kopplung. Spearman und Theil-Sen
sind deshalb nur deskriptive Diagnostik. Die Berichtsspalte sollte als
**Referenzmeter je erkanntem Uhrenereignis** bezeichnet werden; „effektive
Schrittlänge“ ist kein biomechanischer Befund.

### 4. Getrennte persönliche Eis-/Inline-Profile

**Claim:** Eis und Inline nicht zu poolen ist die vorsichtigere Architektur.  
**Bewertung:** `nur indirekt gestützt`.  
**Begründung:** Die Bewegungsarten haben verwandte Gleitmuster, unterscheiden
sich aber in Reibung, maximaler Geschwindigkeit, Ausrüstung, Untergrund und
einzelnen Haltungs-/Technikmerkmalen. Ein lokaler Faktor kann zusätzlich
Detektor-, Uhrenarm-, Stickhandling- und Basismodellfehler gemeinsam aufnehmen.

**Nicht zulässiger Claim:** Das getrennte Profil sei eine validierte
biomechanische Eigenschaft oder über Geräte, Hallen, Firmware und Modellstände
stabil.  
**Bewertung:** `nicht ausreichend belegt`.

## Implementierungsabgleich Beta 7

| Vertrag | Implementierungsbefund | Audit |
|---|---|---|
| 20,00 m fest | Controller setzt `referenceDistanceCm = 2000`; Recorder akzeptiert für Kalibrierung nur 2000 cm. | entspricht dem geprüften Produktmodell |
| 5 + 5 gültige Läufe | `skate_only` für 1–5, `puck_stickhandling` für 6–10; ungültige Läufe wiederholen dieselbe Vorgabe. | methodisch nachvollziehbar, nicht literaturvalidiert |
| Qualitätsgates | 2–30 s, positive Distanz/Pushes, 80–100 % Abdeckung, bekannte Zeitbasis, Verhältnis 0,50–1,50. | Produktgrenzen, keine Normwerte |
| robuste Konsistenz | Median, relative MAD ≤ 0,15, Bedingungsdifferenz ≤ 0,15. | sinnvolle Schutzregeln, Schwellen frei gewählt |
| Kadenz-Shadow | Kadenz und Referenzmeter je Ereignis werden gespeichert; Offline-Spearman/Theil-Sen je Bedingung. | kein Live-Einfluss zulässig |
| Oberflächentrennung | Versionierter lokaler Speicher hat getrennte `ice`-/`inline`-Slots; Training lädt nur die gewählte Oberfläche. | wissenschaftlich vorsichtig und fail-closed |
| Datenschutz/Architektur | Keine Positioning- oder Communications-Berechtigung; kein Watch-Uploadpfad. | kein GPS-Zwang, keine Cloud, kein globales Modell |

## Vorgeschriebene Testauswertung

### A. Referenz und Metadaten

- Strecke mit Maßband oder verlässlicher Hallenmarkierung als 20,00 m
  bestimmen; Messmethode und geschätzte Referenzunsicherheit protokollieren.
- Oberfläche, Halle/Eisfläche, Eis- beziehungsweise Bodenqualität, Rollen,
  Uhrenmodell, Firmware, App-Build, Detektorversion, Uhrenarm und Handschuh
  festhalten.
- Start-/Endmarker unabhängig per Video oder zweiter Person prüfen.
- Erkannte Anschübe nicht als Referenzanschübe wiederverwenden. Falls
  möglich, Skate-/Anschubereignisse im Video separat annotieren.
- Pausendauer und Laufreihenfolge speichern; subjektive Tempolabels nicht als
  gemessene Geschwindigkeitsklassen behandeln.

### B. Kalibrierläufe nur in-sample

Für alle zehn gültigen Läufe Rohwerte ausgeben:

- Basisschätzung, Referenzdistanz und Verhältnis `Referenz/Baseline`;
- erkannte und unabhängig annotierte Anschübe;
- Dauer, Kadenz, Abdeckung, Zeitbasis, Bedingung und Tempovorgabe;
- Bedingungsmedian, relative MAD und Unterschied der Bedingungsmediane.

Fehler nach Anwendung des aus denselben zehn Läufen gebildeten Faktors sind
**Trainingsfehler**. Sie dürfen nicht als Genauigkeitsnachweis bezeichnet
werden.

### C. Persönlicher Holdout

Nach Aktivierung neue, nicht zur Faktorbildung verwendete Läufe erfassen:

- je Oberfläche mindestens drei neue gerade 20-m-Läufe pro Bedingung;
- zusätzlich mindestens eine hockeyähnliche Sequenz mit Antritt, Gleitphase,
  Kurve, Stopp und Neustart;
- optional 30-m-Läufe, um den Transfer außerhalb der festen
  Kalibrierstrecke zu prüfen.

Baseline und persönliches Profil auf denselben Holdout-Läufen vergleichen:

- MAE in Metern;
- signierter Bias in Metern und Prozentpunkten;
- medianer absoluter Prozentfehler;
- Push-Zählfehler gegen unabhängige Annotation;
- Abdeckung, Ausschlussquote und Ausschlussgründe.

Bei einer einzelnen Person sind diese Ergebnisse persönlich-deskriptiv. Ein
allgemeiner Genauigkeitsclaim erfordert spielergruppierte Holdout-Daten mit
mindestens zwölf Skatern je Oberfläche und die bereits vorab definierten
Bootstrap- und Bias-Gates.

### D. Kadenzanalyse

- Alle fünf Rohpunkte je Bedingung zeigen, einschließlich Bindungen,
  Kadenzspanne und fehlender Werte.
- Keine p-Werte, Kausalitäts- oder Prognosebehauptung aus `n = 5`.
- Konstante oder nahezu konstante Kadenz als `nicht bestimmbar` behandeln.
- Spearman/Theil-Sen wegen der gemeinsamen Pushzahl ausdrücklich als
  algebraisch gekoppelt kennzeichnen.
- Einen späteren Kadenzterm nur gegen unabhängige räumliche Kriterien und in
  neuen Holdout-Daten prüfen. Video-/Skate-Ereignisse sind dafür geeigneter
  als der Wrist-Zähler selbst.
- Fehlende oder manipulierte Shadow-Kadenz darf Watch-, FIT- oder
  Garmin-Connect-Distanz nicht verändern; dies ist als Invarianztest zu
  prüfen.

### E. Eis-/Inline-Trennung

- Kalibrierung, Holdout und Berichte getrennt nach Oberfläche führen.
- Im Primärbericht nur das zur Oberfläche passende Profil anwenden.
- Das jeweils andere Profil höchstens offline als klar markierten
  Cross-Surface-Negativkontrollwert berechnen; niemals aktivieren.
- Nach Änderung von Detektor, Basismodell, Uhrenarm oder wesentlicher
  Ausrüstung Profilkompatibilität erneut prüfen beziehungsweise neu
  kalibrieren.

## Freie Produktparameter

Die folgenden Werte sind vorab definierte App-Entscheidungen und dürfen nicht
als aus Studien abgeleitete Normen dargestellt werden:

- 20 m Referenzstrecke;
- fünf plus fünf gültige Läufe;
- feste Tempoabfolge;
- 80 % Mindestabdeckung;
- Faktorbereich 0,50–1,50;
- relative MAD von höchstens 0,15;
- Bedingungsabweichung von höchstens 0,15;
- Half-up-Rundung auf vier Nachkommastellen.

## Schlussfolgerung

Beta 7 ist wissenschaftlich vertretbar, wenn die Funktion als
**experimentelle persönliche bekannte-Distanz-Korrektur eines geschätzten
Wrist-Modells** beschrieben wird. Die Implementierung trennt Eis und Inline,
aktiviert nicht automatisch und führt Kadenz nur als Shadow-Evidenz. Der
entscheidende nächste Nachweis ist nicht eine bessere Anpassung der zehn
Kalibrierläufe, sondern der Fehlervergleich auf neuen bekannten Strecken und
hockeyähnlichen Holdout-Sequenzen.

