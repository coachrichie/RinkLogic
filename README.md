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

Der kontrollierte Remote-Testkandidat `0.2.0-beta.7` wurde für 69 signierte
Paketvarianten gebaut. Die Ring-1-Matrix enthält 50 freigegebene Produkt-IDs;
das bedeutet nicht, dass alle 50 Modelle physisch geprüft wurden. Automatisiert
bestanden 275/275 Venu-2-Plus-Tests sowie Responsive-Tests für Venu 2S,
Forerunner 255S, Instinct 3 AMOLED und fēnix 9 Pro 51 mm. Installation und
Rückgabe erfolgen ausschließlich privat nach der Beta-7-Testanleitung.

Automatische Shift-Vorschläge, Anschubzählung, Kadenz und geschätzte Distanz
sind experimentell. Sie sind keine Leistungs- oder Gesundheitsdiagnostik und
dürfen bei fehlender Messgrundlage nicht als `0` interpretiert werden.

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

## Referenzhardware

- Garmin Venu 2 Plus (`venu2plus`)
- Polar H10 als vorgesehener externer Sensor; die aktive Garmin-HR-Quelle wird
  von der App nicht als H10-verifiziert behauptet
- Connect IQ SDK 9.2.0

Für den kontrollierten Beta-7-Test sind nur die 50 in
`watch-v2/device-matrix.json` als `release-enabled` markierten Ring-1-IDs
zulässig. Ring 2 bleibt ausgeschlossen. Die Matrix ist eine Buildfreigabe, kein
Beleg für einen vollständigen Hardwaretest jedes Modells.

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

Für einen signierten Venu-2-Plus-Build müssen das aktive Connect IQ SDK und
`SHIFTSENSE_DEVELOPER_KEY` lokal konfiguriert sein. Der Schlüssel bleibt
außerhalb des Repositorys.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -UnitTest
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus
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
- [Beta-7-Remote-Kalibrierung](docs/testing/BETA7-REMOTE-CALIBRATION.md)
- [Beta-7-Geräteinstallation](docs/DEVICE-INSTALL-CHECKLIST.md)
- [FIT-Schema](docs/data/FIT-SCHEMA.md)

## Lizenzstatus

Software steht unter der Apache License 2.0. Originale Dokumentation und
projekt-eigene Medien stehen unter CC BY 4.0. Rechteinhaber ist Richard Dominik
Haimerl Schwarzwaldau. Die genaue Dateizuordnung, Attribution und Garmin-
Abgrenzung stehen in [`docs/LICENSING.md`](docs/LICENSING.md).
