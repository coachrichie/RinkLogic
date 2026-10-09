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

Der Abschlussnachweis ergänzt öffentliche URL, `main`-SHA, Sichtbarkeit,
Branch-Protection-Antwort, privaten Sicherheitskanal und Ergebnis eines
unangemeldeten frischen Clones. Ungeprüfte Einstellungen werden nicht als aktiv
dargestellt.
