import SwiftUI
import SwiftData

@main
struct HabitTrackerApp: App {
    @State private var health = HealthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(health)
        }
        // Daten werden lokal auf dem iPad gespeichert.
        .modelContainer(for: [Habit.self, HabitEntry.self])
    }
}
