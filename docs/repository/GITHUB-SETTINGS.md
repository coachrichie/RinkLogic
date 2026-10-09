# GitHub-Einstellungen für RinkLogic

## Zielzustand

- Repository: `coachrichie/RinkLogic`
- Sichtbarkeit: öffentlich, aber erst nach sämtlichen privaten Freigabegates
- Standardbranch: `main`
- Issues: aktiv
- Topics: `garmin`, `connect-iq`, `monkey-c`, `hockey`, `wearables`,
  `heart-rate`, `open-source`
- Änderungen an `main` ausschließlich per Pull Request
- Pflichtcheck: `python-tests`, strikt auf aktuellem `main`
- Konversationen vor Merge aufgelöst
- keine Force-Pushes und keine Löschung von `main`
- Private Vulnerability Reporting: aktiv und getestet

Die Sollkonfiguration der Branch Protection liegt in
`.github/main-branch-protection.json`.

## Bestätigter Ausgangszustand

Am 9. Oktober 2026 war `coachrichie/ShiftSense-Hockey-App` privat, `main` der
Standardbranch und GitHub Actions erfolgreich. Branch Protection war im
privaten Repository tarifbedingt nicht verfügbar; der Security-Advisory-Endpunkt
lieferte HTTP 404. Diese Funktionen werden erst nach der öffentlichen
Sichtbarkeitsänderung als aktiv dokumentiert, wenn GitHub sie bestätigt.

## Nachweis nach Veröffentlichung

Am 10. Oktober 2026 wurde der geprüfte, historienfreie Snapshot veröffentlicht:

- öffentliche URL: <https://github.com/coachrichie/RinkLogic>;
- initialer `main`-Commit: `7180a0b88cfe715cf535800fe02e6f7473dc8f66`;
- GitHub-Sichtbarkeit: `PUBLIC`;
- Standardbranch: `main`;
- erster GitHub-Actions-Lauf `Python tests`: erfolgreich;
- Pflichtcheck `python-tests`: strikt und aktuell;
- Änderungen über Pull Requests und aufgelöste Konversationen erforderlich;
- Force-Push und Branch-Löschung: deaktiviert;
- Private Vulnerability Reporting: aktiviert und per API zurückgelesen.

Ein frischer Clone über die öffentliche HTTPS-URL wurde mit deaktivierter
Git-Anmeldehilfe erstellt. Er erreichte den genannten Commit und bestand 32
Analysetests plus drei Subtests, 20 Repository-/Audit-Tests, Repository-Policy,
Release-Audit und REUSE 146/146.
