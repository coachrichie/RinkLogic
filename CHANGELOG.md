# Changelog

Alle wesentlichen Änderungen an ShiftSense Hockey werden hier in kurzer Form
dokumentiert. Das detaillierte Entwicklungsjournal befindet sich in
[`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md).

## Unreleased

### Added

- Isolierter `0.2.0-beta.4`-Build mit evidenzbegrenzter Höhenbaseline und dem
  lokalen persönlichen Testfaktor `220/292,5`; kein GPS, Upload oder globales
  Modell.
- FIT-Schema 9 mit Float-Minutenfeldern 101–109 für Eis-/Bankzeit, HF-Zonen,
  Zeit über 90 % HFmax und Median-Shift.

- Dreiseitige Post-Training-Zusammenfassung auf der Uhr nach erfolgreichem
  Speichern.
- Garmin-Connect-/FIT-Felder für Shiftanzahl, Eis- und Bankzeit,
  Shift-Dauern, HR-Zonen, Belastungs-/Pausenverhältnis und Shift-Dichte.
- Lap-Felder für Durchschnittspuls und HR-Abfall nach 30 beziehungsweise
  60 Sekunden auf der Bank.
- Lokale Kalibrierungs- und Pilotberichte für experimentelle Bewegungswerte.
- Experimentelle, höhenabhängige Variante der geschätzten Anschubdistanz mit
  begrenztem Faktor, festem Rückfall und internem Quellenmerkmal. Der normale
  Release-Build verwendet weiter `:fixed`; `:profile_height` ist für
  Validierungs-Builds vorgesehen. Gewicht/BMI verändern die Distanz nicht.
  Das populationsweite Aktivierungstor steht in
  [`docs/testing/player-profile-distance-validation.md`](docs/testing/player-profile-distance-validation.md).

### Changed

- Alle von RinkLogic dargestellten Zeitwerte auf der Uhr verwenden
  Dezimalminuten; Gesamt-/Eis-/Bankzeit mit einer und Shiftzeiten mit zwei
  Nachkommastellen.
- Der lokale Parser liest Schema 4–9, konvertiert historische Sekunden genau
  einmal und behält rohe FIT-Werte für Audits.

- Fehlende Sensor-Zeitstempel auf der Venu 2 Plus werden abgefangen; manuelle
  Shifts und HR-Aufzeichnung bleiben davon unabhängig.
- Anschub- und Distanzwerte kennzeichnen die geschätzte Zeitbasis und bleiben
  bei unzureichender Abdeckung unbekannt.

### Validation status

- Beta 4 ist ein Testkandidat. Simulator-, Hardware-, Garmin-Connect- und
  Schema-9-FIT-Nachweise werden getrennt geführt; Distanzgenauigkeit ist nicht
  aus einem erfolgreichen Smoke-Test abzuleiten.

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
