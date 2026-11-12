# Beta 7 – Gerätenachweis

Quelle der freigegebenen Produkt-IDs ist
`watch-v2/device-matrix.json`. Diese Seite dokumentiert Nachweisstufen und darf
nicht als pauschale Hardwarefreigabe gelesen werden.

## Nachweisstufen

- **compile-verified:** Das jeweilige Garmin-Geräteprofil baut mit SDK 9.2.0.
- **simulator-verified:** Automatisierte Tests liefen auf einem Repräsentanten
  der Display-/Eingabeklasse.
- **hardware-verified:** Der Ablauf wurde auf genau diesem physischen Modell
  einschließlich Speichern und Garmin-Connect-Synchronisierung beobachtet.

## Ring 1

**Kandidatenstatus:** Der korrigierte Export vom 7. November 2026 aus Commit
`7fef470` ist zur kontrollierten Remote-Abnahme freigegeben. Größe:
8.624.741 Byte; SHA-256
`4E6A62C40B0AE9FB978CB702CF82854A784A9E98CD79FFF662C7DCC7A90D40DF`.
Der Vorgängerhash `918F13E4…D6CB8` bleibt gesperrt.

Ring 1 umfasst 50 releasefähige Profile in den Klassen AMOLED klein/mittel/groß
und MIP klein/mittel/groß sowie Touch-/Zwei-Tasten- und Fünf-Tasten-Bedienung.
Der am 29. Oktober begonnene und am 5. November 2026 nach Unterbrechung
fortgesetzte Einzelbuild weist 50/50 vorhandene Ring-1-Artefakte und keinen
fehlenden Geräteordner aus.

Der signierte IQ-Export erweitert diese 50 logischen Produkt-IDs auf 69 Garmin-
Paketvarianten. Das Paket enthält exakt 69 passende PRGs sowie `manifest.sig2`
und `dev_key.pub`; diese Zahl ist daher kein Widerspruch zur Ring-1-Matrix.

Repräsentanten: `venu2s`, `venu2plus`, `venu3`, `venu445mm`, `fr255s`, `fr955`,
`fenix7x`, `fenix847mm`, `epix2pro51mm` und `instinct3amoled45mm`.

Vollständige Suites mit jeweils 266/266 bestanden auf `venu2s`, `venu2plus`,
`venu3`, `venu445mm`, `fr955`, `fenix7x`, `fenix847mm`, `epix2pro51mm` und
`instinct3amoled45mm`. Auf `fr255s` bestand der gezielte Responsive-Test; ein
erneuter Komplettlauf endete ohne fachlichen Fehler durch Abbruch des Garmin-
Simulatorprozesses und bleibt daher offen.

Die Venu 2 Plus ist das bisherige Hardware-Referenzgerät. Alle anderen Modelle
bleiben bis zu einem protokollierten realen Test höchstens compile- oder
simulator-verifiziert.

Nach dem UI-Fix bestanden 275/275 Tests auf `venu2plus` sowie gezielte
Responsive-Läufe auf `venu2s`, `fr255s`, `instinct3amoled45mm` und
`fenix9pro51mm` (466 px). Ready, Startmenü, Sportauswahl, Kalibrierungsintro und
Laufseite wurden zusätzlich visuell auf der simulierten Venu 2S geprüft. Dies
ist weiterhin kein Hardwareclaim.

## Ring 2

`venux1` und `instinct3solar45mm` sind bewusst zurückgestellt. Ihre rechteckige
beziehungsweise besondere MIP-Geometrie ist nicht Bestandteil des Beta-7-
Releasepakets.

## Bekannte Testgrenze

Ein Garmin-Simulatorabbruch ist kein bestandener Test. Wenn ein vollständiger
Testlauf auf einem kleinen Geräteprofil instabil ist, muss mindestens der
gezielte Responsive-Test plus erfolgreicher Einzelbuild dokumentiert werden;
die offene Vollsuite bleibt sichtbar und wird nicht als Hardwareproblem der App
umgedeutet.
