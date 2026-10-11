# RinkLogic 0.2.0-beta.4: Minutenfelder und kalibrierte Distanz

## Ziel

Die Testversion `0.2.0-beta.4` soll den bereits auf der Venu 2 Plus
erfolgreich geprüften Aufzeichnungsablauf beibehalten und für den nächsten
Hallentest zwei gezielte Änderungen liefern:

1. Alle von RinkLogic kontrollierten Zeitwerte werden auf Uhr und in Garmin
   Connect als Minutenwerte mit der Einheit `min` dargestellt.
2. Eine klar als Schätzung gekennzeichnete Distanz wird aus dem bestehenden
   Anschubmodell, dem begrenzten Größenfaktor und der bisherigen Testrelation
   berechnet und konsistent auf allen relevanten Uhr- und Connect-Flächen
   verwendet.

Die Beta dient der Datenerhebung und dem Funktionsnachweis. Sie erhebt keinen
Anspruch auf wissenschaftlich validierte Distanzgenauigkeit.

## Geltungsbereich

Die Änderung umfasst die Watch-App, FIT-Developer-Felder, Garmin-Connect-
Beiträge, den lokalen FIT-Parser, Tests, Dokumentation und ein signiertes
Beta-Artefakt. Sie umfasst ausdrücklich nicht:

- GPS-Aufzeichnung oder GPS-Kalibrierung,
- Uploads, Serverdienste oder ein globales Modell,
- automatisches Training mit Daten anderer Nutzer,
- eine Änderung des normalen Release-Standardmodells,
- eine Aussage, die Distanz sei gemessen oder wissenschaftlich validiert.

Die getestete `0.2.0-beta.3` bleibt unverändert als Rückfallversion erhalten.

## Zeitdarstellung

### Nutzeroberflächen

Alle von RinkLogic erzeugten Zeitwerte werden in Minuten ausgegeben. Das gilt
für Live-Ansichten, Abschlussseiten, Connect-IQ-Zusammenfassung,
Connect-Details, HR-Zonen und Shift-Runden. Intern bleiben Millisekunden die
Zeitbasis, damit Berechnungen nicht an Genauigkeit verlieren.

- Gesamt-, Eis- und Bankzeit: Dezimalminuten mit einer Nachkommastelle.
- Durchschnittliche, kürzeste, längste, Median- und einzelne Shiftdauer:
  Dezimalminuten mit zwei Nachkommastellen.
- Zeit in HR-Zone 1 bis 5 und Zeit über 90 % HRmax: Dezimalminuten mit einer
  Nachkommastelle.
- Work-to-Rest-Verhältnis bleibt ein dimensionsloses Verhältnis.
- Shift-Dichte bleibt `Shifts/h`.
- HR-Abfall nach 30 und 60 Sekunden bleibt eine Herzfrequenzdifferenz in bpm;
  die 30/60 Sekunden beschreiben den Messzeitpunkt und werden nicht als
  Dauerwert ausgegeben.

Native Garmin-Flächen außerhalb der Kontrolle der Connect-IQ-App können
weiterhin Garmins eigene Zeitformatierung verwenden. RinkLogic darf dafür
keine abweichende Einheit behaupten.

### FIT-Schema 9

Bereits vergebene IDs werden niemals mit einer neuen Einheit umgedeutet.
Schema 9 zieht daher die aktiven Sekundenfelder 75, 76, 79–84 und 89 zurück
und führt neue `float32`-Session-Felder ein:

| ID | Name | Bedeutung | Einheit |
| --- | --- | --- | --- |
| 101 | `time_on_ice_minutes` | Eiszeit | `min` |
| 102 | `bench_time_minutes` | Bankzeit | `min` |
| 103–107 | `heart_rate_zone_1_minutes` bis `heart_rate_zone_5_minutes` | Zeit in HR-Zone 1–5 | `min` |
| 108 | `time_above_90_percent_hrmax_minutes` | Zeit über 90 % HRmax | `min` |
| 109 | `median_shift_minutes` | Median-Shiftdauer | `min` |

Die vorhandenen Felder 98 (`average_shift_minutes`) und 99
(`shift_duration_minutes`) bleiben unverändert. Die aktive Session-Allokation
lautet damit:

`74, 78, 85, 86, 96, 97, 98, 101, 102, 103, 104, 105, 106, 107, 108, 109`.

