import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

/// A deliberately small, non-sensitive payload for the official GG WidgetKit extension.
/// It works when the developer enables the documented App Group entitlement; otherwise
/// widgets fall back to their bundled preview without exposing user data.
struct WidgetThemeSnapshot: Codable, Hashable, Sendable {
    var themeName: String
    var primaryHex: String
    var secondaryHex: String
    var accentHex: String
    var backgroundHex: String
    var textHex: String
    var updatedAt: Date

    init(
        themeName: String,
        primaryHex: String,
        secondaryHex: String,
        accentHex: String,
        backgroundHex: String,
        textHex: String,
        updatedAt: Date
    ) {
        self.themeName = themeName
        self.primaryHex = primaryHex
        self.secondaryHex = secondaryHex
        self.accentHex = accentHex
        self.backgroundHex = backgroundHex
        self.textHex = textHex
        self.updatedAt = updatedAt
    }

    init(theme: ThemePackage) {
        self.init(
            themeName: theme.name,
            primaryHex: theme.palette.primary,
            secondaryHex: theme.palette.secondary,
            accentHex: theme.palette.accent,
            backgroundHex: theme.palette.background,
            textHex: theme.palette.text,
            updatedAt: .now
        )
    }

    static let preview = WidgetThemeSnapshot(
        themeName: "Haider Signature",
        primaryHex: "#465BFF",
        secondaryHex: "#8A7CFF",
        accentHex: "#F1C85A",
        backgroundHex: "#0A0C22",
        textHex: "#F7F7FF",
        updatedAt: .now
    )
}

enum WidgetDataBridge {
    static let appGroupIdentifier = "group.com.haider.ggcustomizer"
    private static let snapshotKey = "widget-theme-snapshot-v1"

    static func publish(theme: ThemePackage) {
        let snapshot = WidgetThemeSnapshot(theme: theme)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults(suiteName: appGroupIdentifier)?.set(data, forKey: snapshotKey)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    static func readSnapshot(defaults: UserDefaults? = UserDefaults(suiteName: appGroupIdentifier)) -> WidgetThemeSnapshot {
        guard let data = defaults?.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetThemeSnapshot.self, from: data) else {
            return .preview
        }
        return snapshot
    }
}
