import ActivityKit
import Foundation

/// Shared ActivityKit contract for the app and its Live Activity extension.
/// It carries only a GG task title/progress, never device or passcode data.
struct GGCustomizerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var title: String
        var progress: Double
        var endDate: Date?
        var accentHex: String
        var isFinished: Bool
    }

    var taskName: String
    var startedAt: Date
}
