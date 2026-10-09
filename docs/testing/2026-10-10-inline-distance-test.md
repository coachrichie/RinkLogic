# ShiftSense-Test am Samstag, 10. Oktober 2026

Ziel: Auf der Venu 2 Plus prüfen, ob die neue experimentelle Sensor-Zeitbasis überhaupt Anschübe, Kadenz, Distanz und Abdeckung liefert. Erst danach die Distanzschätzung auf bekannter Strecke vergleichen. **Die installierte Uhr-App wird vor diesem Test nicht geändert.**

## Auf der Uhr und in der Halle

1. Eine gerade Strecke unabhängig ausmessen (bevorzugt die bereits verwendeten **22 m**). Anfang und Ende markieren. Sportart, Streckenlänge, Uhrarm und Akkustand vor Start notieren. Den Polar H10 nur als HR-Quelle beurteilen, wenn die Verbindung auf der Uhr tatsächlich bestätigt ist; er ist für die Distanzprüfung nicht erforderlich.
2. ShiftSense **manuell** starten. Prüfen: kein `IQ!`, Live-UI sichtbar, Bewegungsseite erreichbar. Ein bis zwei kurze Probeversuche ausführen. Für jeden: untere Taste am Anfang = Shift **starten**, am Ende = Shift **beenden**. Prüfen, ob Anschübe, Kadenz, geschätzte Distanz und Sensorabdeckung Zahlen statt `--` zeigen. Das `~` an der Distanz kennzeichnet die geschätzte Zeitbasis, keine GPS-Messung.
3. Falls die App abstürzt, nicht speichert oder Bewegungsfelder weiterhin `--`/0-%-Abdeckung zeigen: **Langtest abbrechen**. Aufnahme soweit möglich speichern und Befund notieren. Ein angezeigter Nullwert ohne Sensorabdeckung ist kein Nachweis für null Bewegung.
4. Wenn die Probe funktioniert: fünf Versuche **A** ohne Puck (normales gerades Skating), fünf Versuche **B** mit Puck und aktivem Stickhandling. Möglichst gleiche Strecke; echte Strecke pro Versuch notieren. Jeden Versuch mit zwei unteren Tastendrücken als vollständigen manuellen Shift markieren. Verspätete/vergessene/doppelte Marker sofort notieren; nicht nachträglich als korrekt ausgeben. Eine längere Spiel-/Pass-/Schuss-Sequenz kann zusätzlich als eigener Beobachtungsshift folgen, zählt aber **nicht** zu den zehn geraden Streckenversuchen.
5. Wenn jemand die Anschübe unabhängig zählen oder filmen kann, Referenzzahl pro Versuch festhalten. Ohne unabhängige Zählung das Feld **leer** lassen; keine Zahl von der Uhr abschreiben. Akkustand nach dem Test notieren. Aufnahme mit oberer Taste stoppen und speichern; Sichtbarkeit auf Uhr und in Garmin Connect prüfen.

## Nach dem Test lokal

- Original-FIT unverändert unter `analysis/private/` sichern; nicht auf GitHub hochladen. Bei mehreren Aufnahmen jede FIT-Datei separat auswerten. Die lokale Kalibrierungs-CSV enthält die echte `session_id` aus **genau dieser** FIT-Datei und die Reihenfolge aller manuellen Shifts; siehe [Auswertungsanleitung](20-30m-distance-evaluation.md#lokale-auswertung-nach-dem-test).
- Für jeden Versuch festhalten: Nummer, A/B, reale Strecke, Markerqualität, Uhr-Anschübe, Uhr-Distanz, Sensorabdeckung und optional unabhängig gezählte Anschübe. Unsichere Marker als `uncertain`, `missing`, `duplicate` oder `delayed` markieren. Fehlende Werte nicht als 0 behandeln.
- Getrennt berichten: Distanzfehler für A und B, Anschubfehler **nur** bei externer Zählung, ungültige Versuche mit Grund. Aus einem einzelnen Samstagstest wird weder eine kalibrierte Kilometerzahl noch eine automatische Shift-Erkennung freigegeben.
