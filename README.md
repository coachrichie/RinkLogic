# RinkLogic

RinkLogic ist eine Open-Source-App für Garmin Connect IQ zur Analyse von Eis-
und Inlinehockey. Die App zeichnet eine Garmin-Aktivität auf, zeigt während des
Trainings Herzfrequenz und manuell markierte Shifts und berechnet nach dem
Speichern hockeybezogene Belastungswerte.

Das Projekt ist unabhängig und weder mit Garmin verbunden noch von Garmin
unterstützt. Die Garmin-App behält in dieser ersten öffentlichen Version ihre
bestehenden internen Kennungen und Buildnamen, damit installierte Teststände
kompatibel bleiben.

## Projektstatus

Die aktuelle Beta 7 erweitert die bisher auf einer Garmin Venu 2 Plus
hardwaregeprüfte V2 auf eine maschinenlesbare Ring-1-Matrix mit 50 Garmin-
Modellen. Diese Modelle werden einzeln kompiliert; ausgewählte Display- und
Bedienklassen werden zusätzlich im Simulator geprüft. Nur die Venu 2 Plus gilt
bislang als hardwareverifiziert.
Schichtzählung, Herzfrequenz, Shift-Dauer, Durchschnittspuls pro Shift, alle
drei Abschlussseiten und die benutzerdefinierten Aktivitätsfelder wurden auf
Uhr beziehungsweise in Garmin Connect Mobile beobachtet.

Automatische Shift-Vorschläge, Anschubzählung, Kadenz und geschätzte Distanz
sind experimentell. Sie sind keine Leistungs- oder Gesundheitsdiagnostik und
dürfen bei fehlender Messgrundlage nicht als `0` interpretiert werden.

Beta 7 ergänzt eine geführte persönliche Kalibrierung für Eis- und
Inlinehockey. Beide Sportprofile werden getrennt gespeichert. Das Protokoll
verwendet eine gemessene Strecke von genau 20 m sowie je fünf gültige Läufe
ohne und mit Stickhandling. Ohne gültiges Profil bleibt das wissenschaftliche
Basismodell aktiv. Es gibt weder Cloud-Upload noch GPS-Zwang oder globales
Nutzermodell; Testpersonen übermitteln FIT-Dateien vorerst manuell.

## Aktuelle Funktionen

Unmittelbar nach erfolgreichem Speichern zeigt die Uhr drei Seiten mit:

- Trainingsdauer, Durchschnitts- und Maximalpuls;
- Anzahl der Shifts, Eiszeit und Bankzeit;
- durchschnittlichem und längstem Shift sowie Durchschnittspuls pro Shift.

Die V2 schreibt folgende benutzerdefinierte Daten in die FIT-Aktivität:

- Anzahl der Shifts, Eiszeit, Bankzeit und durchschnittliche Shift-Dauer;
- durchschnittliche Herzfrequenz pro Shift;
- Zeit in den Herzfrequenzzonen 1 bis 5 und Zeit über 90 Prozent HFmax;
- Work-to-Rest-Verhältnis und Shift-Dichte;
- kürzesten, längsten und Median-Shift;
- pro Shift: Durchschnittspuls sowie Herzfrequenzabfall nach 30 und 60 Sekunden;
- experimentelle Anschub-, Distanz- und Sensorabdeckungswerte, soweit valide.

Die drei intensivsten auswertbaren Shifts werden intern nach
Durchschnittspuls geordnet. Sie haben derzeit keine eigenen Garmin-Connect-
Übersichtsfelder. Garmin Connect zeigt benutzerdefinierte Connect-IQ-Felder in
einem eigenen Aktivitätsabschnitt; die nativen Overview-Karten werden von
Garmin anhand des Aktivitätstyps ausgewählt und können von der App nicht durch
Shift-Werte ersetzt werden.

## Geräteunterstützung

- Hardwareverifiziert: Garmin Venu 2 Plus (`venu2plus`)
- Ring 1: 50 freigegebene Geräteprofile; exakter Status in
  [`docs/testing/BETA7-DEVICE-MATRIX.md`](docs/testing/BETA7-DEVICE-MATRIX.md)
