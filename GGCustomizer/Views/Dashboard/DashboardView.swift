import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: ThemeStore

    private let quickActions: [DashboardQuickAction] = [
        .init("Icon Studio", "app.badge", "Build local icon artwork"),
        .init("Smart Engine", "wand.and.stars", "Extract a local palette"),
        .init("Home Designer", "rectangle.grid.2x2", "Plan pages and GG widgets"),
        .init("Recovery", "shield.lefthalf.filled", "Undo and safeguard GG files")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                activeTheme
                quickActionsSection
                privacyPromise
            }
            .padding()
            .padding(.bottom, 24)
        }
        .background(RoyalBackground())
        .navigationTitle("GG Customizer")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { DeviceCompatibilityCenterView() } label: {
                    Image(systemName: "checkmark.shield")
                }
                .accessibilityLabel("Compatibility Center")
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Your private design atelier", systemImage: "crown.fill")
                .font(.title2.bold())
                .foregroundStyle(RoyalPalette.champagne)
            Text("Welcome, \(store.profile.displayName). Build polished assets, save them locally, and use only Apple-supported integrations.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
        }
    }

    private var activeTheme: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active GG theme").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        Text(store.activeTheme.name).font(.title3.bold())
                        Text(store.activeTheme.subtitle).font(.footnote).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "crown.fill")
                        .font(.title2)
                        .foregroundStyle(Color(uiColor: ThemeEngine.color(from: store.activeTheme.palette.accent)))
                }
                ThemeRibbon(palette: store.activeTheme.palette)
                HStack {
                    NavigationLink { RoyalThemeStoreView() } label: {
                        Label("Browse themes", systemImage: "paintpalette")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(uiColor: ThemeEngine.color(from: store.activeTheme.palette.primary)))
                    Spacer()
                    Text("GG & widgets only")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            RoyalSectionHeader("Start creating", subtitle: "Every action is local, reversible where possible, and scoped to GG Customizer.")
                .foregroundStyle(.white)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink { IconStudioView() } label: { QuickActionCard(action: quickActions[0]) }
                NavigationLink { SmartThemeEngineView() } label: { QuickActionCard(action: quickActions[1]) }
                NavigationLink { HomeScreenDesignerView() } label: { QuickActionCard(action: quickActions[2]) }
                NavigationLink { RecoveryCenterView() } label: { QuickActionCard(action: quickActions[3]) }
            }
            .buttonStyle(.plain)
        }
    }

    private var privacyPromise: some View {
        LimitDisclosureCard(
            title: "Private by default",
            message: "GG Customizer has no ads, subscriptions, or analytics. Designs, ratings, backup history, and exports remain on your device until you explicitly share a file.",
            icon: "hand.raised.fill"
        )
    }
}

private struct DashboardQuickAction {
    let title: LocalizedStringKey
    let symbol: String
    let subtitle: LocalizedStringKey
    init(_ title: LocalizedStringKey, _ symbol: String, _ subtitle: LocalizedStringKey) {
        self.title = title; self.symbol = symbol; self.subtitle = subtitle
    }
}

private struct QuickActionCard: View {
    let action: DashboardQuickAction
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: action.symbol).font(.title2).foregroundStyle(RoyalPalette.gold)
                Text(action.title).font(.subheadline.bold()).foregroundStyle(.primary)
                Text(action.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right").font(.caption.bold()).foregroundStyle(RoyalPalette.gold)
            }
            .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
        }
    }
}

struct ThemeRibbon: View {
    let palette: ThemePalette
    var body: some View {
        LinearGradient(
            colors: [
                Color(uiColor: ThemeEngine.color(from: palette.primary)),
                Color(uiColor: ThemeEngine.color(from: palette.secondary)),
                Color(uiColor: ThemeEngine.color(from: palette.accent))
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(alignment: .leading) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("Applied in GG Customizer")
            }
            .font(.caption.bold())
            .foregroundStyle(Color(uiColor: ThemeEngine.color(from: palette.text)))
            .padding(.horizontal, 14)
        }
    }
}