Das sind weiterhin exakt 16 Session-Felder. Die Gesamtallokation bleibt mit
34 Developer-Feldern an der bereits getesteten Venu-2-Plus-Grenze. Parser
müssen Schema 4 bis 9 lesen können. Alte Sekundenfelder werden beim Import in
Minuten umgerechnet; neue FIT-Dateien schreiben ausschließlich die neuen
Minutenfelder. Unbekannte oder nicht berechenbare `float32`-Werte werden als
FIT-Invalid/NaN geschrieben und niemals als Null ausgegeben.

Die Garmin-Connect-Reihenfolge beginnt weiterhin mit:

1. Anzahl Shifts,
2. durchschnittliche Shiftdauer in Minuten,
3. durchschnittliche Shift-Herzfrequenz.

Die geschätzte Gesamtdistanz folgt als zusätzlicher, klar gekennzeichneter
Wert. Einzelne Shiftdauern stehen in der Rundenansicht über Feld 99. Kürzester
und längster Shift werden daraus vom lokalen Parser verlustfrei bestimmt;
wegen der bestätigten 16-Felder-Grenze erhalten sie in dieser Beta kein
zusätzliches Session-Feld. Der Median steht über Feld 109 direkt zur Verfügung.

## Distanzmodell der Test-Beta

### Rechenweg

Die Beta verwendet genau eine Distanzberechnung als Quelle für Uhranzeige,
Shift-Runden, FIT-Records und Connect-Zusammenfassung. Für jeden akzeptierten
Anschub gilt:

```text
height_factor = clamp(0.94, 1.06, 1 + (height_cm - 180) / 360)
test_factor   = 220 / 292.5
start_cm      = round(125 * height_factor * test_factor)
rhythm_cm     = round(225 * height_factor * test_factor)
```

Die ersten vier Anschübe eines erkannten Bursts verwenden `start_cm`, spätere
Rhythmusanschübe `rhythm_cm`. Der Größenfaktor wird nur für endliche
Körpergrößen von 80 bis 250 cm verwendet. Fehlt eine gültige Größe, verwendet
die Beta denselben Testfaktor mit dem neutralen Größenfaktor `1.0`.

Der Faktor `220 / 292,5 ≈ 0,752` stammt aus einer einzelnen näherungsweisen
Testrelation. Er ist ein freier Beta-Parameter, keine Literaturkonstante. Die
Grundstruktur aus Start- und Rhythmusanschüben sowie der eng begrenzte
Größenfaktor bilden das experimentelle, evidenzinformierte App-Modell. Gewicht
und BMI gehen nicht in die Schätzung ein.

### Isolation und Kennzeichnung

Das Modell wird in einer eigenen Build-Konfiguration
`:calibrated_profile_test` aktiviert. `monkey.jungle` bleibt beim festen
Release-Modell; die bestehende `ProfileHeight`-Variante bleibt ebenfalls
unverändert. Nur das explizit benannte Beta-4-Artefakt enthält den Testfaktor.

Jede Nutzeranzeige verwendet `≈` oder eine gleichwertige lokalisierte
Kennzeichnung und spricht von „geschätzter Distanz“. Es gibt keine
Umbenennung in „Distanz“ ohne diesen Hinweis. Die aktive Modellquelle wird im
Speicher bis zum Sessionende gesperrt, damit ein laufendes Training nicht mit
unterschiedlichen Faktoren berechnet wird.

### Gemeinsamer Datenfluss

`DistanceEstimator` liefert die kumulierte und shiftbezogene Distanz. Genau
diese Werte speisen:

- die Live-Anzeige für aktuellen beziehungsweise letzten Shift,
- die Gesamtentfernung auf der Uhr,
- Record-Feld 63 (`estimated_distance_cm_total`),
- Lap-Feld 66 (`shift_estimated_distance_cm`),
- Session-Feld 97 (`estimated_distance_m`),
- die zugehörigen Garmin-Connect-Charts, Runden und Detailwerte.

Keine Oberfläche darf die Distanz unabhängig neu berechnen. Fehlende gültige
Bewegungssamples ergeben einen ungültigen Wert statt einer scheinbar
gemessenen Null. Sensorlücken behalten die letzte gültige kumulierte Summe und
markieren die betroffene Shift-Abdeckung als unvollständig.

## Kompatibilität und Fehlerverhalten

