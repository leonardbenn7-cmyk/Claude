import SwiftUI
import SwiftData
import Charts

struct WeekView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    @State private var weekStart = Stats.startOfWeek(for: .now)
    @State private var showNewHabit = false
    @State private var showManage = false

    private var days: [Date] { Stats.days(startingAt: weekStart, count: 7) }
    private var isCurrentWeek: Bool { weekStart == Stats.startOfWeek(for: .now) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    if habits.isEmpty {
                        emptyState
                    } else {
                        ForEach(habits) { habit in
                            HabitWeekRow(habit: habit, days: days) { day in
                                toggle(habit, on: day)
                            }
                        }
                        WeekSummary(habits: habits, days: days)
                    }
                }
                .padding()
                .frame(maxWidth: 800)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Woche")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Bearbeiten") { showManage = true }
                        .disabled(habits.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewHabit = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showNewHabit) { HabitEditor(habit: nil) }
            .sheet(isPresented: $showManage) { HabitsListView() }
        }
    }

    private var header: some View {
        let first = days.first ?? weekStart
        let last = days.last ?? weekStart
        let week = Stats.cal.component(.weekOfYear, from: first)
        let range = "\(first.formatted(.dateTime.day().month(.abbreviated))) – \(last.formatted(.dateTime.day().month(.abbreviated).year()))"
        return VStack(spacing: 8) {
            PeriodHeader(
                title: "KW \(week)",
                subtitle: range,
                canGoForward: !isCurrentWeek,
                back: { shiftWeek(-1) },
                forward: { shiftWeek(1) }
            )
            if !isCurrentWeek {
                Button("Zur aktuellen Woche") {
                    withAnimation { weekStart = Stats.startOfWeek(for: .now) }
                }
                .font(.subheadline)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Noch keine Habits", systemImage: "checklist")
        } description: {
            Text("Lege dein erstes Habit an oder starte mit ein paar Beispielen.")
        } actions: {
            Button("Habit anlegen") { showNewHabit = true }
                .buttonStyle(.borderedProminent)
            Button("Beispiele hinzufügen") { addExamples() }
        }
    }

    private func shiftWeek(_ value: Int) {
        if let next = Stats.cal.date(byAdding: .weekOfYear, value: value, to: weekStart) {
            withAnimation { weekStart = next }
        }
    }

    private func toggle(_ habit: Habit, on day: Date) {
        let day = Stats.cal.startOfDay(for: day)
        // Alle Einträge des Tages löschen – so werden auch doppelte Häkchen
        // (z. B. gleichzeitig auf iPad und iPhone gesetzt) sauber entfernt.
        let existing = (habit.entries ?? []).filter { Stats.cal.isDate($0.day, inSameDayAs: day) }
        if existing.isEmpty {
            let entry = HabitEntry(day: day)
            context.insert(entry)
            entry.habit = habit
            // Wer einen Tag vor dem Start abhakt, verschiebt den Start nach vorne.
            if day < habit.startDay { habit.createdAt = day }
        } else {
            existing.forEach { context.delete($0) }
        }
        try? context.save()
    }

    private func addExamples() {
        let examples = [
            ("2 Liter Wasser", "💧", "30B0C7"),
            ("20 Minuten lesen", "📚", "FF9500"),
            ("Sport", "🏃", "34C759"),
            ("Meditieren", "🧘", "AF52DE"),
            ("Kein Handy nach 22 Uhr", "📵", "FF2D55"),
        ]
        for (index, item) in examples.enumerated() {
            context.insert(Habit(name: item.0, emoji: item.1, colorHex: item.2, sortOrder: index))
        }
        try? context.save()
    }
}

// MARK: - Eine Zeile pro Habit

struct HabitWeekRow: View {
    let habit: Habit
    let days: [Date]
    let toggle: (Date) -> Void

