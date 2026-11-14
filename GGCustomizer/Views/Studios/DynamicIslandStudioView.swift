import ActivityKit
import SwiftUI

/// Creates Live Activities for GG Customizer's own timed tasks. A Live Activity
/// is not a mechanism to alter the system Dynamic Island or other apps.
struct DynamicIslandStudioView: View {
    @State private var duration: Double = 15
    @State private var activeActivity: Activity<GGCustomizerActivityAttributes>?
    @State private var statusText = "Ready to create a GG task"
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            RoyalBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RoyalSectionHeader("Dynamic Island Studio", subtitle: "Official Live Activities for GG tasks")
                        .foregroundStyle(.white)
                    LimitDisclosureCard(
                        title: "GG activities only",
                        message: "Live Activities can show a timer or task created by GG Customizer. They cannot redesign the system Dynamic Island or control activities from other apps. Dynamic Island hardware is required for its compact presentation.",
                        icon: "capsule.portrait.fill"
                    )

                    dynamicPreview

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            RoyalSectionHeader("Create a timer activity")
                            HStack {
                                Text("Duration")
                                Spacer()
                                Text("\(Int(duration)) min").monospacedDigit().foregroundStyle(RoyalPalette.gold)
                            }
                            Slider(value: $duration, in: 5...60, step: 5)
                                .tint(RoyalPalette.gold)
                            Text("The timer represents a GG Customizer task. iOS decides whether and where to present it.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Button {
                                startActivity()
                            } label: {
                                Label(activeActivity == nil ? "Start GG Live Activity" : "Replace GG Live Activity", systemImage: "play.fill")
                            }
                            .buttonStyle(RoyalButtonStyle())

                            if activeActivity != nil {
                                Button(role: .destructive) { finishActivity() } label: {
                                    Label("End GG Live Activity", systemImage: "stop.fill")
                                }
                                .buttonStyle(RoyalButtonStyle(isDestructive: true))
                            }
                        }
                    }

                    GlassCard {
                        HStack(spacing: 12) {
                            Image(systemName: activeActivity == nil ? "circle.dotted" : "dot.radiowaves.left.and.right")
                                .foregroundStyle(activeActivity == nil ? .secondary : RoyalPalette.emerald)
                            Text(statusText).font(.subheadline).foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Dynamic Island Studio")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Live Activity unavailable", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private var dynamicPreview: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(.black)
                .frame(width: 178, height: 42)
                .overlay {
                    HStack(spacing: 8) {
                        Image(systemName: activeActivity == nil ? "crown.fill" : "timer")
                            .foregroundStyle(RoyalPalette.gold)
                        Text(activeActivity == nil ? "GG Ready" : "GG Timer")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                }
                .shadow(color: .black.opacity(0.45), radius: 14, y: 8)
            Text("Illustrative preview — iOS controls the real presentation.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.66))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
        .background(.black.opacity(0.32), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func startActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            errorMessage = "Live Activities are disabled for this app or unavailable on this device. Enable them in iOS Settings and try again."
            return
        }
        finishActivity()
        let endDate = Date().addingTimeInterval(duration * 60)
        let attributes = GGCustomizerActivityAttributes(taskName: "GG Focus Timer", startedAt: .now)
        let state = GGCustomizerActivityAttributes.ContentState(
            title: "GG Focus Timer",
            progress: 0,
            endDate: endDate,
            accentHex: "E9B640",
            isFinished: false
        )
        do {
            activeActivity = try Activity<GGCustomizerActivityAttributes>.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: endDate),
                pushType: nil
            )
            statusText = "GG timer started. Presentation depends on iOS and your device."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func finishActivity() {
        guard let activity = activeActivity else { return }
        let finalState = GGCustomizerActivityAttributes.ContentState(
            title: "GG Focus Timer complete",
            progress: 1,
            endDate: nil,
            accentHex: "54C993",
            isFinished: true
        )
        Task {
            await activity.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
        activeActivity = nil
        statusText = "Last GG activity ended."
    }
}
