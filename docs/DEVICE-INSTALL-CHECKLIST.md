# RinkLogic Beta 7 – Geräte-Installationscheckliste

Diese Checkliste ist für den kontrollierten Remote-Test bestimmt. Sie ist keine
öffentliche Freigabe und führt keinen Upload in das Garmin Developer Portal aus.

## Vor Übergabe an den Tester

- [ ] Nur Commit `7fef4700d30088f9573cc41f1b14774b47bc4517` verwenden.
- [ ] `RinkLogic-0.2.0-beta.7.iq` hat exakt `8.624.741` Byte.
- [ ] SHA-256 des `.iq`-Containers ist exakt
      `4E6A62C40B0AE9FB978CB702CF82854A784A9E98CD79FFF662C7DCC7A90D40DF`.
- [ ] App-ID ist `4c7d5f9e2b484f0da6913b1c8e7f2a64`.
- [ ] Der alte Hash `918F13E4…D6CB8` wurde nicht verwendet.
- [ ] Produkt-ID steht in `watch-v2/device-matrix.json` als Ring 1 und
      `release-enabled`; Ring 2 ist ausgeschlossen.
- [ ] Aus dem `.iq`-Container wurde nur die PRG zur exakten Geräte-Part-Number
      gewählt. Der `.iq`-Container selbst wird nicht nach `GARMIN/APPS/` kopiert.
- [ ] SHA-256 dieser PRG entspricht `expected_prg_sha256` im persönlichen Auftrag.
- [ ] Auftrag, PRG und Testerassistent wurden privat und ohne Garmin-Zugangsdaten
      bereitgestellt.

## Installation auf der Uhr

- [ ] Uhr synchronisiert, mindestens 50 % geladen und per USB verbunden.
- [ ] Erhaltene PRG nochmals lokal gegen den Auftrags-Hash geprüft.
- [ ] Unveränderte PRG unter dem vorgegebenen Namen nach `GARMIN/APPS/` kopiert;
      keine zweite RinkLogic-Kopie behalten.
- [ ] Uhr sicher getrennt und RinkLogic ohne `IQ!` gestartet.
- [ ] Texte sind vollständig lesbar; Touchzonen überlappen nicht.
- [ ] Auf Tastenmodellen entspricht die ausgeführte Aktion der Hervorhebung.
- [ ] Bei Abweichung gestoppt; keine andere Paketvariante ausprobiert.

## Kalibrierung und Training

- [ ] Persönliches Profil stimmt mit dem Auftrag überein: **Eis** oder **Inline**.
- [ ] Gerade, sichere Strecke mit Maßband/Messrad auf exakt 20,00 m markiert.
- [ ] Läufe 1–5 ohne Stickhandling: langsam, schnell, normal, langsam, schnell.
- [ ] Läufe 6–10 mit Puck/Stickhandling: langsam, schnell, normal, langsam, schnell.
- [ ] Jeder Lauf wurde genau einmal sichtbar akzeptiert; Endstand genau 10.
- [ ] Kalibrierung gespeichert; Eis- und Inline-Faktoren nicht vermischt.
- [ ] Separates normales Training mit passendem Auftrag gespeichert.
- [ ] Keine native Garmin-Distanz erwartet: Beta 7 schreibt Distanz nur in
      RinkLogic-Entwicklerfelder, nicht in `total_distance`.

## Privater Rücklauf

- [ ] Aktivität synchronisiert und in Garmin Connect Web als **Original**
      (FIT/ZIP) exportiert; nicht konvertiert oder neu gepackt.
- [ ] Datei nur nach Auftragsmuster umbenannt; Inhalt unverändert.
- [ ] Lokaler Testerassistent meldet Diagnose **bestanden**.
- [ ] Genau zehn Feedbackfragen beantwortet, ohne Kontakt-/Gesundheitsdaten.
- [ ] Rückgabe-ZIP lokal erzeugt und bewusst über den privaten Kanal gesendet.
- [ ] Kein automatischer Upload, kein Portal-Upload und keine Cloudfunktion genutzt.

Vollständiger Ablauf und Stopbedingungen:
[`testing/BETA7-REMOTE-CALIBRATION.md`](testing/BETA7-REMOTE-CALIBRATION.md).
