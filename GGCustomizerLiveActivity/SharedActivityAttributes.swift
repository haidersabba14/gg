import ActivityKit
import Foundation

/// Include this file in both the GG Customizer app target and the Live Activity
/// extension target. It describes only GG Customizer's own activities; it does
/// not provide access to the system Dynamic Island or activities from other apps.
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
