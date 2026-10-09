# ShiftSense Hockey – Themen und Arbeitsorte

Stand: 6. Oktober 2026. Diese Übersicht ordnet die lange Projektchronik nach Themen. Frühere Nachrichten bleiben im Chat **ShiftSense Hockey – Projektchronik**; die Fachchats dienen der weiteren Arbeit.

| Thema | Projektchat | Dateien und Ergebnisse |
|---|---|---|
| Garmin-Uhr-App, Start/Stop, Live-UI, Tasten, Builds | **ShiftSense – Uhr-App und Live-UI** | `watch-v2/`, `docs/DEVELOPMENT.md`, `docs/HARDWARE-ALPHA-FIX.md`, `docs/testing/V2-STAGE1-HARDWARE.md`, `docs/testing/V2-STAGE2-UI.md` |
| Bewegungsdaten, FIT-Import, Anschübe, Distanz, Shift-Automatik, Kalibrierung | **ShiftSense – Sensorik und Kalibrierung** | `analysis/`, `watch-v2/source/shifts/`, `docs/data/FIT-SCHEMA.md`, `docs/data/HOCKEY-MOTION-PROFILE.md`, `docs/testing/20-30m-distance-evaluation.md`; private FITs und Einzelberichte unter `analysis/private/` |
| Trainingsdarstellung auf dem Telefon / Garmin Connect | **ShiftSense – Garmin Connect** | `docs/data/FIT-SCHEMA.md`, `watch-v2/source/recording/`, Store-/Connect-IQ-Themen im Fachchat |
| Sportwissenschaftliche Evidenz und Algorithmen | **ShiftSense – Studien und Evidenz** | `docs/data/HOCKEY-EVIDENCE-AUDIT-2026-09-28.md`, `docs/data/HOCKEY-MOTION-PROFILE.md` |
| Logo, Veröffentlichung, GitHub-Auftritt | **ShiftSense – GitHub Showcase** | `docs/branding/`, `docs/store-assets/`, `README.md`, `docs/index.html` |
| Entscheidungen, Freigaben und übergreifende Roadmap | **ShiftSense Hockey – Projektchronik** | `docs/superpowers/specs/`, `docs/superpowers/plans/` |

## Aktueller Test

Der Test vom 5. Oktober 2026 liegt lokal unter `analysis/private/2026-10-05-test/assessment.md`. Zehn kurze Versuche und ein längerer Abschnitt wurden in der FIT-Datei vom 17:05-Uhr-Block anhand manueller Grenzen erkannt. Der Nutzer bestätigte **22 m pro Kurzversuch**, also 220 m externe Referenzstrecke für die zehn Versuche. Die FIT-Felder für Anschubzahl, Distanz und Sensorabdeckung sind für eine Kalibrierung bislang ungültig. Herzfrequenzdaten der späteren Spielaufnahmen wurden vom Nutzer als fehlerhaft gemeldet und bleiben von der Shift-Kalibrierung ausgeschlossen.

## Ablage und Datenschutz

Der aktive Entwicklungsstand liegt in einem isolierten Git-Worktree. Lokale
absolute Projektpfade werden nicht dokumentiert. Roh-FITs und individuelle
Testberichte bleiben unter `analysis/private/` und werden durch `.gitignore`
ausgeschlossen.
