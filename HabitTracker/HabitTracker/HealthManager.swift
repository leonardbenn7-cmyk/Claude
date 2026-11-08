import Foundation
import HealthKit
import SwiftUI

struct DailyValue: Identifiable {
    let date: Date
    let value: Double
    var id: Date { date }
}

enum HealthMetric: String, CaseIterable, Identifiable {
    case steps, distance, activeEnergy, exercise, sleep, restingHeartRate, hrv

    var id: String { rawValue }

    var title: String {
        switch self {
        case .steps: "Schritte"
        case .distance: "Distanz"
        case .activeEnergy: "Aktive Kalorien"
        case .exercise: "Trainingsminuten"
        case .sleep: "Schlaf"
        case .restingHeartRate: "Ruhepuls"
        case .hrv: "Herzfrequenzvariabilität"
        }
    }

    var icon: String {
        switch self {
        case .steps: "figure.walk"
        case .distance: "map"
        case .activeEnergy: "flame.fill"
        case .exercise: "figure.run"
        case .sleep: "bed.double.fill"
        case .restingHeartRate: "heart.fill"
        case .hrv: "waveform.path.ecg"
        }
    }

    var color: Color {
        switch self {
        case .steps: .orange
        case .distance: .teal
        case .activeEnergy: .red
        case .exercise: .green
        case .sleep: .indigo
        case .restingHeartRate: .pink
        case .hrv: .purple
        }
    }

    /// Summen (Schritte, Kalorien …) als Balken, Durchschnittswerte (Puls) als Linie.
    var isAverage: Bool { self == .restingHeartRate || self == .hrv }

    var quantityType: HKQuantityType? {
        switch self {
        case .steps: HKQuantityType(.stepCount)
        case .distance: HKQuantityType(.distanceWalkingRunning)
        case .activeEnergy: HKQuantityType(.activeEnergyBurned)
        case .exercise: HKQuantityType(.appleExerciseTime)
        case .restingHeartRate: HKQuantityType(.restingHeartRate)
        case .hrv: HKQuantityType(.heartRateVariabilitySDNN)
        case .sleep: nil
        }
    }

    var unit: HKUnit {
        switch self {
        case .steps: .count()
        case .distance: .meterUnit(with: .kilo)
        case .activeEnergy: .kilocalorie()
        case .exercise, .sleep: .minute()
        case .restingHeartRate: HKUnit.count().unitDivided(by: .minute())
        case .hrv: .secondUnit(with: .milli)
        }
    }

    func format(_ value: Double) -> String {
        switch self {
        case .steps: return value.formatted(.number.precision(.fractionLength(0)))
        case .distance: return value.formatted(.number.precision(.fractionLength(1))) + " km"
        case .activeEnergy: return value.formatted(.number.precision(.fractionLength(0))) + " kcal"
        case .exercise: return value.formatted(.number.precision(.fractionLength(0))) + " min"
        case .restingHeartRate: return value.formatted(.number.precision(.fractionLength(0))) + " bpm"
        case .hrv: return value.formatted(.number.precision(.fractionLength(0))) + " ms"
        case .sleep:
            let minutes = Int(value.rounded())
            return "\(minutes / 60) h \(minutes % 60) min"
        }
    }
}

@Observable
@MainActor
final class HealthManager {
    private let store = HKHealthStore()

    let isAvailable = HKHealthStore.isHealthDataAvailable()
    var values: [HealthMetric: [DailyValue]] = [:]
    var isLoading = false
    var errorMessage: String?

    func requestAuthorization() async {
        guard isAvailable else { return }
        var types = Set<HKObjectType>(HealthMetric.allCases.compactMap { metric -> HKObjectType? in metric.quantityType })
        types.insert(HKCategoryType(.sleepAnalysis))
        do {
            try await store.requestAuthorization(toShare: [], read: types)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func load(days: Int) async {
        guard isAvailable else { return }
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        for metric in HealthMetric.allCases {
            do {
                values[metric] = metric == .sleep
                    ? try await fetchSleep(days: days)
                    : try await fetchQuantity(metric, days: days)
            } catch {
                values[metric] = []
            }
        }
    }

    // MARK: - Abfragen

    private func range(days: Int) -> (start: Date, end: Date, days: [Date]) {
        let today = Stats.today
        let start = Stats.cal.date(byAdding: .day, value: -(days - 1), to: today) ?? today
        return (start, Date(), Stats.days(startingAt: start, count: days))
    }

    private func fetchQuantity(_ metric: HealthMetric, days: Int) async throws -> [DailyValue] {
        guard let type = metric.quantityType else { return [] }
        let r = range(days: days)
        let predicate = HKQuery.predicateForSamples(withStart: r.start, end: r.end)
        let query = HKStatisticsCollectionQueryDescriptor(
            predicate: .quantitySample(type: type, predicate: predicate),
            options: metric.isAverage ? .discreteAverage : .cumulativeSum,
            anchorDate: r.start,
            intervalComponents: DateComponents(day: 1)
        )
        let collection = try await query.result(for: store)

        var byDay: [Date: Double] = [:]
        for stats in collection.statistics() {
            let quantity = metric.isAverage ? stats.averageQuantity() : stats.sumQuantity()
            if let quantity {
                byDay[Stats.cal.startOfDay(for: stats.startDate)] = quantity.doubleValue(for: metric.unit)
            }
        }
        return r.days.map { DailyValue(date: $0, value: byDay[$0] ?? 0) }
    }

    /// Schlaf in Minuten, zugeordnet zum Tag des Aufwachens.
    /// Überlappende Einträge (iPhone + Apple Watch) werden zusammengelegt.
    private func fetchSleep(days: Int) async throws -> [DailyValue] {
        let r = range(days: days)
        let queryStart = r.start.addingTimeInterval(-12 * 3600)
        let predicate = HKQuery.predicateForSamples(withStart: queryStart, end: r.end)
        let query = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: HKCategoryType(.sleepAnalysis), predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )
        let samples = try await query.result(for: store)
        let asleep = Set(HKCategoryValueSleepAnalysis.allAsleepValues.map(\.rawValue))

        var intervalsByDay: [Date: [(Date, Date)]] = [:]
        for sample in samples where asleep.contains(sample.value) {
            let day = Stats.cal.startOfDay(for: sample.endDate)
            intervalsByDay[day, default: []].append((sample.startDate, sample.endDate))
        }

        return r.days.map { day in
            let intervals = (intervalsByDay[day] ?? []).sorted { $0.0 < $1.0 }
            var total: TimeInterval = 0
            var current: (Date, Date)?
            for interval in intervals {
                if let c = current, interval.0 <= c.1 {
                    current = (c.0, max(c.1, interval.1))
                } else {
                    if let c = current { total += c.1.timeIntervalSince(c.0) }
                    current = interval
                }
            }
            if let c = current { total += c.1.timeIntervalSince(c.0) }
            return DailyValue(date: day, value: total / 60)
        }
    }
}