- Ring 2: Venu X1 und Instinct 3 Solar vorerst zurückgestellt
- Polar H10 als vorgesehener externer Sensor; die aktive Garmin-HR-Quelle wird
  von der App nicht als H10-verifiziert behauptet
- Connect IQ SDK 9.2.0

Compile- oder Simulatorprüfung ersetzt keinen Hardwaretest. Die
Gerätematrix weist diese Nachweisstufen deshalb getrennt aus.

## Projektstruktur

| Pfad | Verantwortung |
| --- | --- |
| `watch-v2/` | Aktuelle V2-App, Ressourcen und Monkey-C-Tests |
| `watch/` | Frühere V1-Implementierung und Regressionstests |
| `analysis/` | Lokale FIT-Auswertung und Kalibrierungsberichte |
| `scripts/` | Reproduzierbare Build- und Repository-Prüfungen |
| `shared/` | Gemeinsames FIT-Schema und geprüfte Markenressourcen |
| `docs/` | Architektur, Evidenz, Entwicklung und Hardwareprotokolle |

## Lokaler Quickstart

Python 3.12 einrichten und die lokale Analyse prüfen:

```powershell
python -m pip install -r analysis/requirements.txt
python -m unittest discover -s analysis/tests -p "test_*.py" -v
python -m unittest discover -s scripts/tests -p "test_*.py" -v
python scripts/repository_policy.py
```

Für einen signierten Einzel- oder Matrix-Build müssen das aktive Connect IQ SDK und
`SHIFTSENSE_DEVELOPER_KEY` lokal konfiguriert sein. Der Schlüssel bleibt
außerhalb des Repositorys.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -UnitTest
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-matrix-build.ps1 -Ring Ring1 -BuildOnly
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -DistanceModel PersonalCalibrationBeta -ExportPackage
```

Buildausgaben unter `watch-v2/bin/` werden nicht versioniert.

## Datenschutz

Persönliche FIT-Dateien, Uhr-Logs, Trainingsdaten, Schlüssel und lokale
Auswertungen gehören nicht in Git. Die Repository-Policy blockiert bekannte
private und generierte Pfade. Beispiele müssen synthetisch oder nachweislich
anonymisiert sein. Details stehen in [`SECURITY.md`](SECURITY.md) und
[`CONTRIBUTING.md`](CONTRIBUTING.md).

## Community

- [Beiträge](CONTRIBUTING.md)
- [Support](SUPPORT.md)
- [Governance](GOVERNANCE.md)
- [Verhaltenskodex](CODE_OF_CONDUCT.md)
- [Vertrauliche Sicherheitsmeldung](SECURITY.md)

## Dokumentation

- [Architektur](ARCHITECTURE.md)
- [Beitragen und testen](CONTRIBUTING.md)
- [Sicherheit und Datenschutz melden](SECURITY.md)
- [Änderungsverlauf](CHANGELOG.md)
- [Open-Source-Bereitschaft](docs/OPEN_SOURCE_READINESS.md)
- [Drittanbieter und Assets](docs/THIRD_PARTY.md)
- [Projektlandkarte](docs/PROJECT-MAP.md)
- [Entwicklungsjournal](docs/DEVELOPMENT.md)
- [Post-Training-Hardwaretest](docs/testing/V2-POST-TRAINING-SUMMARY.md)
- [FIT-Schema](docs/data/FIT-SCHEMA.md)
- [Beta-7-Gerätematrix](docs/testing/BETA7-DEVICE-MATRIX.md)
- [Beta-7-Remote-Kalibrierung](docs/testing/BETA7-REMOTE-CALIBRATION.md)

## Lizenzstatus

Software steht unter der Apache License 2.0. Originale Dokumentation und
projekt-eigene Medien stehen unter CC BY 4.0. Rechteinhaber ist Richard Dominik
Haimerl Schwarzwaldau. Die genaue Dateizuordnung, Attribution und Garmin-
Abgrenzung stehen in [`docs/LICENSING.md`](docs/LICENSING.md).
