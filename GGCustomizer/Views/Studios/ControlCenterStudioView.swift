import SwiftUI

/// Explains the user-controlled Control Center integration. Apple requires the
/// user to add an app control themselves; apps cannot rearrange system controls.
struct ControlCenterStudioView: View {
    private var isControlWidgetAvailable: Bool {
        if #available(iOS 18.0, *) { return true }
        return false
    }

    var body: some View {
        ZStack {
            RoyalBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RoyalSectionHeader("Control Center Studio", subtitle: "Official App Intent controls when iOS supports them")
                        .foregroundStyle(.white)

                    LimitDisclosureCard(
                        title: "Your Control Center stays yours",
                        message: "GG Customizer cannot recolor, rearrange, or replace Apple’s Control Center controls. On iOS 18 or later, you may add GG’s own official quick-action control yourself.",
                        icon: "switch.2"
                    )

                    GlassCard {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(RoyalPalette.goldGradient)
                                    .frame(width: 82, height: 82)
                                Image(systemName: "crown.fill")
                                    .font(.title)
                                    .foregroundStyle(RoyalPalette.midnight)
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Open GG Customizer")
                                    .font(.headline)
                                Text("A small official control that opens the app.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                FeatureStatusBadge(status: isControlWidgetAvailable ? .supported : .unsupported)
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 13) {
                            RoyalSectionHeader("How to add it")
                            ControlInstruction(step: 1, text: "Open Control Center on your iPhone.")
                            ControlInstruction(step: 2, text: "Touch and hold an empty area, then choose Add a Control.")
                            ControlInstruction(step: 3, text: "Find GG Customizer and select Open GG Customizer.")
                            ControlInstruction(step: 4, text: "Place it where you want — iOS saves your choice.")
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Compatibility", systemImage: "checkmark.shield")
                                .font(.headline)
                            Text(isControlWidgetAvailable ? "This iOS version can use the official GG control if the included extension is installed and enabled." : "Control Center app controls require iOS 18 or later. You can still use all in-app quick actions.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Control Center Studio")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ControlInstruction: View {
    let step: Int
    let text: LocalizedStringKey
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(step)")
                .font(.caption.bold())
                .foregroundStyle(RoyalPalette.midnight)
                .frame(width: 24, height: 24)
                .background(RoyalPalette.gold, in: Circle())
            Text(text).font(.subheadline)
        }
    }
}
