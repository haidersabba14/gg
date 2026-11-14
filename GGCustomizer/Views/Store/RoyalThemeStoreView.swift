import SwiftUI
import UIKit

/// Local, no-purchase theme gallery. Applying a theme changes GG Customizer and
/// its optional widgets only; it intentionally never claims to theme iOS itself.
struct RoyalThemeStoreView: View {
    @EnvironmentObject private var store: ThemeStore
    @State private var searchText = ""
    @State private var filter: ThemeStoreFilter = .all
    @State private var previewTheme: ThemePackage?
    @State private var showingScopeInfo = false

    private var visibleThemes: [ThemePackage] {
        store.themes.filter { theme in
            theme.matches(searchText) && filter.includes(theme)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    storeHeader
                    LimitDisclosureCard(
                        title: "Theme scope is honest by design",
                        message: "Apply changes GG Customizer and its optional GG widgets. iOS does not expose an API to apply a system-wide theme, replace other app icons, or move Home Screen icons.",
                        icon: "checkmark.shield.fill"
                    )
                    filters
                    if visibleThemes.isEmpty {
                        RoyalEmptyState(symbol: "magnifyingglass", title: "No themes found", message: "Try another name, tag, or filter.")
                            .frame(maxWidth: .infinity, minHeight: 240)
                    } else {
                        ForEach(visibleThemes) { theme in
                            ThemeStoreCard(
                                theme: theme,
                                isActive: theme.id == store.activeTheme.id,
                                onPreview: { previewTheme = theme },
                                onApply: { apply(theme) },
                                onFavorite: { store.setFavorite(themeID: theme.id) },
                                onRate: { store.rate(themeID: theme.id, rating: $0) }
                            )
                        }
                    }
                }
                .padding()
                .padding(.bottom, 22)
            }
            .background(RoyalBackground())
            .navigationTitle("Royal Theme Store")
            .searchable(text: $searchText, prompt: "Search local themes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let created = store.createRandomTheme()
                        previewTheme = created
                        feedback(.success)
                    } label: {
                        Label("Create random theme", systemImage: "shuffle")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingScopeInfo = true
                    } label: {
                        Label("Theme scope", systemImage: "info.circle")
                    }
                }
            }
            .sheet(item: $previewTheme) { theme in
                ThemePreviewSheet(
                    theme: theme,
                    isActive: theme.id == store.activeTheme.id,
                    onApply: {
                        apply(theme)
                        previewTheme = nil
                    }
                )
            }
            .alert("Where themes apply", isPresented: $showingScopeInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Themes are local, free, and private. GG Customizer can style this app and its widgets after you add them through iOS. It cannot change iOS, SpringBoard, the Lock Screen, or another app.")
            }
        }
    }

    private var storeHeader: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Label("Twenty royal foundations", systemImage: "crown.fill")
                            .font(.title3.bold())
                            .foregroundStyle(RoyalPalette.champagne)
                        Text("Free forever. Stored on your device. No account, ads, or tracking.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 10)
                    FeatureStatusBadge(status: .supported)
                }
                HStack(spacing: 10) {
                    VStack(alignment: .leading) {
                        Text("Active")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(store.activeTheme.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                    }
                    Spacer()
                    Button {
                        if store.restorePreviousTheme() { feedback(.success) } else { feedback(.warning) }
                    } label: {
                        Label("Restore previous", systemImage: "arrow.uturn.backward")
                    }
                    .buttonStyle(.bordered)
                    .tint(RoyalPalette.gold)
                }
            }
        }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Browse")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(ThemeStoreFilter.allCases) { option in
                        Button {
                            filter = option
                            feedback(.selection)
                        } label: {
                            Label(option.title, systemImage: option.symbol)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 13)
                                .padding(.vertical, 9)
                                .foregroundStyle(filter == option ? RoyalPalette.midnight : .primary)
                                .background(filter == option ? AnyShapeStyle(RoyalPalette.goldGradient) : AnyShapeStyle(.thinMaterial), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(filter == option ? .isSelected : [])
                    }
                }
            }
        }
    }

    private func apply(_ theme: ThemePackage) {
        store.apply(themeID: theme.id, scope: .ggCustomizer)
        feedback(.success)
    }

    private func feedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        HapticService.notification(type, enabled: store.settings.hapticsEnabled)
        if type == .success { HapticService.confirmationSound(enabled: store.settings.soundsEnabled) }
    }
}

private enum ThemeStoreFilter: String, CaseIterable, Identifiable {
    case all
    case favorites
    case builtIn
    case local

