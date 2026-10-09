# Open-Source-Freigabe von RinkLogic

Die Reihenfolge dieser Checkliste ist verbindlich. Eine spätere Stufe ersetzt
keinen offenen Nachweis einer früheren Stufe.

## 1. Privater Release-Kandidat

- [ ] Apache-2.0, CC-BY-4.0, NOTICE und REUSE-Zuordnung sind vollständig.
- [ ] Beiträge, Abhängigkeiten und Asset-Rechte sind geklärt.
- [ ] Garmin SDK, Program Materials, Schlüssel und generierte Dateien sind
      nicht versioniert.
- [ ] Aktueller Baum und vollständige Git-Historie bestehen Policy- und
      Secret-Audit mit `release_audit.py` und Gitleaks 8.29.1.
- [ ] Python-, Repository- und Connect-IQ-Simulatortests bestehen.
- [ ] Signierter Build, Größe und SHA-256 sind dokumentiert.

## 2. Physische Produktabnahme

- [ ] Installation, Start, Shifts, Speichern und drei Zusammenfassungsseiten
      bestehen auf der Zieluhr.
- [ ] Garmin Connect Mobile zeigt die unterstützten Summary- und Lap-Felder.
- [ ] Exportiertes FIT besteht CRC-, Schema-, Einheiten- und Wertevergleich.
- [ ] Fehlende Herzfrequenzdaten bleiben unbekannt und werden nicht zu null.

## 3. Review und Merge im privaten Repository

- [ ] Fresh Review meldet keine offenen kritischen oder wichtigen Befunde.
- [ ] Pull Request ist auf dem exakten Kandidatencommit grün.
- [ ] Geprüfter Pull Request ist nach `main` gemergt.

## 4. Sichtbarkeitsänderung

- [ ] GitHub-Name, Beschreibung und Topics nennen RinkLogic.
- [ ] Repository wurde bewusst von privat auf öffentlich gestellt.
- [ ] GitHub bestätigt anschließend `visibility: public`.

## 5. Prüfung aus öffentlicher Sicht

- [ ] Ein nicht angemeldeter, frischer Clone erreicht denselben `main`-Commit.
- [ ] Tests, Policy, Audit und REUSE-Lint bestehen im frischen Clone.
- [ ] README-, Lizenz-, Beitrags-, Support- und Sicherheitslinks funktionieren.
- [ ] Branch Protection und Pflichtcheck `python-tests` sind aktiv und gelesen.
- [ ] Private Vulnerability Reporting ist aktiviert und der Meldeweg geprüft.

Findet die Historienprüfung nicht veröffentlichbare Daten, bleibt dieses
Repository privat. Dann ist ein separat geprüfter sauberer Snapshot der einzige
zulässige Veröffentlichungsweg.
