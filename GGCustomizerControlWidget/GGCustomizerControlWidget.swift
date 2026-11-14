import AppIntents
import SwiftUI
import WidgetKit

// Control Center controls are available on iOS 18+. This target should only be
// included by the Xcode project when building with an iOS 18-or-newer SDK.
// Some Xcode SDK variants do not ship the ControlCenter module for Simulator.
// The fallback keeps CI and older SDK builds honest: it exposes no fake control.

#if canImport(ControlCenter)
import ControlCenter

@available(iOS 18.0, *)
struct OpenGGCustomizerIntent: AppIntent {
    static var title: LocalizedStringResource = "Open GG Customizer"
    static var description = IntentDescription("Opens GG Customizer to its safe, app-scoped controls.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

@available(iOS 18.0, *)
struct GGQuickThemeControl: ControlWidget {
    static let kind = "com.ggcustomizer.control.quicktheme"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenGGCustomizerIntent()) {
                Label("Open GG", systemImage: "crown.fill")
            }
        }
        .displayName("GG Quick Theme")
        .description("Open GG Customizer to preview and apply an app-scoped theme.")
    }
}

@available(iOS 18.0, *)
@main
struct GGCustomizerControlWidgetExtension: WidgetBundle {
    var body: some Widget {
        GGQuickThemeControl()
    }
}
#else
@main
struct GGCustomizerControlWidgetExtension: WidgetBundle {
    var body: some Widget {
        GGControlCompatibilityWidget()
    }
}

private struct GGControlCompatibilityWidget: Widget {
    let kind = "com.ggcustomizer.control.compatibility"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CompatibilityProvider()) { _ in
            VStack(spacing: 6) {
                Image(systemName: "switch.2")
                Text("GG Controls")
                    .font(.caption2)
            }
            .containerBackground(for: .widget) { Color.black }
        }
        .configurationDisplayName("GG Controls Compatibility")
        .description("Control Center controls require an SDK that includes Apple's ControlCenter framework.")
        .supportedFamilies([.systemSmall])
    }
}

private struct CompatibilityEntry: TimelineEntry { let date: Date }

private struct CompatibilityProvider: TimelineProvider {
    func placeholder(in context: Context) -> CompatibilityEntry { CompatibilityEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (CompatibilityEntry) -> Void) { completion(CompatibilityEntry(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CompatibilityEntry>) -> Void) {
        completion(Timeline(entries: [CompatibilityEntry(date: .now)], policy: .never))
    }
}
#endif
