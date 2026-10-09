# Sicherheit und Datenschutz

## Unterstützter Stand

Sicherheitskorrekturen beziehen sich auf den aktuellen `main`-Branch. Frühere
Commits und lokal erzeugte PRG-Dateien gelten nicht als separat unterstützte
Versionen.

## Vertrauliche Meldung

Sicherheits- und Datenschutzbefunde werden nicht als öffentliches Issue
eingereicht. Verwende nach der öffentlichen Freigabe
[GitHub Private Vulnerability Reporting](https://github.com/coachrichie/RinkLogic/security/advisories/new).
Beschreibe Auswirkung, betroffene Version oder Commit, Reproduktion und eine
mögliche Begrenzung. Füge keine echten Schlüssel oder persönlichen FIT-, Log-
oder Trainingsdaten bei.

Der Kanal wird unmittelbar nach der Sichtbarkeitsänderung technisch geprüft.
Falls GitHub ihn als nicht verfügbar meldet, veröffentliche keine Ersatzmeldung.
Nutze einen bereits etablierten privaten Kontakt zum Maintainer oder bewahre
den Bericht lokal auf, bis der private GitHub-Kanal bestätigt ist.

## Was hierher gehört

- Offenlegung von Tokens, Entwickler-Schlüsseln oder privaten Trainingsdaten;
- unerlaubter Zugriff auf oder Export von personenbezogenen Daten;
- Manipulation von Aufzeichnung, FIT-Ausgabe oder Sicherheitsgrenzen;
- Abhängigkeitsschwachstellen mit konkreter Auswirkung auf dieses Projekt.

Normale Darstellungsfehler, Messabweichungen ohne Sicherheitsauswirkung und
Funktionswünsche gehören in die vorgesehenen Issue-Formulare.

## Lokale Geheimnisse

`SHIFTSENSE_DEVELOPER_KEY` verweist ausschließlich lokal auf den
Connect-IQ-Entwicklerschlüssel. Schlüssel, Tokens und `.env`-Dateien werden
weder in GitHub Actions noch im Repository gespeichert. Persönliche
Aktivitätsdaten bleiben unter ignorierten privaten Pfaden und werden nicht als
Test-Fixture verwendet.
