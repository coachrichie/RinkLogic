# Changelog

Alle wesentlichen Änderungen an ShiftSense Hockey werden hier in kurzer Form
dokumentiert. Das detaillierte Entwicklungsjournal befindet sich in
[`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md).

## Unreleased

### Added

- Dreiseitige Post-Training-Zusammenfassung auf der Uhr nach erfolgreichem
  Speichern.
- Garmin-Connect-/FIT-Felder für Shiftanzahl, Eis- und Bankzeit,
  Shift-Dauern, HR-Zonen, Belastungs-/Pausenverhältnis und Shift-Dichte.
- Lap-Felder für Durchschnittspuls und HR-Abfall nach 30 beziehungsweise
  60 Sekunden auf der Bank.
- Lokale Kalibrierungs- und Pilotberichte für experimentelle Bewegungswerte.

### Changed

- Fehlende Sensor-Zeitstempel auf der Venu 2 Plus werden abgefangen; manuelle
  Shifts und HR-Aufzeichnung bleiben davon unabhängig.
- Anschub- und Distanzwerte kennzeichnen die geschätzte Zeitbasis und bleiben
  bei unzureichender Abdeckung unbekannt.

### Validation status

- 163 Connect-IQ-Simulatortests und ein signierter Venu-2-Plus-Build bestanden
  auf dem getesteten Beta-Stand.
- Die private Connect-IQ-Beta wurde auf einer Venu 2 Plus gestartet und
  speicherte Aktivitäten; Shift-Zähler, Herzfrequenz, Shift-Dauer,
  Durchschnittspuls pro Shift und alle drei Abschlussseiten wurden bestätigt.
- Garmin Connect Mobile zeigte die benutzerdefinierten Aktivitätsfelder. Die
  drei priorisierten Werte sind Anzahl Shifts, durchschnittliche Shift-Dauer
  und durchschnittliche Shift-Herzfrequenz.
- Ein exportiertes Schema-7-FIT bestand CRC- und Feldprüfung. Die nativen
  Garmin-Overview-Karten bleiben eine nicht durch Connect IQ konfigurierbare
  Plattformdarstellung.