- Start, manuelle Shift-Grenzen, HR-Erfassung, Speichern und die drei
  Abschlussseiten bleiben funktional unverändert.
- Der normale Build behält 125/225 cm ohne Testfaktor und muss in einem
  Regressionstest byte- beziehungsweise wertseitig vom Beta-Modell getrennt
  bleiben.
- Schema-4-bis-8-Dateien bleiben lesbar; Sekunden werden nur im Parser zur
  Anzeige in Minuten umgerechnet.
- Schema-9-Felder verwenden neue IDs und dürfen nie mit alten IDs
  zusammengeführt oder als Sekunden interpretiert werden.
- Ungültige Körpergröße führt zum neutralen kalibrierten Beta-Fallback, nicht
  zum unkalibrierten Release-Modell.
- Ein Allokationsfehler verhindert den Aufzeichnungsstart mit bestehender
  Fehleranzeige; es wird keine teilweise interpretierbare Session gespeichert.

## Verifikation

Vor Ausgabe des Beta-Artefakts müssen folgende Nachweise frisch auf dem
Implementierungscommit erzeugt werden:

1. Alle bestehenden Monkey-C-Simulator- und Python-Tests bestehen für den
   normalen Build und die Testvarianten.
2. Neue Tests decken den Faktor `220/292.5`, gültige Grenzwerte des
   Größenfaktors, ungültige Profilwerte, Modell-Locking und die unveränderten
   Release-Konstanten ab.
3. Mapping-Tests belegen, dass Live-, Shift-, Record-, Lap- und Session-Werte
   aus derselben Distanzquelle stammen.
4. Schema-Tests belegen 34 aktive Felder, exakt 16 Session-Felder, eindeutige
   IDs und die neuen Minuten-Einheiten.
5. Parser-Tests decken die alten Sekundenfelder aus Schema 4–8, die bereits in
   Schema 8 vorhandenen Minutenfelder 98/99 und sämtliche neuen
   Schema-9-Minutenfelder ab.
6. Lokalisierungs- und FIT-Contribution-Tests prüfen `min`, `≈` und die
   Connect-Reihenfolge.
7. Fester Release-, ProfileHeight- und kalibrierter Beta-Build kompilieren für
   `venu2plus`; nur der kalibrierte Build wird als `0.2.0-beta.4` signiert.
8. Das signierte IQ-Paket erhält SHA-256, Commit-ID und eine reproduzierbare
   Installationsnotiz. Es wird nicht als stabiler Release veröffentlicht.

## Hardware-Abnahme für den nächsten Test

Vor dem Hallentest wird die Beta auf der angeschlossenen Venu 2 Plus geöffnet
und ein kurzer Start-/Shift-/Speichern-Smoke-Test durchgeführt. Danach sind zu
prüfen:

- kein `IQ!`, HR-Wert sichtbar und manuelle Shifts zählbar,
- alle RinkLogic-Zeitwerte auf Uhr und in Connect mit `min`,
- aktuelle/letzte Shift-Distanz und Gesamtdistanz auf der Uhr mit
  Schätzkennzeichnung,
- Distanzkurve, Shift-Distanzen und Gesamtdistanz in Garmin Connect,
- Connect-Zusammenfassung mit Shifts, durchschnittlicher Shiftdauer und
  durchschnittlicher Shift-Herzfrequenz an erster Stelle,
- gespeicherte Aktivität öffnet sich auf Uhr und Telefon,
- Original-FIT bleibt lokal und enthält Schema 9 mit gültiger CRC.

Ein einzelner erfolgreicher Test validiert die Bedienung und die technische
Durchgängigkeit, nicht die Distanzgenauigkeit. Die reale 22-m-Strecke,
Bedingung ohne beziehungsweise mit Stickhandling, Markerqualität,
Anschubanzahl und Uhrschätzung werden pro Wiederholung getrennt protokolliert.

## Freigabekriterien

`0.2.0-beta.4` ist für den Test freigegeben, wenn alle automatisierten
Prüfungen und der kurze Geräte-Smoke-Test bestehen, die Minuteinheiten auf den
RinkLogic-Flächen sichtbar sind und die geschätzte Distanz auf allen oben
genannten Flächen denselben Wertpfad nutzt. Eine Übernahme des Testfaktors in
den normalen Release erfordert eine separate, vorab definierte Validierung und
ist nicht Teil dieser Spezifikation.
