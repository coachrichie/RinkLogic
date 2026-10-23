# Beta 6: Evidenz- und Risikoaudit der persönlichen Distanzkalibrierung

Stand: 23. Oktober 2026

## Urteil

Der Beta-6-Ansatz ist als **lokale, experimentelle bekannte-Distanz-Korrektur** wissenschaftlich konsistent, sofern er nicht als biologisches Schrittlängenmodell oder Genauigkeitsnachweis bezeichnet wird. Der Median aus zehn Verhältnissen `Referenzdistanz / unkalibrierte Basisschätzung` ist eine robuste Produktentscheidung gegen einzelne Ausreißer. Die Grenzen `0,50–1,50`, die relative MAD von höchstens 15 Prozent, die höchstens 15-prozentige Abweichung der Bedingungsmediane und die Mindestabdeckung von 80 Prozent sind Sicherheits- und Qualitätsregeln der App, keine aus Studien abgeleiteten Universalgrenzen.

Die bestehende Literatur stützt, dass Skating räumlich-zeitlich mit unabhängigen Referenzsystemen untersucht werden kann. Sie validiert jedoch weder Garmin-Handgelenkereignisse noch die Beta-6-Konstanten oder einen persönlichen Multiplikator:

- `hockey-skating-khandan-2022`: Skate-, Schienbein- und Becken-IMUs gegen Motion Capture und Drucksohlen auf 14 m synthetischem Eis; kein Handgelenk und kein Distanzfaktor pro erkanntem Uhrenereignis.
- `bandy-pojskic-2025`: indirekte Zusammenhänge zwischen Beinlänge und Glide-/Step-Maßen; Konferenzabstract, keine individuelle Umrechnungsformel.
- `bandy-vanden-tillaar-2025`: Glide-/Step-Längen hängen mit Geschwindigkeit zusammen; keine persönliche Anthropometriegleichung.
- `inline-speed-wu-2025`: heterogene, begrenzte Inline-Speed-Skating-Biomechanik; keine Inline-Hockey- oder Garmin-Validierung.
- `hockey-allisse-2023`: breite Übersicht von On-Ice-Tests; kein Modell von Körpergröße/Gewicht zu Metern pro Handgelenkereignis.

Die höhenbegrenzte Baseline bleibt deshalb ein evidenzbegrenzter App-Prior. Gewicht und BMI verändern die Distanz nicht. Eis und Inline erhalten getrennte Profile und getrennte Auswertungen.

## Zulässige Interpretation

Der persönliche Faktor kann lokale, systematische Abweichungen zwischen Basisschätzung und bekannter Strecke reduzieren. Er kann nicht bestimmen, ob die Abweichung durch falsche Ereigniszahl, falsche Meter je Ereignis, Stickhandling, Kurven, Gleitanteile, Markerfehler oder Sensorlücken entstand. Der Faktor korrigiert diese Ursachen gemeinsam und darf nicht als physiologische oder biomechanische Eigenschaft des Spielers bezeichnet werden.

`Referenzdistanz / erkannte Anschübe` ist im Beta-6-Bericht ausschließlich **Referenzmeter je erkanntem Uhrenereignis**. Der kurze Name „effektive Schrittlänge“ ist operativ, aber nicht gleichbedeutend mit Skate-Step-Length, Glide-Length oder Same-Skate-Stride-Length aus biomechanischen Studien.

Eine unabhängige Push-Zählung bewertet getrennt:

```text
Zählfehler = erkannte Uhrenereignisse − unabhängig annotierte Anschübe
```

Sie darf weder durch die Uhrdistanz ersetzt noch nachträglich so angepasst werden, dass der Distanzfehler kleiner wird.

## Risiken und vorgeschriebene Begrenzungen

