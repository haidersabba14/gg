import SwiftUI

@main
struct GGCustomizerApp: App {
    @StateObject private var store = ThemeStore()

    var body: some Scene {
        WindowGroup {
            AppContainerView()
                .environmentObject(store)
                .tint(Color(uiColor: ThemeEngine.color(from: store.activeTheme.palette.accent)))
                .preferredColorScheme(preferredColorScheme)
                .environment(\.locale, appLocale)
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch store.settings.appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private var appLocale: Locale {
        switch store.settings.languageOverride {
        case "ar": return Locale(identifier: "ar")
        case "en": return Locale(identifier: "en")
        default: return .autoupdatingCurrent
        }
    }
}

private struct AppContainerView: View {
    @EnvironmentObject private var store: ThemeStore

    var body: some View {
        Group {
            if store.settings.hasCompletedWelcome {
                GGMainTabView()
            } else {
                CinematicWelcomeView {
                    withAnimation(.easeInOut(duration: 0.55)) {
                        store.settings.hasCompletedWelcome = true
                    }
                }
            }
        }
        .task {
            _ = store.applyScheduledThemeIfDue()
            WidgetDataBridge.publish(theme: store.activeTheme)
        }
    }
}

private struct GGMainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("Home", systemImage: "crown.fill") }

            RoyalThemeStoreView()
                .tabItem { Label("Themes", systemImage: "paintpalette.fill") }

            StudioHubView()
                .tabItem { Label("Studios", systemImage: "sparkles") }

            NavigationStack {
                MoreHubView()
            }
            .tabItem { Label("More", systemImage: "square.grid.2x2.fill") }
        }
    }
}

private struct CinematicWelcomeView: View {
    let begin: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            RoyalBackground()
            VStack(spacing: 22) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(RoyalPalette.gold.opacity(0.16))
                        .frame(width: 174, height: 174)
                        .blur(radius: 12)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 78, weight: .medium))
                        .foregroundStyle(RoyalPalette.goldGradient)
                        .shadow(color: RoyalPalette.gold.opacity(0.55), radius: 26)
                        .scaleEffect(appeared ? 1 : 0.48)
                }
                .accessibilityHidden(true)
                VStack(spacing: 10) {
                    Text("GG Customizer")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Your iPhone. Your Style. Your Rules.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(RoyalPalette.champagne)
                    Text("Design locally. Export safely. Stay in control.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                }
                .opacity(appeared ? 1 : 0)
                Spacer()
                Button(action: begin) {
                    Label("Enter the atelier", systemImage: "arrow.right.circle.fill")
                }
                .buttonStyle(RoyalButtonStyle())
                .padding(.horizontal, 30)
                .opacity(appeared ? 1 : 0)
                Text("No ads · No subscription · No tracking")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
                    .padding(.bottom, 34)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.72).delay(0.12)) { appeared = true }
        }
    }
}
