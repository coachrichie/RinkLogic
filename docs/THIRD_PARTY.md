# Drittanbieter, Werkzeuge und Assets

Diese Übersicht unterstützt Reproduzierbarkeit und eine spätere Lizenzprüfung.
Sie ist keine Open-Source-Lizenz für das Gesamtprojekt.

## Software und Plattformen

| Bestandteil | Verwendung | Version/Quelle | Lizenz- oder Nutzungsstatus |
| --- | --- | --- | --- |
| Garmin Connect IQ SDK und Toybox API | Kompilierung, Simulator und Geräte-API | SDK 9.2.0, Garmin Developer | Lokale Entwicklungsabhängigkeit; Garmin-Bedingungen gelten. SDK-Dateien werden nicht in diesem Repository redistribuiert. |
| `fitdecode` | Lokale FIT-Dekodierung in `analysis/` | `fitdecode==0.11.0`, PyPI/GitHub | MIT; externe Python-Abhängigkeit, deren Quellcode nicht in diesem Repository gebündelt wird. |
| Python | Analyse, Tests und Repository-Policy | Python 3.12 | Externe Laufzeit; nicht im Repository gebündelt. |
| GitHub Actions | Automatisierte Python-Prüfungen | GitHub-gehostete Runner | Dienstabhängigkeit; Workflow lädt keine privaten Schlüssel. |

## Bildressourcen

Folgende versionierte Dateien gehören zur Rechteprüfung vor einer öffentlichen
Veröffentlichung:

- `shared/branding/shiftsense-logo-master.png`
- `shared/branding/ice-ready-background-master.png`
- `shared/branding/favicon.png`
- `watch/resources/drawables/launcher_icon.png`
- `watch-v2/resources/drawables/launcher_icon.png`
- `watch-v2/resources/drawables/ready_background.png`
- `watch-v2/resources/drawables/ready_logo.png`

Richard Dominik Haimerl Schwarzwaldau hat die Urheberschaft beziehungsweise die
für eine Veröffentlichung erforderlichen Rechte an diesen Projektassets
bestätigt. Sie werden gemäß [`LICENSING.md`](LICENSING.md) unter CC BY 4.0
veröffentlicht. Garmin-Marken und Garmin-Programmmaterialien sind darin nicht
enthalten und werden nicht mitlizenziert.

## Pflege

Neue Abhängigkeiten oder fremde Assets werden hier im selben Pull Request mit
Version, Bezugsquelle, Zweck und Lizenzstatus ergänzt. Ungeklärte Bestandteile
blockieren eine öffentliche Freigabe, nicht jedoch die private lokale
Entwicklung.
