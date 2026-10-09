# Beitragen zu RinkLogic

RinkLogic verwendet kleine, überprüfbare Änderungen mit nachvollziehbaren
Tests. Beiträge müssen die Messgrenzen der App und den
Schutz persönlicher Trainingsdaten respektieren.

## Arbeitsablauf

1. Erstelle einen Branch im Muster `codex/kurzer-themenname` von aktuellem
   `main`.
2. Entwickle Verhaltensänderungen test-first und halte Commits fokussiert.
3. Verwende kurze Commit-Nachrichten wie `feat:`, `fix:`, `test:`, `docs:` oder
   `ci:` mit einer konkreten Beschreibung.
4. Öffne einen Pull Request und fülle die Prüf-, Datenschutz- und
   Hardwareabschnitte wahrheitsgemäß aus.
5. Merge erst nach erfolgreichen Pflichtchecks und aufgelösten Diskussionen.

## Developer Certificate of Origin

Jeder Commit muss mit `Signed-off-by` bestätigen, dass der Beitrag gemäß dem
[Developer Certificate of Origin 1.1](https://developercertificate.org/)
eingereicht werden darf:

```powershell
git commit -s -m "feat: kurze Beschreibung"
```

Codebeiträge werden unter Apache-2.0 bereitgestellt. Beiträge zu
Dokumentation und projekt-eigenen Medien werden gemäß der Zuordnung in
[`docs/LICENSING.md`](docs/LICENSING.md) unter CC BY 4.0 bereitgestellt
(inbound equals outbound).

## Pflichtprüfungen

Für jede Änderung:

```powershell
python -m unittest discover -s analysis/tests -p "test_*.py" -v
python -m unittest discover -s scripts/tests -p "test_*.py" -v
python scripts/repository_policy.py
python scripts/release_audit.py
python -m reuse lint
```

Vor einer Veröffentlichung zusätzlich Gitleaks 8.29.1 mit verifizierter
Prüfsumme installieren und die vollständige Git-Historie redigiert prüfen:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/install-gitleaks.ps1
.\.tools\gitleaks\gitleaks.exe git --redact --no-banner --config .gitleaks.toml
```

Bei Änderungen unter `watch-v2/` zusätzlich:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -UnitTest
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus
```

Der Pull Request nennt die tatsächlich ausgeführten Prüfungen. Simulator- und
Buildnachweise ersetzen keinen Gerätetest. Ein Hardwarebefund enthält Commit,
Gerät, Firmware, genaue Bedienfolge und beobachtetes Ergebnis, aber keine
private Rohdatei.

## Daten- und Geheimnisgrenzen

Nicht committen oder in Issues beziehungsweise Pull Requests einfügen:

- Garmin-Entwicklerschlüssel, Tokens, `.env`-Dateien oder Inhalte aus
  `.secrets/`;
- persönliche FIT-Dateien, Uhr-Logs oder Trainingsdaten;
- Dateien unter `analysis/private/`, `fixtures/private/` oder vergleichbaren
  privaten Pfaden;
- PRG-Dateien, Simulatorausgaben oder andere Inhalte aus `watch/bin/` und
  `watch-v2/bin/`;
- Screenshots mit Konten, Standorten oder personenbezogenen Aktivitätsdaten.

Wenn reale Daten für die Fehlersuche notwendig sind, beschreibe nur das
kleinste reproduzierbare Verhalten. Speichere Rohdaten lokal und teile sie
nicht über GitHub.

## Dokumentation und Messansprüche

Neue Metriken benötigen Definition, Einheiten, Fehlwertverhalten, Tests und
eine klare Validierungsgrenze. Formulierungen wie „validiert“, „genau“ oder
„H10-gemessen“ sind nur zulässig, wenn die verlinkte Evidenz genau diese Aussage
trägt. Unbekannte Messwerte bleiben unbekannt und werden nicht als Nullwert
dargestellt.

## Community-Regeln

Mit der Teilnahme gilt der [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).
Allgemeine Hilfe steht in [`SUPPORT.md`](SUPPORT.md); Sicherheits- und
Datenschutzmeldungen folgen ausschließlich [`SECURITY.md`](SECURITY.md).
