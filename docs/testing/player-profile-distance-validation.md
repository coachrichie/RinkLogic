# Validierung der profilbasierten Distanzschätzung

Stand: 2026-10-10. Dieses Protokoll prüft eine **experimentelle, geschätzte**
Distanz (`estimated_distance_cm`), keine direkt gemessene Strecke. Die
Implementierung allein belegt keine höhere Genauigkeit. Die separate
[20–30-m-Vorlage](20-30m-distance-evaluation.md) sammelt mindestens fünf
Wiederholungen je Bedingung für die Kalibrierungsprüfung einer Person. Deren
`profile_status: eligible` aktiviert kein populationsweites Höhenmodell.

## Modell und Freigabestatus

Der normale Release-Build verwendet `DistanceModelConfig.mode() == :fixed`:
Die ersten vier Anschübe eines Bursts erhalten je 125 cm, spätere
Rhythmusanschübe je 225 cm. Die Quelle lautet intern `:default`. Nur ein
gesonderter Validierungs-Build mit `:profile_height` prüft den Höhenansatz;
der interne Konfigurations-Einschub vor Aufnahmestart ist ausschließlich für
Tests und Validierung bestimmt. Es gibt keine Laufzeitwahl für Eis/Inline und
keine automatische Aktivierung aus einem persönlichen Kalibrierungsbericht.

Der experimentelle Test-Build wird ausdrücklich so erzeugt:

```powershell
.\scripts\watch-v2-build.ps1 -Device venu2plus -DistanceModel ProfileHeight
```

Er schreibt `watch-v2/bin/venu2plus/RinkLogic-profile-test.prg`. Ohne
`-DistanceModel ProfileHeight` entsteht weiterhin der feste Release-Build;
die beiden Artefakte dürfen beim Hardwaretest nicht verwechselt werden.

Für den persönlichen Beta-4-Test existiert zusätzlich der isolierte Modus
`CalibratedProfile`. Er berechnet zuerst dieselbe höhenbegrenzte Baseline und
rundet sie half-up auf ganze Zentimeter. Erst danach wird der lokale
persönliche Testfaktor `220/292,5` angewandt und erneut half-up gerundet. Damit
ergeben sich bei 80/180/250 cm 89/159, 94/169 beziehungsweise 100/180 cm.
Bei ungültiger Höhe wird exakt 125/225 cm als Baseline verwendet und erst dann
der persönliche Faktor angewandt. Der Faktor ist weder wissenschaftlicher
Populationskoeffizient noch automatisch aktivierte Nutzereinstellung.

```powershell
.\scripts\watch-v2-build.ps1 -Device venu2plus -DistanceModel CalibratedProfile
```

Dieser Build ergänzt ausdrücklich kein GPS, keinen Upload und kein globales
Modell oder Training. Gewicht und BMI bleiben ohne Einfluss. Eine spätere
Freigabe des Höhenmodells bleibt von den unten definierten, spielergruppierten
Held-out-Gates abhängig und wird durch den persönlichen Beta-Test nicht ersetzt.

Bei einer gültigen Garmin-Profilhöhe von einschließlich 80–250 cm gilt:

```text
rawFactor     = 1 + 0.5 * ((heightCm - 180) / 180)
factor        = clamp(0.94, 1.06, rawFactor)
startPushCm   = floor(125 * factor + 0.5)
rhythmPushCm  = floor(225 * factor + 0.5)
```

Das ist positive kaufmännische Rundung (half-up), getrennt für beide
Anschubarten, danach Addition in ganzen Zentimetern. An den gekappten
Grenzen verwendet die Implementierung die äquivalenten Brüche 47/50 und
53/50, damit ein exakter Halbschritt trotz Gleitkomma-Arithmetik aufwärts
rundet. Bei 180 cm bleiben 125/225 cm; bei 80 cm ergeben sich 118/212 cm,
bei 250 cm 133/239 cm. Fehlende, nicht numerische oder außerhalb 80–250 cm
liegende Höhen fallen auf 125/225 cm und `:default` zurück. Die Wahl wird
für die gesamte Aufnahme fixiert. `weight`/Gewicht und BMI haben **keinen**
Einfluss auf Meter pro Anschub; auch Alter, Geschlecht, HR, Können und
Kalibrierungswerte gehen nicht in diese Formel ein.

