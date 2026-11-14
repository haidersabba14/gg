import SwiftUI

/// Entry point for creative tools. Each studio states its system boundary before
/// any action that could otherwise sound like an iOS-level customization.
struct StudioHubView: View {
    private let tools: [StudioLink] = [
        .init(title: "Icon Studio", subtitle: "Create, preview, export", symbol: "app.badge"),
        .init(title: "Passcode Studio", subtitle: "Preview only — never reads passcodes", symbol: "circle.grid.3x3.fill"),
        .init(title: "Lock Screen Studio", subtitle: "Create wallpapers and official setup guides", symbol: "lock.rectangle.fill"),
        .init(title: "Dynamic Island Studio", subtitle: "Live Activities for GG tasks", symbol: "capsule.portrait.fill"),
        .init(title: "Control Center Studio", subtitle: "Official controls on supported iOS versions", symbol: "switch.2"),
        .init(title: "Dialer Theme Studio", subtitle: "Preview-only keypad themes", symbol: "phone.fill")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                RoyalBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("GG Creative Studios", systemImage: "crown.fill")
                                .font(.title.bold())
                                .foregroundStyle(RoyalPalette.champagne)
                            Text("Build your own assets locally, then export or use Apple’s official controls.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.75))
                        }

                        LimitDisclosureCard(
                            title: "Honest compatibility",
                            message: "GG Customizer cannot modify SpringBoard, the system passcode screen, Phone app, or other apps. Unsupported system changes are never simulated as applied.",
                            icon: "checkmark.shield.fill"
                        )

                        LazyVStack(spacing: 12) {
                            NavigationLink { IconStudioView() } label: {
                                StudioRow(tool: tools[0], status: .limited)
                            }
                            NavigationLink { PasscodeStudioView() } label: {
                                StudioRow(tool: tools[1], status: .unsupported)
                            }
                            NavigationLink { LockScreenStudioView() } label: {
                                StudioRow(tool: tools[2], status: .limited)
                            }
                            NavigationLink { DynamicIslandStudioView() } label: {
                                StudioRow(tool: tools[3], status: .limited)
                            }
                            NavigationLink { ControlCenterStudioView() } label: {
                                StudioRow(tool: tools[4], status: .limited)
                            }
                            NavigationLink { DialerStudioView() } label: {
                                StudioRow(tool: tools[5], status: .unsupported)
                            }
                        }
                    }
                    .padding()
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

private struct StudioLink: Identifiable {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let symbol: String
    var id: String { symbol }
}

private struct StudioRow: View {
    let tool: StudioLink
    let status: FeatureStatusBadge.Status

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: tool.symbol)
                    .font(.title2)
                    .foregroundStyle(RoyalPalette.gold)
                    .frame(width: 38)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(tool.title).font(.headline).foregroundStyle(.primary)
                    Text(tool.subtitle).font(.footnote).foregroundStyle(.secondary)
                    FeatureStatusBadge(status: status)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
