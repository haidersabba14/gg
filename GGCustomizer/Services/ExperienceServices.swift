import AudioToolbox
import Foundation
import OSLog
import UIKit

enum GGLogger {
    static let subsystem = Bundle.main.bundleIdentifier ?? "com.ggcustomizer.app"
    static let storage = Logger(subsystem: subsystem, category: "storage")
    static let transfer = Logger(subsystem: subsystem, category: "transfer")
    static let compatibility = Logger(subsystem: subsystem, category: "compatibility")
}

enum HapticService {
    static func selection(enabled: Bool) {
        guard enabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium, enabled: Bool) {
        guard enabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType, enabled: Bool) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    /// A subtle in-app confirmation. It is never played until a user enables sounds.
    static func confirmationSound(enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(1104)
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case arabic = "ar"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System / النظام"
        case .english: return "English"
        case .arabic: return "العربية"
        }
    }
}