Die Quelle `:default` oder `:profile_height` ist nur Metadatum im Speicher,
kein Konfidenzwert und kein neues FIT-Feld. Für den Vergleich müssen
Build-Kennung, Modus, Oberflächenlabel, Referenzstrecke und die lokal
rekonstruierte beziehungsweise aus demselben Anschubablauf berechnete
`fixed`-Baseline eindeutig zusammenpassen. Die Oberfläche wird **außerhalb**
der App als `ice` oder `inline` erfasst; die App erhält keinen Sportarten-
Selektor.

## Erhebung und Trennung

1. Mindestens **12 skaters on ice** und **12 skaters on inline** erfassen.
   Falls dieselbe Person beide Oberflächen fährt, ihre gesamten Daten als
   eine Spielergruppe behandeln. Kleinere Stichproben bleiben explorativ.
2. Je Person und Oberfläche mindestens drei gerade, unabhängig vermessene
   20–30-m-Läufe und mindestens eine hockeyähnliche Folge aus Antritt,
   Gleiten, Kurve, Stopp und Wiederantritt aufzeichnen. Reihenfolge,
   Oberfläche, Bedingungen, Geräte-/Buildstand, Start-/Endmarken,
   Sensorabdeckung und, wenn möglich, unabhängige Anschubzählung notieren.
   Video oder zweite Person liefert die Referenz; die Uhrschätzung ist
   keine Referenzstrecke.
3. Nur Versuche mit gültigen Referenzmarken und zuordenbarer Schätzung in
   die primäre Genauigkeitsanalyse aufnehmen; fehlende Werte und
   Ausschlüsse mit Gründen und Zählungen berichten. Gerade Läufe und
   hockeyähnliche Folgen zusätzlich getrennt ausweisen.
4. Vor der Auswertung Spieler für eine unberührte Holdout-Gruppe reservieren
   oder gruppierte Kreuzvalidierung nach Spieler verwenden. **Niemals nur
   Sitzungen aufteilen:** Keine Daten einer Person dürfen gleichzeitig
   Modell-/Schwellenentwicklung und deren Held-out-Bewertung informieren.
   Schwellen, Ausschlussregeln und Berechnung vor Einsicht in die
   Held-out-Ergebnisse festlegen.
5. Für jede bewertete Strecke dieselben erkannten Anschübe und Kategorien
   unter beiden Modellen berechnen und als gepaartes Paar aus
   Referenzmetern, `fixed`-Schätzung und `profile_height`-Schätzung führen.
   Fehlt im Validierungs-Build eine gültige Höhe, den Rückfall als
   `:default` kennzeichnen und separat zählen. Die FIT-Datei enthält keine
   Modellquelle; sie wird nur in der lokalen Forschungstabelle zugeordnet.

## Auswertung und globale Aktivierung

Für Eis, Inline und alle Held-out-Beobachtungen zusammen jeweils die Anzahl
Spieler/Versuche, MAE (mittlerer absoluter Fehler in m), Median des
absoluten Prozentfehlers, signierten Bias in m und Prozent sowie die
Fehlerverteilung nach Antritts-/Rhythmusanteil berichten. Für jede Metrik
gelten dieselben gepaarten Referenzen. Prozentfehler ist
`100 * (Schätzung - Referenz) / Referenz`.