1. **Resubstitutionsfehler:** Der Faktor wird aus denselben zehn Läufen bestimmt, auf denen er rechnerisch gut aussieht. Fehler nach Multiplikation auf diesen Läufen sind Trainingsfehler und kein Genauigkeitsnachweis. Eine Genauigkeitsaussage benötigt neue, nicht zur Faktorbildung verwendete bekannte-Distanz-Läufe.
2. **Geteilte Messgröße:** Kadenz ist `erkannte Anschübe / Zeit`; Referenzmeter je erkanntem Ereignis sind `Referenzdistanz / erkannte Anschübe`. Der erkannte Anschubzähler steht einmal im Zähler und einmal im Nenner. Eine negative Spearman-Korrelation oder Theil-Sen-Steigung kann dadurch algebraisch entstehen, selbst ohne echte biomechanische Kadenzwirkung.
3. **Sehr kleine Teilstichprobe:** Spearman und Theil-Sen beruhen je Bedingung auf fünf Läufen einer Person. Sie sind nur deskriptiv; keine p-Werte, Konfidenz-, Kausalitäts-, Prognose- oder Aktivierungsbehauptung.
4. **Subjektive Geschwindigkeit:** `slow/fast/normal` sind Instruktionen, keine gemessenen Geschwindigkeitsklassen. Primär analysiert werden Laufdauer und erkannte Kadenz; die Tempolabels dienen nur der Protokollkontrolle.
5. **Feste Reihenfolge:** `slow/fast/normal/slow/fast` verbessert die Wiederholbarkeit, vermischt Geschwindigkeit aber mit Reihenfolge, Lernen und Ermüdung. Aus den ersten zehn Läufen wird kein Pace-Effekt geschätzt.
6. **Stickhandling:** Stock- und Armbewegung kann den Handgelenkdetektor verändern. Die beiden Bedingungen bleiben getrennt; Übereinstimmung der Mediane ist nur ein Konsistenzgate, keine Validierung.
7. **Oberflächen- und Sitzungstransfer:** Ein Faktor gilt nur für den getesteten Spieler, Uhrenarm, Oberfläche, Detektor-/Buildstand und die beobachtete Ausführung. Eis und Inline werden nicht gepoolt und ein Faktor wird nicht zwischen ihnen kopiert.
8. **Sicherheitsgrenzen:** `0,50–1,50`, 80 Prozent Abdeckung und 15-Prozent-Gates sind vorab definierte Produktgrenzen. Sie dürfen nicht als sportwissenschaftliche Normwerte veröffentlicht werden.
9. **Aktivierung:** Ein auf der Uhr als `eligible` bezeichneter Kandidat ist technisch konsistent, nicht wissenschaftlich validiert. Aktivierung bleibt explizit, lokal und reversibel. Keine automatische Aktivierung und kein globales Modelltraining.
10. **Datenschutz:** Original-FIT, Formular, Video und Spielerzeilen bleiben privat. Öffentliche Berichte enthalten nur aggregierte, nicht identifizierende Ergebnisse.

## Kriterien für die ersten Tester-FITs

### A. Identität und Integrität

- Original-FIT unverändert; SHA-256, Eingangszeit und private Speicherposition protokollieren.
- CRC gültig; FIT-Schema 12; App-Version, Build-Commit, Modellkennung und Gerät stimmen mit Release-Manifest überein.
- Sitzungsstart im Referenzformular stimmt zeitzonengenau mit der FIT überein.
- Oberfläche und Referenzdistanz sind eindeutig; Strecke ist unabhängig mit Maßband oder verlässlicher Hallenmarkierung als 20, 22, 25 oder 30 m bestimmt.
- Kalibrierungs-FIT und normales Training nicht verwechseln.

### B. Zehn gültige Läufe

- Genau zehn akzeptierte Referenz-Laps in der Reihenfolge:
  `skate_only: slow, fast, normal, slow, fast`, danach
  `puck_stickhandling: slow, fast, normal, slow, fast`.
- Jeder akzeptierte Lauf erfüllt unabhängig erneut:
  Dauer 2–30 s; Basisschätzung > 0; erkannte Anschübe > 0; Abdeckung 80–100 Prozent; bekannte Zeitbasis; Verhältnis `Referenz/Baseline` 0,50–1,50; vollständige Start-/Endmarker.
- Verworfene Versuche, Wiederholungsgrund und erneute Tempovorgabe werden gezählt. Sie fließen nicht in die zehn Faktoren ein.
- Keine fehlenden, doppelten oder vertauschten Laps; keine stillschweigende Imputation.

### C. Faktor unabhängig nachrechnen

Für jeden Lauf:

```text
r_i = Referenzdistanz / unkalibrierte Basisschätzung
```

Dann getrennt für beide Bedingungen Median und relative MAD berechnen. Beide relativen MAD-Werte müssen höchstens 0,15 sein. Die absolute Differenz der Bedingungsmediane, geteilt durch deren Mittelpunkt, muss höchstens 0,15 sein. Der Kandidat ist der positive Half-up auf vier Nachkommastellen gerundete Median aller zehn `r_i` und muss in `0,50–1,50` liegen.

