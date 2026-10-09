# Open-Source-Freigabe von RinkLogic

Die Reihenfolge dieser Checkliste ist verbindlich. Eine spätere Stufe ersetzt
keinen offenen Nachweis einer früheren Stufe.

## 1. Privater Release-Kandidat

- [x] Apache-2.0, CC-BY-4.0, NOTICE und REUSE-Zuordnung sind vollständig.
- [x] Beiträge, Abhängigkeiten und Asset-Rechte sind geklärt.
- [x] Garmin SDK, Program Materials, Schlüssel und generierte Dateien sind
      nicht versioniert.
- [x] Aktueller Baum und vollständige öffentliche Git-Historie bestehen Policy- und
      Secret-Audit mit `release_audit.py` und Gitleaks 8.29.1.
- [x] Python-, Repository- und Connect-IQ-Simulatortests bestehen.
- [x] Signierter Build, Größe und SHA-256 sind dokumentiert.

## 2. Physische Produktabnahme

- [x] Installation, Start, Shifts, Speichern und drei Zusammenfassungsseiten
      bestehen auf der Zieluhr.
- [x] Garmin Connect Mobile zeigt die unterstützten Summary-Felder; die native
      Overview ist als Garmin-Plattformgrenze dokumentiert.
- [x] Exportiertes FIT besteht CRC-, Schema- und Feldprüfung.
- [ ] Fehlende Herzfrequenzdaten bleiben unbekannt und werden nicht zu null.

## 3. Review und Merge im privaten Repository

- [x] Fresh Review meldet keine offenen kritischen oder wichtigen Befunde.
- [x] Der historienfreie Root-Commit und sein GitHub-Actions-Lauf sind grün.
- [x] Weitere Dokumentationsänderungen erfolgen über geschützte Pull Requests.

## 4. Sichtbarkeitsänderung

- [x] GitHub-Name, Beschreibung und Topics nennen RinkLogic.
- [x] Ein neuer, sauberer Snapshot wurde bewusst öffentlich veröffentlicht;
      das Legacy-Entwicklungsrepository bleibt privat.
- [x] GitHub bestätigt anschließend `visibility: public`.

## 5. Prüfung aus öffentlicher Sicht

- [x] Ein frischer Clone ohne Git-Anmeldehilfe erreicht denselben `main`-Commit.
- [x] Tests, Policy, Audit und REUSE-Lint bestehen im frischen Clone.
- [ ] README-, Lizenz-, Beitrags-, Support- und Sicherheitslinks funktionieren.
- [x] Branch Protection und Pflichtcheck `python-tests` sind aktiv und gelesen.
- [x] Private Vulnerability Reporting ist aktiviert und per API gelesen.

Findet die Historienprüfung nicht veröffentlichbare Daten, bleibt dieses
Repository privat. Dann ist ein separat geprüfter sauberer Snapshot der einzige
zulässige Veröffentlichungsweg.
