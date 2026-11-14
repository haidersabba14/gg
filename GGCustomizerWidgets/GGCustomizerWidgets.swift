import Foundation
import SwiftUI
import WidgetKit

// MARK: - GG Customizer widgets
//
// These widgets intentionally expose only GG Customizer content. WidgetKit does
// not permit an app to restyle another app's widgets or the Home Screen itself.

@main
struct GGCustomizerWidgets: WidgetBundle {
    var body: some Widget {
        GGHomeWidget()
        GGLockScreenWidget()
    }
}

private struct GGWidgetEntry: TimelineEntry {
    let date: Date
    let themeName: String
    let quote: String
    let accentHex: String

    static let placeholder = GGWidgetEntry(
        date: .now,
        themeName: "Royal Gold",
        quote: "Your iPhone. Your Style. Your Rules.",
        accentHex: "D8A839"
    )
}

private struct GGWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> GGWidgetEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (GGWidgetEntry) -> Void) {
        completion(makeEntry(for: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GGWidgetEntry>) -> Void) {
        let now = Date()
        let entries = [makeEntry(for: now)]
        let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1_800)
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }

    private func makeEntry(for date: Date) -> GGWidgetEntry {
        // An App Group is optional during development. When the production
        // entitlement is enabled, the host app writes the active theme here.
        let defaults = UserDefaults(suiteName: "group.com.haider.ggcustomizer")
        let snapshot = GGWidgetThemeSnapshot.read(from: defaults)
        return GGWidgetEntry(date: date, themeName: snapshot.themeName, quote: "Your iPhone. Your Style. Your Rules.", accentHex: snapshot.accentHex)
    }
}

private struct GGHomeWidget: Widget {
    let kind = "com.ggcustomizer.home"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GGWidgetProvider()) { entry in
            GGHomeWidgetView(entry: entry)
        }
        .configurationDisplayName("GG Royal Clock")
        .description("A clock and quote styled with your active GG theme.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct GGHomeWidgetView: View {
    let entry: GGWidgetEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, Color(hex: entry.accentHex).opacity(0.38)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(Color(hex: entry.accentHex))
                    Text(entry.themeName)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                }
                .foregroundStyle(.white.opacity(0.92))

                Text(entry.date, style: .time)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)

                Text(entry.quote)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(2)
            }
            .padding()
        }
        .containerBackground(for: .widget) {
            Color.black
        }
    }
}

private struct GGLockScreenWidget: Widget {
    let kind = "com.ggcustomizer.lock"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GGWidgetProvider()) { entry in
            GGLockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("GG Lock Screen")
        .description("A compact GG Customizer lock screen widget.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

private struct GGLockScreenWidgetView: View {
    let entry: GGWidgetEntry
    @Environment(\.widgetFamily) private var family

    @ViewBuilder
    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "crown.fill")
                    .font(.title3)
                Text(entry.date, style: .time)
                    .font(.system(size: 7, design: .rounded))
                    .offset(y: 12)
            }
        case .accessoryInline:
            Label(entry.themeName, systemImage: "crown.fill")
        default:
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.themeName).font(.caption.weight(.semibold))
                    Text(entry.date, style: .time).font(.caption2)
                }
            }
        }
    }
}

private extension Color {
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)
        let red, green, blue: UInt64
        switch sanitized.count {
        case 3:
            red = ((value >> 8) & 0xF) * 17
            green = ((value >> 4) & 0xF) * 17
            blue = (value & 0xF) * 17
        default:
            red = value >> 16
            green = (value >> 8) & 0xFF
            blue = value & 0xFF
        }
        self.init(.sRGB, red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255, opacity: 1)
    }
}

private struct GGWidgetThemeSnapshot: Codable {
    let themeName: String
    let accentHex: String

    static func read(from defaults: UserDefaults?) -> GGWidgetThemeSnapshot {
        guard let data = defaults?.data(forKey: "widget-theme-snapshot-v1"),
              let snapshot = try? JSONDecoder().decode(FullSnapshot.self, from: data) else {
            return GGWidgetThemeSnapshot(themeName: "Haider Signature", accentHex: "#F1C85A")
        }
        return GGWidgetThemeSnapshot(themeName: snapshot.themeName, accentHex: snapshot.accentHex)
    }

    private struct FullSnapshot: Codable {
        let themeName: String
        let primaryHex: String
        let secondaryHex: String
        let accentHex: String
        let backgroundHex: String
        let textHex: String
        let updatedAt: Date
    }
}
