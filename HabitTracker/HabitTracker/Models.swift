import Foundation
import SwiftData

// Für iCloud-Sync braucht SwiftData: Standardwerte für alle Felder,
// optionale Beziehungen und keine "unique"-Felder.

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = "✅"
    var colorHex: String = "34C759"
    var createdAt: Date = Date()
    var sortOrder: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \HabitEntry.habit)
    var entries: [HabitEntry]? = []

    init(name: String, emoji: String, colorHex: String, sortOrder: Int) {
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }

    /// Ab diesem Tag zählt das Habit in die Prozentwerte.
    var startDay: Date { Stats.cal.startOfDay(for: createdAt) }

    /// Alle Tage, an denen das Habit abgehakt wurde.
    var doneDays: Set<Date> {
        Set((entries ?? []).map { Stats.cal.startOfDay(for: $0.day) })
    }
}

/// Ein Häkchen: "Habit X an Tag Y erledigt".
@Model
final class HabitEntry {
    var day: Date = Date()
    var habit: Habit?

    init(day: Date) {
        self.day = Stats.cal.startOfDay(for: day)
    }
}
