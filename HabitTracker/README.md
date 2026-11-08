# Habits – Habit Tracker für iPhone & iPad

Eine App für iPhone und iPad (SwiftUI) mit:

- **Wochenplaner**: Habits pro Tag abhaken, am Ende Auswertung in Prozent + Diagramm
- **Statistik**: Monatsübersicht (wie viel % deiner täglichen Habits du erfüllt hast), Verlauf pro Tag, Werte pro Habit, Serien, letzte 6 Monate
- **Gesundheit**: Schritte, Distanz, aktive Kalorien, Trainingsminuten, Schlaf, Ruhepuls und HRV aus Apple Health / Apple Watch, mit Diagrammen (7 oder 30 Tage)
- **iCloud-Sync**: Was du auf dem iPad abhakst, erscheint auch auf dem iPhone (und umgekehrt)

## Was du brauchst

- Einen **Mac** mit **Xcode** (kostenlos im Mac App Store)
- Deine **Apple-ID**
- Für den iCloud-Sync zwischen iPad und iPhone: das **Apple Developer Program** (99 € / Jahr).
  Ohne das läuft die App auch, aber dann speichert jedes Gerät nur für sich, und die App
  muss alle 7 Tage neu von Xcode aufs Gerät gespielt werden (Apple-Regel für kostenlose Konten).

## Installation

1. Diesen Ordner auf den Mac laden (z. B. das Repo als ZIP von GitHub herunterladen).
2. `HabitTracker/HabitTracker.xcodeproj` doppelklicken → öffnet Xcode.
3. Links das blaue Projekt **HabitTracker** anklicken → Target **HabitTracker** → Tab **Signing & Capabilities**.
4. Bei **Team** deine Apple-ID auswählen (ggf. erst unter *Xcode → Settings → Accounts* hinzufügen).
5. Falls Xcode meckert, dass die **Bundle Identifier** schon vergeben ist: einfach ändern, z. B. `com.deinname.habits`.
6. **Nur mit kostenlosem Konto:** Bei *iCloud* und *Push Notifications* auf das kleine 🗑/✕ klicken, um die beiden Funktionen zu entfernen (kostenlose Konten dürfen kein iCloud). HealthKit bleibt drin.
7. **Mit bezahltem Konto:** Bei *iCloud* sicherstellen, dass *CloudKit* angehakt ist und ein Container `iCloud.<deine Bundle ID>` ausgewählt ist (mit dem ↻-Knopf anlegen lassen).
8. iPhone per Kabel anschließen, oben in Xcode als Ziel auswählen und **▶︎ (Run)** drücken.
9. Beim ersten Mal auf dem iPhone: *Einstellungen → Allgemein → VPN & Geräteverwaltung* → deinem Entwickler-Profil vertrauen. Außerdem muss der **Entwicklermodus** an sein (*Einstellungen → Datenschutz & Sicherheit → Entwicklermodus*).
10. Dasselbe mit dem iPad wiederholen.

## Gut zu wissen

- **Sync**: Auf beiden Geräten mit derselben Apple-ID in iCloud angemeldet sein. Änderungen kommen meist nach ein paar Sekunden an, manchmal dauert es bis zu einer Minute.
- **Gesundheitsdaten auf dem iPad**: Das iPad zeigt Health-Daten nur, wenn in der Health-App auf dem iPhone die iCloud-Synchronisierung für Health aktiv ist (*Einstellungen → [Dein Name] → iCloud → Health*).
- **Apple Watch**: Ruhepuls, HRV, Trainingsminuten und Schlaf kommen von der Watch – die App liest sie aus Apple Health, eine eigene Watch-App ist dafür nicht nötig.
- **Prozentwerte**: Gezählt werden nur Tage bis heute und erst ab dem Tag, an dem du ein Habit angelegt hast. Ein neues Habit zieht deinen Monat also nicht runter.

## Aufbau des Codes

| Datei | Inhalt |
| --- | --- |
| `HabitTrackerApp.swift` | Start der App, Datenbank mit iCloud |
| `Models.swift` | Datenmodell: Habit und Häkchen |
| `Stats.swift` | Berechnung von Prozenten und Serien |
| `HealthManager.swift` | Abfragen aus Apple Health |
| `Views/WeekView.swift` | Wochenplaner mit Auswertung |
| `Views/StatsView.swift` | Monatsstatistik mit Diagrammen |
| `Views/HealthView.swift` | Gesundheitsübersicht |
| `Views/HabitEditor.swift` | Habit anlegen, bearbeiten, sortieren |
