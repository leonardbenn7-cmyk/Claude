import SwiftUI
import SwiftData

@main
struct HabitTrackerApp: App {
    let container: ModelContainer = {
        let schema = Schema([Habit.self, HabitEntry.self])
        // .automatic: synchronisiert über iCloud, wenn die iCloud-Funktion
        // im Projekt aktiv ist. Sonst werden die Daten nur lokal gespeichert.
        let cloud = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        if let container = try? ModelContainer(for: schema, configurations: cloud) {
            return container
        }
        let local = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: local)
        } catch {
            fatalError("Datenbank konnte nicht geladen werden: \(error)")
        }
    }()

    @State private var health = HealthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(health)
        }
        .modelContainer(container)
    }
}