    var id: String { rawValue }
    var title: String {
        switch self {
        case .all: return "All"
        case .favorites: return "Favorites"
        case .builtIn: return "Royal Collection"
        case .local: return "My Designs"
        }
    }
    var symbol: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .favorites: return "heart.fill"
        case .builtIn: return "crown.fill"
        case .local: return "paintpalette.fill"
        }
    }

    func includes(_ theme: ThemePackage) -> Bool {
        switch self {
        case .all: return true
        case .favorites: return theme.isFavorite
        case .builtIn: return theme.isBuiltIn
        case .local: return !theme.isBuiltIn
        }
    }
}

private struct ThemeStoreCard: View {
    let theme: ThemePackage
    let isActive: Bool
    let onPreview: () -> Void
    let onApply: () -> Void
    let onFavorite: () -> Void
    let onRate: (Int) -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                ThemePalettePreview(palette: theme.palette, height: 132)
                    .overlay(alignment: .topTrailing) {
                        if isActive {
                            Label("Active", systemImage: "checkmark.circle.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(RoyalPalette.midnight)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(RoyalPalette.goldGradient, in: Capsule())
                                .padding(10)
                        }
                    }
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(theme.name).font(.title3.bold())
                        Text(theme.subtitle).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: onFavorite) {
                        Image(systemName: theme.isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(theme.isFavorite ? .pink : .secondary)
                            .font(.title3)
                            .padding(7)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(theme.isFavorite ? "Remove from favorites" : "Add to favorites")
                }
                Text(theme.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 7) {
                    Label(theme.iconTreatment.rawValue.capitalized, systemImage: "app.dashed")
                    Label(theme.wallpaperTreatment.rawValue.capitalized, systemImage: "photo")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                ThemeRating(value: theme.localRating, onRate: onRate)
                HStack(spacing: 10) {
                    Button(action: onPreview) {
                        Label("Preview", systemImage: "eye")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    Button(action: onApply) {
                        Label(isActive ? "Applied in GG" : "Apply in GG", systemImage: isActive ? "checkmark" : "paintbrush.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(uiColor: ThemeEngine.color(from: theme.palette.primary)))
                    .disabled(isActive)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct ThemePalettePreview: View {
    let palette: ThemePalette
    var height: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    Color(uiColor: ThemeEngine.color(from: palette.background)),
                    Color(uiColor: ThemeEngine.color(from: palette.primary)),
                    Color(uiColor: ThemeEngine.color(from: palette.secondary))
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            HStack(spacing: 8) {
                ThemeSampleIcon(symbol: "crown.fill", color: palette.accent)
                ThemeSampleIcon(symbol: "sparkles", color: palette.surface)
                ThemeSampleIcon(symbol: "heart.fill", color: palette.primary)
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.20)) }
    }
}

private struct ThemeSampleIcon: View {
    let symbol: String
    let color: String

    var body: some View {
        Image(systemName: symbol)
            .font(.title2)
            .foregroundStyle(Color(uiColor: ThemeEngine.color(from: color)))
            .frame(width: 47, height: 47)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct ThemeRating: View {
    let value: Int
    let onRate: (Int) -> Void

    var body: some View {
        HStack(spacing: 2) {
            Text("Your rating").font(.caption).foregroundStyle(.secondary)
            Spacer(minLength: 8)
            ForEach(1...5, id: \.self) { index in
                Button { onRate(index == value ? 0 : index) } label: {
                    Image(systemName: index <= value ? "star.fill" : "star")
                        .foregroundStyle(index <= value ? RoyalPalette.gold : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rate \(index) stars")
            }
        }
    }
}

private struct ThemePreviewSheet: View {
    let theme: ThemePackage
    let isActive: Bool
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ThemePalettePreview(palette: theme.palette, height: 280)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(theme.name).font(.largeTitle.bold())
                        Text(theme.summary).foregroundStyle(.secondary)
                    }
                    LimitDisclosureCard(
                        title: "Preview scope",
                        message: "This preview shows GG Customizer styling and export artwork. It does not modify iOS or the appearance of another application.",
                        icon: "eye.trianglebadge.exclamationmark"
                    )
                    VStack(alignment: .leading, spacing: 9) {
                        Label("Included locally", systemImage: "checklist")
                            .font(.headline)
                        Label("GG Customizer palette", systemImage: "paintpalette")
                        Label("GG widget color settings", systemImage: "rectangle.3.group")
                        Label("Exportable icon and wallpaper direction", systemImage: "square.and.arrow.up")
                    }
                    Button(action: onApply) {
                        Label(isActive ? "Already applied in GG" : "Apply in GG Customizer", systemImage: isActive ? "checkmark.circle.fill" : "paintbrush.fill")
                    }
                    .buttonStyle(RoyalButtonStyle())
                    .disabled(isActive)
                }
                .padding()
            }
            .navigationTitle("Theme preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
