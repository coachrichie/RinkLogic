# ShiftSense Hockey – Bildressourcen fuer den Ready-Bildschirm

Die neu generierten Originale liegen in `shared/branding/`:

- `shiftsense-logo-master.png`: quadratisches Schlaeger/Puck-Symbol mit Shift-Kreis.
- `ice-ready-background-master.png`: dunkle Eishockeyszene mit freiem unteren Bereich fuer Status und Start.
- `favicon.png`: 48 × 48 px aus dem Logo; noch nicht in eine Weboberflaeche eingebunden, da dieses Repository aktuell keine Web-App enthaelt.

Unter `watch-v2/resources/drawables/` liegen verkleinerte Uhr-Versionen: `launcher_icon.png` (70 × 70), `ready_logo.png` (88 × 88) und `ready_background.png` (416 × 416). Die Dateien wurden aus den Originalen mit qualitativ hochwertiger bikubischer Skalierung erstellt. Der Ready-Bildschirm zeichnet Text und Statussymbole als echte UI-Elemente ueber den Hintergrund, damit keine Bildbeschriftung eine falsche Verbindung behauptet.

Bildgenerierung: integriertes `image_gen`-Werkzeug. Die Nutzeraufnahme der Garmin-Cardio-App war eine Layout-Referenz, kein Editierziel; die neue Eishockeyszene und das Logo wurden von Grund auf erstellt.

Logo-Prompt: “Use case: logo-brand. Asset type: square master logo for a Garmin Connect IQ ice-hockey training app named ShiftSense Hockey, to remain recognizable at 40 px. Create a completely new, original, simple high-contrast icon: a single angular ice-hockey stick sweeping around one puck, with a subtle sense of a circular shift/rotation. Flat vector-like geometry, crisp silhouette, icy cyan and electric blue on a very dark navy field. No text, no letters, no numbers, no gradients, no photorealism, no brand marks, no Garmin logo, no watermark. Center the emblem with generous safe margins so it can be cropped into a circle or used as a favicon.”

Hintergrund-Prompt: “Use case: stylized-concept. Asset type: compact Garmin round-watch ready-screen background, 416x416 crop. A completely original ice-hockey scene: a lone hockey player skating on an indoor rink, viewed from slightly behind at a modest distance, with a puck near the stick and low arena lights. Moody dark navy and desaturated icy blue, subtle high-contrast rim lighting, atmospheric but not busy. Player and rink occupy the upper half; lower half remains very dark and visually quiet so white UI status text and buttons will be readable. Circular-safe composition with no important subject at the edges. No words, numbers, logos, icons, UI elements, Garmin branding, watermarks, or identifiable team jerseys. Do not reproduce the cardio app photo; it is only a compositional inspiration for a sports ready screen.”