    var body: some View {
        let color = Color(hex: habit.colorHex)
        let done = habit.doneDays
        let result = Stats.completion(of: [habit], on: days)
        let today = Stats.today

        Card {
            HStack {
                Text(habit.emoji).font(.title3)
                Text(habit.name).font(.headline).lineLimit(2)
                Spacer()
                Text("\(result.done)/\(result.possible)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 0) {
                ForEach(days, id: \.self) { day in
                    let isDone = done.contains(day)
                    let isFuture = day > today
                    let isToday = day == today
                    VStack(spacing: 6) {
                        Text(day.formatted(.dateTime.weekday(.short)))
                            .font(.caption2.weight(isToday ? .bold : .regular))
                            .foregroundStyle(isToday ? color : .secondary)
                        Button { toggle(day) } label: {
                            ZStack {
                                Circle().fill(isDone ? color : color.opacity(0.12))
                                if isDone {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(width: 36, height: 36)
                            .overlay {
                                Circle()
                                    .stroke(isToday ? color : .clear, lineWidth: 2)
                                    .padding(-4)
                            }
                            .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(isFuture)
                        .opacity(isFuture ? 0.35 : 1)
                        .sensoryFeedback(.success, trigger: isDone) { _, new in new }
                        .accessibilityLabel("\(habit.name), \(day.formatted(.dateTime.weekday(.wide)))")
                        .accessibilityValue(isDone ? "erledigt" : "offen")
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Auswertung am Ende der Woche

struct WeekSummary: View {
    let habits: [Habit]
    let days: [Date]

    var body: some View {
        let week = Stats.completion(of: habits, on: days)
        let todayInWeek = days.contains(Stats.today)
        let reference = todayInWeek ? [Stats.today] : days
        let dayResult = Stats.completion(of: habits, on: reference)
        let perfectDays = days.filter {
            let r = Stats.completion(of: habits, on: [$0])
            return r.possible > 0 && r.done == r.possible
        }.count
        let ranked = habits
            .map { HabitResult(habit: $0, result: Stats.completion(of: [$0], on: days)) }
            .filter { $0.result.possible > 0 }
            .sorted { $0.result.percent > $1.result.percent }

        Card {
            Text("Auswertung").font(.title3.bold())

            HStack(spacing: 12) {
                StatTile(title: "Woche", value: week.percent.percentText,
                         subtitle: "\(week.done) von \(week.possible)")
                if todayInWeek {
                    StatTile(title: "Heute", value: dayResult.percent.percentText,
                             subtitle: "\(dayResult.done) von \(dayResult.possible)", color: .blue)
                }
                StatTile(title: "Perfekte Tage", value: "\(perfectDays)",
                         subtitle: "alles erledigt", color: .orange)
            }

            Text("Erfüllt pro Tag").font(.subheadline.weight(.semibold))
            Chart {
                ForEach(days, id: \.self) { day in
                    BarMark(
                        x: .value("Tag", day, unit: .day),
                        y: .value("Erfüllt", Stats.completion(of: habits, on: [day]).percent * 100)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .cornerRadius(6)
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 50, 100]) { value in
                    AxisGridLine()
                    AxisValueLabel { Text("\(Int(value.as(Double.self) ?? 0)) %") }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.short), centered: true)
                }
            }
            .frame(height: 160)

            if !ranked.isEmpty {
                Text("Habits diese Woche").font(.subheadline.weight(.semibold))
                ForEach(ranked) { item in
                    HStack {
                        Text(item.habit.emoji)
                        Text(item.habit.name).lineLimit(1)
                        Spacer()
                        Text(item.result.percent.percentText)
                            .monospacedDigit()
                            .foregroundStyle(Color(hex: item.habit.colorHex))
                            .bold()
                    }
                    .font(.subheadline)
                }
            }
        }
    }
}

private struct HabitResult: Identifiable {
    let habit: Habit
    let result: Stats.Result
    var id: UUID { habit.id }
}
