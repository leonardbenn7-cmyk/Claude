import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var month = Stats.startOfMonth(for: .now)

    private var monthDays: [Date] { Stats.daysOfMonth(month) }
    private var isCurrentMonth: Bool { month == Stats.startOfMonth(for: .now) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    PeriodHeader(
                        title: month.formatted(.dateTime.month(.wide).year()),
                        canGoForward: !isCurrentMonth,
                        back: { shiftMonth(-1) },
                        forward: { shiftMonth(1) }
                    )
                    if habits.isEmpty {
                        ContentUnavailableView(
                            "Noch keine Daten",
                            systemImage: "chart.bar",
                            description: Text("Lege im Tab „Woche“ deine Habits an und hake sie ab.")
                        )
                    } else {
                        overview
                        dailyChart
                        perHabit
                        monthsChart
                    }
                }
                .padding()
                .frame(maxWidth: 800)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Statistik")
        }
    }

    private func shiftMonth(_ value: Int) {
        if let next = Stats.cal.date(byAdding: .month, value: value, to: month) {
            withAnimation { month = next }
        }
    }

    // MARK: Monatsübersicht

    private var overview: some View {
        let result = Stats.completion(of: habits, on: monthDays)
        let perfect = monthDays.filter {
            let r = Stats.completion(of: habits, on: [$0])
            return r.possible > 0 && r.done == r.possible
        }.count
        let bestStreak = habits.map(Stats.bestStreak).max() ?? 0

        return Card {
            Text("Monatsübersicht").font(.title3.bold())
            HStack(spacing: 20) {
                ProgressRing(progress: result.percent)
                    .frame(width: 130, height: 130)
                VStack(spacing: 10) {
                    StatTile(title: "Häkchen", value: "\(result.done) / \(result.possible)")
                    StatTile(title: "Perfekte Tage", value: "\(perfect)", color: .orange)
                    StatTile(title: "Längste Serie", value: "\(bestStreak) Tage", color: .pink)
                }
            }
            Text("Du hast \(result.percent.percentText) deiner täglichen Habits erfüllt.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Verlauf im Monat

    private var dailyChart: some View {
        let points = monthDays.compactMap { day -> Stats.DayPercent? in
            let r = Stats.completion(of: habits, on: [day])
            return r.possible > 0 ? Stats.DayPercent(date: day, percent: r.percent * 100) : nil
        }
        let average = points.isEmpty ? 0 : points.map(\.percent).reduce(0, +) / Double(points.count)

        return Card {
            Text("Erfüllt pro Tag").font(.headline)
            if points.isEmpty {
                Text("In diesem Monat gibt es noch keine Daten.")
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                Chart {
                    ForEach(points) { point in
                        BarMark(
                            x: .value("Tag", point.date, unit: .day),
                            y: .value("Erfüllt", point.percent)
                        )
                        .foregroundStyle(Color.accentColor.gradient)
                        .cornerRadius(3)
                    }
                    RuleMark(y: .value("Durchschnitt", average))
                        .foregroundStyle(.secondary)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("Ø \(Int(average.rounded())) %")
                                .font(.caption2).foregroundStyle(.secondary)
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
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.day())
                    }
                }
                .frame(height: 180)
            }
        }
    }

    // MARK: Pro Habit

    private var perHabit: some View {
        Card {
            Text("Pro Habit").font(.headline)
            ForEach(habits) { habit in
                let r = Stats.completion(of: [habit], on: monthDays)
                let color = Color(hex: habit.colorHex)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(habit.emoji)
                        Text(habit.name).font(.subheadline.weight(.medium)).lineLimit(1)
                        Spacer()
                        Text(r.percent.percentText).bold().monospacedDigit().foregroundStyle(color)
                    }
                    ProgressView(value: r.percent).tint(color)
                    HStack {
                        Text("\(r.done) von \(r.possible) Tagen")
                        Spacer()
                        Label("\(Stats.currentStreak(habit)) Tage Serie", systemImage: "flame.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: Letzte 6 Monate

    private var monthsChart: some View {
        let months: [Stats.DayPercent] = (-5...0).compactMap { offset in
            guard let m = Stats.cal.date(byAdding: .month, value: offset, to: month) else { return nil }
            return Stats.DayPercent(date: m, percent: Stats.completion(of: habits, on: Stats.daysOfMonth(m)).percent * 100)
        }

        return Card {
            Text("Letzte 6 Monate").font(.headline)
            Chart {
                ForEach(months) { item in
                    BarMark(
                        x: .value("Monat", item.date, unit: .month),
                        y: .value("Erfüllt", item.percent)
                    )
                    .foregroundStyle(item.date == month ? Color.accentColor : Color.accentColor.opacity(0.35))
                    .cornerRadius(6)
                    .annotation(position: .top) {
                        Text("\(Int(item.percent.rounded())) %").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            .chartYScale(domain: 0...110)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                }
            }
            .frame(height: 170)
        }
    }
}
