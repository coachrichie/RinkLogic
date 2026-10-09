# Initiale Repository-Freigabeprüfung

Datum: 9. Oktober 2026  
Geprüfter Quellstand: `4eabf3fc5a5961d3d91e81456489cf3d80ddfcb1`

Diese Prüfung wurde vor der Erstellung des privaten GitHub-Repositorys
ausgeführt. Sie belegt den lokalen Entwicklungsstand, nicht die spätere
Hardware- oder Garmin-Connect-Darstellung.

## Datenschutz und Historie

- Arbeitsbaum vor der Prüfung: sauber.
- Versionierte Dateien, die nach den aktuellen Ignore-Regeln ausgeschlossen
  wären: keine.
- Verbotene private oder generierte Pfade in der erreichbaren Historie: keine.
- Secret-Mustersuche: keine Token- oder Schlüsselwerte gefunden.
- Zwei Muster-Treffer in einem älteren Implementierungsplan wurden als
  wiederholte Zuweisung eines lokalen `.der`-Schlüsselpfads bewertet. Sie
  enthalten kein Schlüsselmaterial. Vor einer öffentlichen Freigabe bleibt
  die erneute Prüfung und gegebenenfalls Bereinigung absoluter lokaler Pfade
  verpflichtend.

Die Prüfung gibt keine gefundenen Werte, privaten Dateinamen oder absoluten
Benutzerpfade wieder.

## Automatisierte Tests

| Prüfung | Ergebnis |
| --- | --- |
| Python-Analyse | 31/31 bestanden |
| Repository-Policy | 6/6 bestanden |
| Venu-2-Plus-Simulator | 163/163 bestanden |

Der Connect-IQ-Testlauf endete mit `PASSED (passed=163, failed=0, errors=0)`.

## Signierter Gerätebuild

- Ziel: `venu2plus`
- Build: erfolgreich
- Größe: 406.844 Byte
- SHA-256: `779584297394367405FDF5CEE600D004ED12583638EF8E5B533568C71B903F9C`
- Ablage: ignorierter lokaler Buildpfad unter `watch-v2/bin/`

Der Entwickler-Schlüssel wurde nur lokal für den Buildprozess eingebunden und
weder kopiert noch versioniert.

## Noch offene Abnahme

Nicht durch diese Prüfung bestätigt sind:

- Installation dieses Builds auf der physischen Venu 2 Plus;
- Darstellung und Navigation der drei Post-Training-Seiten auf der Uhr;
- Synchronisation und Anzeige der benutzerdefinierten Felder in Garmin Connect
  Mobile und Web;
- Export und unabhängige Dekodierung eines neuen Schema-7-FIT;
- Genauigkeit experimenteller Anschub-, Distanz- und Auto-Shift-Werte.
