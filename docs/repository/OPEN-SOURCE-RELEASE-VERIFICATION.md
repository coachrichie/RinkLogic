# Open-Source-Verifikation für RinkLogic

Stand: 10. Oktober 2026

## Veröffentlichungsmodell

Das bisherige private Entwicklungsrepository enthält nicht veröffentlichbare
Legacy-Historie mit generierten Dateien und lokalen Arbeitspfaden. Es bleibt
privat. Das öffentliche Projekt `coachrichie/RinkLogic` wird deshalb als
geprüfter Snapshot mit neuer, sauberer Git-Historie veröffentlicht.

Der Snapshot enthält weder reale FIT-Aktivitäten noch persönliche
Gesundheitsdaten, Protokolle, Garmin-SDK-Material, Signierschlüssel oder
generierte PRG-/IQ-Dateien.

## Getesteter Produktstand

- Quellcommit der bestätigten Beta: `50c80b5`
- Connect-IQ-Beta: `0.1.0-beta.3` (interne Version 3)
- Manifest-App-ID: `4c7d5f9e-2b48-4f0d-a691-3b1c8e7f2a64`
- Garmin-Beta-Store-ID: `fdc96577-b809-4dca-88d4-8a2c1e753884`
- Exportiertes IQ-Paket: 212.156 Byte
- SHA-256 des exportierten IQ-Pakets:
  `DEFE1CBBF55899D516322F535E748685569A16DDDD1D03E8B9F4B8BB6F0640D0`
- Zielgerät: Garmin Venu 2 Plus
- SDK: Connect IQ 9.2.0

Das IQ-Paket und sämtliche Signierdaten bleiben außerhalb des öffentlichen
Repositorys.

## Automatisierte Nachweise

Auf dem Beta-Stand bestanden:

- 32 Python-Analysetests sowie drei Subtests;
- 20 Repository- und Release-Audit-Tests;
- Repository-Policy und REUSE-Prüfung;
- signierter Produktionsbuild;
- 163 von 163 Connect-IQ-Simulatortests.

Vor dem öffentlichen Push werden diese Prüfungen gegen den endgültigen
Snapshot erneut ausgeführt. Der alte Entwicklungsverlauf gilt aufgrund der
dokumentierten Historienfunde ausdrücklich nicht als veröffentlichungsfähig.

## Beobachtete Hardware- und Telefondaten

Der Projektinhaber bestätigte auf der Venu 2 Plus:

- erfolgreichen Start und Speicherung der Aktivität;
- Shift-Zählung;
- Live-Herzfrequenz und Shift-Dauer;
- durchschnittliche Herzfrequenz pro Shift;
- alle drei Post-Training-Abschlussseiten.

In Garmin Connect Mobile waren die benutzerdefinierten Connect-IQ-Daten im
zweiten Aktivitätsabschnitt sichtbar. Die ersten drei Werte sind Anzahl der
Shifts, durchschnittliche Shift-Dauer und durchschnittliche
Shift-Herzfrequenz.

Ein privater FIT-Export bestand die CRC-Prüfung und enthielt Schema 7, 30
Entwicklerfelddefinitionen sowie plausible Sessionwerte. Das reale FIT wurde
nicht in Git aufgenommen.

## Garmin-Plattformgrenze

Die native Garmin-Connect-Overview zeigte Standardkarten wie Distanz, Anstieg
und durchschnittliche Geschwindigkeit. Connect IQ stellt keine API bereit,
um diese nativen Karten mit Entwicklerfeldern zu ersetzen. RinkLogic ordnet
die drei wichtigsten Hockeywerte deshalb an den Anfang des separaten
Connect-IQ-Aktivitätsabschnitts. Eine Umdeutung von Distanz-, Höhen- oder
Geschwindigkeitsfeldern wurde bewusst ausgeschlossen.

Uhr-Firmware, Garmin-Connect-Mobile-Version und bereinigte Screenshots wurden
beim bestätigten Beta-Test nicht protokolliert. Diese fehlenden Metadaten
ändern nicht die beobachtete Funktionsprüfung, werden aber nicht als vorhanden
behauptet.

## Lizenz- und Rechteumfang

- Software: Apache-2.0
- Originale Dokumentation und projekt-eigene Medien: CC-BY-4.0
- Rechteinhaber: Richard Dominik Haimerl Schwarzwaldau

Garmin-Marken, Garmin-SDK-Komponenten und sonstige Garmin Program Materials
sind von diesen Lizenzen ausgeschlossen und werden nicht weitergegeben.

## Öffentliche GitHub-Prüfung

Nach dem Push werden öffentliche URL, `main`-SHA, Sichtbarkeit, unangemeldeter
Clone, GitHub Actions, Branch Protection und Private Vulnerability Reporting
mit den tatsächlich gelesenen GitHub-Antworten ergänzt oder in den
Release-Notizen dokumentiert.