Die Unsicherheit des Unterschieds `MAE(fixed) - MAE(profile_height)` mit
einem **95-%-paired-bootstrap**-Intervall bestimmen: Spieler mit Zurücklegen
ziehen, alle zugehörigen gepaarten Beobachtungen (auch beide Oberflächen)
gemeinsam mitnehmen und die Metrik je Ziehung erneut berechnen. Resampling
auf Versuch- oder Sitzungsebene würde die Spielerabhängigkeit unterschätzen.
Für Eis, Inline und die kombinierte Auswertung jeweils **10.000** Replikate
mit NumPy `Generator(PCG64(20261010))` erzeugen. Das Intervall ist das
unadjustierte Perzentilintervall vom 2,5. bis 97,5. Perzentil der 10.000
replizierten MAE-Differenzen, berechnet mit `numpy.quantile(...,
method="linear")`; die Punktschätzung wird separat aus den ursprünglichen
Held-out-Daten berechnet. Im Ergebnisbericht müssen die Python- und
NumPy-Version sowie der Git-Commit des Analyseskripts (oder, falls es nicht
versioniert ist, dessen SHA-256-Prüfsumme) stehen. Diese Angaben und der
fixierte Seed sind vor dem Entsperren der Held-out-Ergebnisse festzuhalten.
Vorab definierte Höhendrittel innerhalb jeder Oberfläche getrennt zeigen;
diese kleinen Gruppen sind explorativ und kein zusätzliches Aktivierungstor.
Auffällige Schäden in einem Drittel erfordern eine gesonderte Prüfung.

Ein **einziger globaler** Wechsel des Release-Defaults ist nur zulässig,
wenn **Eis, Inline und die kombinierte Held-out-Auswertung jeweils alle**
folgenden Kriterien erfüllen:

- `MAE(profile_height)` liegt mindestens 5 % unter `MAE(fixed)`.
- Das 95-%-Intervall der gepaarten Spieler-Bootstrap-Differenz liegt
  vollständig über null und begünstigt damit `profile_height`.
- Der Betrag des signierten Bias verschlechtert sich gegenüber `fixed`
  um höchstens 1 m **und** höchstens 2 Prozentpunkte.

Diese Schwellen sind Produktentscheidungen, keine wissenschaftlich
abgeleiteten Genauigkeitsstandards. Ohne Laufzeit-Oberflächenwahl kann ein
Erfolg nur auf Eis oder nur auf Inline keinen Teil-Rollout begründen.
**Scheitert irgendein Gate, bleibt `DistanceModelConfig.mode()` bei
`:fixed`.** Auch ein bestandenes Gate ist eine Grundlage für eine separate
Release-Entscheidung und ersetzt keine Geräteprüfung.

## Datenschutz und Nachweisgrenze

FIT-Originale, Videos, Profilhöhen und personenbezogene Forschungstabellen
bleiben lokal unter `analysis/private/` oder in einem gleichwertig privaten
Speicher. Keine persönlichen Rohdaten oder abgeleiteten Spielerzeilen
committen. Es wird weder ein neues Garmin-Recht noch ein Netzwerkdienst
benötigt. In öffentlich versionierten Unterlagen stehen nur aggregierte,
nicht identifizierende Ergebnisse.

Simulator-Tests prüfen Rechenweg, Fallback, Sperre und Datenfluss; ein
erfolgreicher Build prüft die Kompilierung. Beides ist **kein Nachweis für
Distanzgenauigkeit** auf Eis oder Inline. Der Hardware-Rundlauf auf der
Venu 2 Plus und die oben definierte Populationserhebung stehen noch aus.

## Implementierungsprüfung vom 2026-10-10

- Connect IQ SDK **9.2.0**, Ziel **Venu 2 Plus** (`venu2plus`): vollständige
  Simulator-Suite in beiden Buildvarianten **174/174 bestanden,
  0 fehlgeschlagen, 0 Fehler**.
- Normaler App-Build für `venu2plus`: **BUILD SUCCESSFUL**, Exitcode 0.
- Der normale, eingecheckte Build gibt weiterhin `:fixed` zurück. Der
  Profilmodus ist nur im expliziten `ProfileHeight`-Testartefakt aktiv.
  Simulator-Erfolg belegt Implementierungsverhalten, **nicht**
  Distanzgenauigkeit. Hardwareprüfung und die Spielergruppen-Auswertung auf
  Eis, Inline und kombiniert bleiben offen.
