import AppIntents
import ControlCenter
import SwiftUI
import WidgetKit

// Control Center controls are available on iOS 18+. This target should only be
// included by the Xcode project when building with an iOS 18-or-newer SDK.

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
