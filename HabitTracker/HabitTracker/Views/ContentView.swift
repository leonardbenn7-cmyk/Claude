import SwiftUI

struct ContentView: View {
    var body: some View {
        // Auf dem iPhone unten Tabs, auf dem iPad wahlweise Seitenleiste.
        TabView {
            Tab("Woche", systemImage: "checklist") {
                WeekView()
            }
            Tab("Statistik", systemImage: "chart.bar.xaxis") {
                StatsView()
            }
            Tab("Gesundheit", systemImage: "heart.fill") {
                HealthView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}
