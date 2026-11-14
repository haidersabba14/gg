import ActivityKit
import Foundation
import SwiftUI
import WidgetKit

@main
struct GGCustomizerLiveActivity: WidgetBundle {
    var body: some Widget {
        GGCustomizerLiveActivityWidget()
    }
}

private struct GGCustomizerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GGCustomizerActivityAttributes.self) { context in
            GGActivityLockScreenView(context: context)
                .activityBackgroundTint(.black.opacity(0.92))
                .activitySystemActionForegroundColor(Color(hex: context.state.accentHex))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.isFinished ? "checkmark.seal.fill" : "crown.fill")
                        .foregroundStyle(Color(hex: context.state.accentHex))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(Int(context.state.progress * 100))%")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(.primary)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.taskName)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    GGActivityProgress(context: context)
                }
            } compactLeading: {
                Image(systemName: context.state.isFinished ? "checkmark" : "crown.fill")
                    .foregroundStyle(Color(hex: context.state.accentHex))
            } compactTrailing: {
                Text("\(Int(context.state.progress * 100))")
                    .font(.caption2.monospacedDigit())
            } minimal: {
                Image(systemName: context.state.isFinished ? "checkmark" : "crown.fill")
                    .foregroundStyle(Color(hex: context.state.accentHex))
            }
            .widgetURL(URL(string: "ggcustomizer://dynamic-island"))
            .keylineTint(Color(hex: context.state.accentHex))
        }
    }
}

private struct GGActivityLockScreenView: View {
    let context: ActivityViewContext<GGCustomizerActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: context.state.isFinished ? "checkmark.seal.fill" : "sparkles")
                .font(.title3)
                .foregroundStyle(Color(hex: context.state.accentHex))
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                GGActivityProgress(context: context)
            }
            if let endDate = context.state.endDate, !context.state.isFinished {
                Text(endDate, style: .timer)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 2)
    }
}

private struct GGActivityProgress: View {
    let context: ActivityViewContext<GGCustomizerActivityAttributes>

    var body: some View {
        ProgressView(value: min(max(context.state.progress, 0), 1))
            .tint(Color(hex: context.state.accentHex))
            .accessibilityLabel("GG task progress")
            .accessibilityValue("\(Int(context.state.progress * 100)) percent")
    }
}

private extension Color {
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)
        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: 1
        )
    }
}
