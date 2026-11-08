import Foundation

enum Stats {
    /// Kalender mit Montag als Wochenbeginn.
    static let cal: Calendar = {
        var c = Calendar.current
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        return c
    }()

    static var today: Date { cal.startOfDay(for: .now) }

    static func startOfWeek(for date: Date) -> Date {
        cal.dateInterval(of: .weekOfYear, for: date)?.start ?? cal.startOfDay(for: date)
    }

    static func startOfMonth(for date: Date) -> Date {
        cal.dateInterval(of: .month, for: date)?.start ?? cal.startOfDay(for: date)
    }

    static func days(startingAt start: Date, count: Int) -> [Date] {
        (0..<count).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    static func daysOfMonth(_ date: Date) -> [Date] {
        let count = cal.range(of: .day, in: .month, for: date)?.count ?? 30
        return days(startingAt: startOfMonth(for: date), count: count)
    }

    struct DayPercent: Identifiable {
        let date: Date
        let percent: Double
        var id: Date { date }
    }

    struct Result {
        var done = 0
        var possible = 0
        var percent: Double { possible == 0 ? 0 : Double(done) / Double(possible) }
    }

    /// Wie viele der möglichen Häkchen wurden gesetzt?
    /// Gezählt werden nur Tage bis heute und ab dem Start des Habits.
    static func completion(of habits: [Habit], on days: [Date]) -> Result {
        var result = Result()
        let now = today
        for habit in habits {
            let done = habit.doneDays
            let start = habit.startDay
            for day in days where day <= now && day >= start {
                result.possible += 1
                if done.contains(day) { result.done += 1 }
            }
        }
        return result
    }

    /// Tage in Folge bis heute (heute zählt mit, wenn schon abgehakt).
    static func currentStreak(_ habit: Habit) -> Int {
        let done = habit.doneDays
        var day = today
        if !done.contains(day) {
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }
        var count = 0
        while done.contains(day) {
            count += 1
            guard let previous = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    static func bestStreak(_ habit: Habit) -> Int {
        var best = 0
        var current = 0
        var previous: Date?
        for day in habit.doneDays.sorted() {
            if let p = previous, cal.date(byAdding: .day, value: 1, to: p) == day {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
            previous = day
        }
        return best
    }
}
