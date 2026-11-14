import SwiftUI

struct MoreHubView: View {
    @EnvironmentObject private var store: ThemeStore

    var body: some View {
        List {
            Section {
                profileHeader
            }
            .listRowBackground(Color.clear)

            Section("Create & share") {
                NavigationLink { SmartThemeEngineView() } label: {
                    MoreRow(title: "Smart Theme Engine", subtitle: "Palette extraction, random themes, import and export", symbol: "wand.and.stars")
                }
                NavigationLink { HomeScreenDesignerView() } label: {
                    MoreRow(title: "Home Screen Designer", subtitle: "Multiple-page plans and GG widget ideas", symbol: "rectangle.grid.2x2")
                }
                NavigationLink { ThemeTransferView() } label: {
                    MoreRow(title: "Theme Files", subtitle: "Share JSON and ZIP packages through iOS", symbol: "square.and.arrow.up.on.square")
                }
                NavigationLink { VerifiedIntegrationsCenterView() } label: {
                    MoreRow(title: "Verified Integrations", subtitle: "Reviewed, file-based integrations only", symbol: "checkmark.shield")
                }
            }

            Section("System integrations") {
                NavigationLink { LockScreenStudioView() } label: {
                    MoreRow(title: "Lock Screen Studio", subtitle: "Wallpaper creation and official setup", symbol: "lock.rectangle")
                }
                NavigationLink { DynamicIslandStudioView() } label: {
                    MoreRow(title: "Dynamic Island Studio", subtitle: "GG-only Live Activities", symbol: "capsule.portrait")
                }
                NavigationLink { ControlCenterStudioView() } label: {
                    MoreRow(title: "Control Center Studio", subtitle: "Official control on iOS 18+", symbol: "switch.2")
                }
            }

            Section("Safety & information") {
                NavigationLink { RecoveryCenterView() } label: {
                    MoreRow(title: "Emergency Recovery Center", subtitle: "Backup, undo, safe mode, health scan", symbol: "shield.lefthalf.filled")
                }
                NavigationLink { DeviceCompatibilityCenterView() } label: {
                    MoreRow(title: "Compatibility Center", subtitle: "Real public-API capability report", symbol: "checkmark.shield")
                }
                NavigationLink { GGSettingsView() } label: {
                    MoreRow(title: "Settings & Profile", subtitle: "Language, appearance, sounds, privacy", symbol: "gearshape")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(RoyalBackground())
        .navigationTitle("More")
    }

    private var profileHeader: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(RoyalPalette.goldGradient).frame(width: 50, height: 50)
                    Image(systemName: "person.fill").foregroundStyle(RoyalPalette.midnight)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.profile.displayName).font(.headline)
                    Text(store.profile.bio.isEmpty ? "Local GG profile" : store.profile.bio)
                        .font(.footnote).foregroundStyle(.secondary).lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct MoreRow: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let symbol: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).foregroundStyle(RoyalPalette.gold).frame(width: 23)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
