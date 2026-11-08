import SwiftUI
import Charts

struct HealthView: View {
    @Environment(HealthManager.self) private var health
    @AppStorage("healthRequested") private var requested = false
    @State private var range = 7

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if !health.isAvailable {
                        ContentUnavailableView(
                            "Apple Health nicht verfügbar",
                            systemImage: "heart.slash",
                            description: Text("Auf diesem Gerät gibt es keine Health-Daten.")
                        )
                    } else if !requested {
                        connectCard
                    } else {
                        Picker("Zeitraum", selection: $range) {
                            Text("7 Tage").tag(7)
                            Text("30 Tage").tag(30)
                        }
                        .pickerStyle(.segmented)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                            ForEach(HealthMetric.allCases) { metric in
                                MetricTile(metric: metric, values: health.values[metric] ?? [])
                            }
                        }

                        ForEach(HealthMetric.allCases) { metric in
                            MetricChart(metric: metric, values: health.values[metric] ?? [])
                        }

                        Text("Tipp: Fehlen Werte, prüfe in der Health-App unter Profil → Apps → Habits, ob alle Kategorien erlaubt sind.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: 800)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Gesundheit")
            .toolbar {
                if health.isLoading {
                    ToolbarItem(placement: .topBarTrailing) { ProgressView() }
                }
            }
            .refreshable { await health.load(days: range) }
            .task(id: range) {
                if requested { await health.load(days: range) }
            }
        }
    }

    private var connectCard: some View {
        Card {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 44))
                .foregroundStyle(.pink)
            Text("Mit Apple Health verbinden").font(.title3.bold())
            Text("Zeige Schritte, Kalorien, Training, Schlaf, Ruhepuls und HRV von deinem iPhone und deiner Apple Watch an. Die Daten bleiben auf deinem Gerät.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                Task {
                    await health.requestAuthorization()
                    requested = true
                    await health.load(days: range)
                }
            } label: {
                Text("Zugriff erlauben").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
        }
    }
}

// MARK: - Kachel mit heutigem Wert

private func average(_ values: [DailyValue], for metric: HealthMetric) -> Double {
    // Tage ohne Messung (0) zählen nicht in den Durchschnitt.
    let measured = values.map(\.value).filter { $0 > 0 }
    return measured.isEmpty ? 0 : measured.reduce(0, +) / Double(measured.count)
}

struct MetricTile: View {
    let metric: HealthMetric
    let values: [DailyValue]

    var body: some View {
        let today = values.last?.value ?? 0
        let avg = average(values, for: metric)
        VStack(alignment: .leading, spacing: 6) {
            Label(metric.title, systemImage: metric.icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(metric.color)
                .lineLimit(1)
            Text(today > 0 ? metric.format(today) : "–")
                .font(.title3.bold())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(metric == .sleep ? "letzte Nacht · Ø \(metric.format(avg))" : "heute · Ø \(metric.format(avg))")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Diagramm pro Wert

struct MetricChart: View {
    let metric: HealthMetric
    let values: [DailyValue]

    var body: some View {
        let avg = average(values, for: metric)
        let measured = values.filter { $0.value > 0 }
        let isShort = values.count <= 7
        let dayFormat: Date.FormatStyle = isShort ? .dateTime.weekday(.short) : .dateTime.day().month(.defaultDigits)

        Card {
            HStack {
                Label(metric.title, systemImage: metric.icon)
                    .font(.headline)
                    .foregroundStyle(metric.color)
                Spacer()
                Text("Ø \(metric.format(avg))")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            if measured.isEmpty {
                Text("Keine Daten im Zeitraum.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart {
                    if metric.isAverage {
                        ForEach(measured) { item in
                            LineMark(x: .value("Tag", item.date, unit: .day),
                                     y: .value(metric.title, item.value))
                                .interpolationMethod(.catmullRom)
                            PointMark(x: .value("Tag", item.date, unit: .day),
                                      y: .value(metric.title, item.value))
                        }
                        .foregroundStyle(metric.color)
                    } else {
                        ForEach(values) { item in
                            BarMark(x: .value("Tag", item.date, unit: .day),
                                    y: .value(metric.title, metric == .sleep ? item.value / 60 : item.value))
                                .foregroundStyle(metric.color.gradient)
                                .cornerRadius(4)
                        }
                    }
                    RuleMark(y: .value("Ø", metric == .sleep ? avg / 60 : avg))
                        .foregroundStyle(.secondary)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                }
                .chartYScale(domain: .automatic(includesZero: !metric.isAverage))
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(metric == .sleep ? "\(Int(v)) h" : v.formatted(.number.notation(.compactName)))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: isShort ? 1 : 7)) { _ in
                        AxisValueLabel(format: dayFormat)
                    }
                }
                .frame(height: 160)
            }
        }
    }
}