- Offline-Neuberechnung und Uhrkandidat müssen bis auf Float32-/Vierstellen-Toleranz übereinstimmen.
- Sessionfeld 115, aktivierte lokale Profilkopie, Oberfläche und angezeigter Faktor müssen übereinstimmen. Abweichungen quarantänisieren die Datei.
- Vor ausdrücklicher Aktivierung darf ein normales Training die Baseline nicht verändern; nach Aktivierung muss nur das passende Oberflächenprofil wirken. Deaktivierung, beschädigtes Profil oder Oberflächenwechsel müssen auf die Baseline zurückfallen.

### D. Anschub- und Kadenzanalyse

- Bei unabhängiger Push-Annotation je Lauf erkannten Wert, Referenzwert, signierten Zählfehler und absoluten Zählfehler berichten.
- Referenzmeter je erkanntem Ereignis nur bei `erkannte Anschübe > 0` berechnen und ausdrücklich nicht als anatomische Schrittlänge benennen.
- Spearman und Theil-Sen getrennt nach Bedingung aus genau den fünf gültigen Punkten berichten, zusammen mit allen fünf Rohpunkten, Kadenzspanne, Bindungen und fehlenden Werten.
- Degenerierte Daten ohne Kadenz- oder Ergebnisvariation ergeben `nicht bestimmbar`, niemals null.
- Korrelation und Steigung bleiben Shadow-Evidenz und verändern weder Faktor noch Record-, Lap- oder Session-Distanz.

### E. Genauigkeitsprüfung außerhalb der Kalibrierläufe

- Baseline- und Faktorfehler der zehn Kalibrierläufe als **in-sample/deskriptiv** kennzeichnen.
- Danach pro Oberfläche und Bedingung neue bekannte-Distanz-Läufe erfassen, die nicht in den Median eingingen. Erst diese bewerten persönliche Übertragbarkeit.
- Auf Hold-out-Läufen mindestens MAE, signierten Bias, medianen absoluten Prozentfehler, Push-Zählfehler, Ausschlussquote und Abdeckung berichten.
- Gerade bekannte Strecken und hockeyähnliche Folgen separat ausweisen. Eine hockeyähnliche Folge ohne unabhängige Distanz ist nur Robustheits-/Fehlerdiagnostik.
- Mehrnutzerergebnisse nach Spielern gruppieren; keine Läufe derselben Person zugleich zur Schwellenentwicklung und formalen Hold-out-Bewertung verwenden.

## Werkzeugvertrag und verbleibende Grenze

Die Offline-Auswertung rekonstruiert nun den Beta-6-Kandidaten aus dem Median
der zehn gültigen Baseline-Verhältnisse; der historische Testfaktor wurde
entfernt. Für Schema 12 prüft sie erneut Laufdauer 2–30 s, Abdeckung 80–100
Prozent, positive Anschubzahl und Basisschätzung sowie das Verhältnis
0,50–1,50. Bedingungsmediane, relative MAD und Bedingungsdifferenz entscheiden
wie auf der Uhr über die technische Konsistenz.

Zusätzlich verlangt sie genau eine Oberfläche und eine gemeinsame erlaubte
Referenzdistanz von 20, 22, 25 oder 30 m je Sitzung. FIT-Feld 115,
Formularfaktor und offline rekonstruierter Kandidat müssen vollständig
vorhanden und innerhalb der Toleranz identisch sein; fehlende oder abweichende
Faktoridentität setzt den Bericht auf `inconsistent` und damit Quarantäne.

Der Formularvertrag ist eindeutig: Jede tatsächlich gespeicherte technische
FIT-Lap erhält genau eine Zeile in derselben Reihenfolge; darunter müssen exakt
zehn Zeilen `valid` sein. Verworfene Versuche bleiben als nicht gültige Zeilen
erhalten, wenn sie im FIT als Lap vorkommen.

Die Zeitbasis wird in Schema 12 wegen des ausgeschöpften Feldbudgets nicht pro
Lap exportiert. Der Offline-Bericht kennzeichnet sie deshalb als
`not_exported_in_schema_12`; dieses einzelne Runtime-Gate ist aus dem FIT nicht
unabhängig rekonstruierbar und bleibt ein dokumentierter Vorbehalt.

Ein `eligible`-Status bedeutet weiterhin nur technische Protokollkonsistenz.
Er belegt weder Genauigkeit noch Übertragbarkeit oder Produktionsreife. Erste
Testerberichte bleiben bis zu unabhängigen Hold-out-Läufen **nicht validiert**.
