# Habits – Habit Tracker fürs iPad

Eine iPad-App (SwiftUI) mit:

- **Wochenplaner**: Habits pro Tag abhaken, am Ende Auswertung in Prozent + Diagramm
- **Statistik**: Monatsübersicht (wie viel % deiner täglichen Habits du erfüllt hast), Verlauf pro Tag, Werte pro Habit, Serien, letzte 6 Monate
- **Gesundheit**: Schritte, Distanz, aktive Kalorien, Trainingsminuten, Schlaf, Ruhepuls und HRV aus Apple Health / Apple Watch, mit Diagrammen (7 oder 30 Tage)

Die Daten werden nur auf dem iPad gespeichert.

## Was du brauchst

- Einen **Mac** mit **Xcode** (kostenlos im Mac App Store)
- Deine **Apple-ID** (kostenloses Konto reicht)
- iPadOS 18 oder neuer

## Installation

1. Diesen Ordner auf den Mac laden (z. B. das Repo als ZIP von GitHub herunterladen).
2. `HabitTracker/HabitTracker.xcodeproj` doppelklicken → öffnet Xcode.
3. Links das blaue Projekt **HabitTracker** anklicken → Target **HabitTracker** → Tab **Signing & Capabilities**.
4. Bei **Team** deine Apple-ID auswählen (ggf. erst unter *Xcode → Settings → Accounts* hinzufügen).
5. Falls Xcode meckert, dass die **Bundle Identifier** schon vergeben ist: ändern, z. B. `com.deinname.habits`.
6. iPad per Kabel anschließen, oben in Xcode als Ziel auswählen und **▶︎ (Run)** drücken.
7. Beim ersten Mal auf dem iPad: **Entwicklermodus** einschalten (*Einstellungen → Datenschutz & Sicherheit → Entwicklermodus*) und dem Entwickler-Profil vertrauen (*Einstellungen → Allgemein → VPN & Geräteverwaltung*).

**Wichtig bei kostenlosem Konto:** Die App läuft 7 Tage, danach startet sie nicht mehr.
Dann einfach das iPad wieder anschließen und in Xcode erneut ▶︎ drücken. Deine Daten bleiben dabei erhalten.
Mit dem Apple Developer Program (99 € / Jahr) hält sie ein Jahr.

## Gut zu wissen

- **Gesundheitsdaten auf dem iPad**: Deine Apple Watch schickt ihre Daten ans iPhone. Damit sie auf dem iPad ankommen, muss auf dem iPhone die iCloud-Synchronisierung für Health an sein (*Einstellungen → [Dein Name] → iCloud → Health*) und das iPad mit derselben Apple-ID angemeldet sein. Prüfe am besten zuerst, ob du deine Werte in der Health-App auf dem iPad siehst.
- **Prozentwerte**: Gezählt werden nur Tage bis heute und erst ab dem Tag, an dem du ein Habit angelegt hast. Ein neues Habit zieht deinen Monat also nicht runter.

## Aufbau des Codes

| Datei | Inhalt |
| --- | --- |
| `HabitTrackerApp.swift` | Start der App, lokale Datenbank |
| `Models.swift` | Datenmodell: Habit und Häkchen |
| `Stats.swift` | Berechnung von Prozenten und Serien |
| `HealthManager.swift` | Abfragen aus Apple Health |
| `Views/WeekView.swift` | Wochenplaner mit Auswertung |
| `Views/StatsView.swift` | Monatsstatistik mit Diagrammen |
| `Views/HealthView.swift` | Gesundheitsübersicht |
| `Views/HabitEditor.swift` | Habit anlegen, bearbeiten, sortieren |
