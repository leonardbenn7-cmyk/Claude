import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

extension Double {
    var percentText: String { formatted(.percent.precision(.fractionLength(0))) }
}

enum Palette {
    static let colors = [
        "34C759", "30B0C7", "007AFF", "5856D6", "AF52DE",
        "FF2D55", "FF3B30", "FF9500", "FFCC00", "A2845E",
    ]
    static let emojis = [
        "✅", "💧", "📚", "🏃", "🧘", "💪", "🥗", "😴",
        "📵", "✍️", "🎸", "🇬🇧", "🧹", "💊", "🚶", "🙏",
    ]
}

/// Weiße Karte auf grauem Hintergrund.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct StatTile: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var color: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2.bold()).foregroundStyle(color).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.6)
            if let subtitle {
                Text(subtitle).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ProgressRing: View {
    let progress: Double
    var color: Color = .accentColor
    var lineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
            Text(progress.percentText).font(.title.bold()).monospacedDigit()
        }
    }
}

/// Kopfzeile mit Pfeilen zum Blättern (Woche / Monat).
struct PeriodHeader: View {
    let title: String
    var subtitle: String? = nil
    let canGoForward: Bool
    let back: () -> Void
    let forward: () -> Void

    var body: some View {
        HStack {
            Button(action: back) { Image(systemName: "chevron.left").padding(8) }
            Spacer()
            VStack(spacing: 2) {
                Text(title).font(.headline)
                if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
            }
            Spacer()
            Button(action: forward) { Image(systemName: "chevron.right").padding(8) }
                .disabled(!canGoForward)
        }
        .font(.title3.weight(.semibold))
    }
}
