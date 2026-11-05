# Beta 7 – Remote-Kalibrierung

## Zweck

Dieses Protokoll ermöglicht einen vergleichbaren Beta-Test ohne physischen
Zugriff des Entwicklers auf Uhr oder Testperson. Es bewertet technische
Durchgängigkeit und Datenqualität, nicht medizinische Leistung.

## Vorbereitung

- Unterstütztes Ring-1-Gerät und installierte Beta 7 dokumentieren.
- Eis- oder Inlinehockey vorab festlegen.
- Eine gerade Strecke von exakt 20,00 m markieren.
- Uhr eng tragen; optionalen Brustgurt in Garmin koppeln.
- Keine GPS-Aufzeichnung ist erforderlich.

## Kalibrierung

1. `WEITER` → `KALIBRIERUNG` → Sport wählen.
2. Fünf gültige 20-m-Läufe ohne Stickhandling durchführen.
3. Fünf gültige 20-m-Läufe mit Stickhandling durchführen.
4. Jeden Lauf ausschließlich über die angezeigte untere Taste starten und
   beenden. Ein abgelehnter Lauf wird wiederholt und zählt nicht.
5. Bei 10/10 die Zusammenfassung prüfen und mit der oberen Taste aktivieren.
6. Rückkehr ins Auswahlmenü und sichtbaren Profilstatus kontrollieren.

## Training und Rückgabe

Danach eine getrennte Aktivität im gleichen Sportprofil aufzeichnen. Mindestens
fünf manuelle Shifts markieren, speichern und in Garmin Connect synchronisieren.
Die Aktivität muss als Hockey erscheinen; Kalorien und die benutzerdefinierten
Minutenfelder werden geprüft. Eine native Distanz von `0,00 km` ist in Beta 7
zulässig und wird nicht als Fehlschlag gewertet.
Testperson sendet anschließend über einen privaten Kanal:

- originale Kalibrierungs-FIT-Datei;
- originale Trainings-FIT-Datei;
- Gerätemodell, Firmware, App-Version und gewählten Sport;
- gemessene 20-m-Referenz, beobachtete Ablehnungen und Bedienprobleme;
- Screenshot der benutzerdefinierten Garmin-Connect-Felder ohne Kontodaten.

## Datenschutz und Grenzen

Rohdateien bleiben außerhalb von Git. Beta 7 lädt nichts automatisch hoch und
trainiert kein globales Modell. Ein persönliches Profil wird nur lokal auf der
Uhr gespeichert. Fehlende Sensordaten bleiben unbekannt; sie dürfen nicht als
Null oder als belegte Distanz interpretiert werden.
