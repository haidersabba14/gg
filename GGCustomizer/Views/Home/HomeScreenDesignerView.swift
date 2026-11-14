import SwiftUI
import UIKit
import WidgetKit

/// A sandboxed layout planner for GG widgets and exported design boards. It never tries
/// to rearrange SpringBoard; iOS deliberately keeps the real Home Screen under user control.
struct HomeScreenDesignerView: View {
    @EnvironmentObject private var store: ThemeStore
    @State private var draft = HomeScreenLayout(name: "My GG Layout")
    @State private var selectedPageIndex = 0
    @State private var showingSavedLayouts = false
    @State private var exportURL: URL?
    @State private var statusMessage: String?

    private var selectedPage: HomeScreenPage? {
        guard draft.pages.indices.contains(selectedPageIndex) else { return nil }
        return draft.pages[selectedPageIndex]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 19) {
                intro
                LimitDisclosureCard(
                    title: "This is a design board, not SpringBoard control",
                    message: "GG Customizer can save this layout, refresh its own WidgetKit widgets, and export a plan. iOS does not permit an app to move Home Screen icons, pages, or other apps’ widgets.",
                    icon: "rectangle.3.group.bubble.left"
                )
                layoutName
                pageSelector
                preview
                widgetPalette
                placementInspector
                savedActions
            }
            .padding()
            .padding(.bottom, 28)
        }
        .background(RoyalBackground())
        .navigationTitle("Home Screen Designer")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSavedLayouts) {
            SavedLayoutsSheet(
                layouts: store.homeLayouts,
                onLoad: { layout in
                    draft = layout
                    selectedPageIndex = 0
                    showingSavedLayouts = false
                    announce("Loaded \(layout.name) into the local editor.")
                },
                onDelete: { id in store.delete(homeLayoutID: id) }
            )
        }
        .alert("Home Screen Designer", isPresented: Binding(get: { statusMessage != nil }, set: { if !$0 { statusMessage = nil } })) {
            Button("OK", role: .cancel) { statusMessage = nil }
        } message: {
            Text(statusMessage ?? "")
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Design every page with intent", systemImage: "rectangle.grid.2x2.fill")
                .font(.title2.bold())
                .foregroundStyle(RoyalPalette.champagne)
            Text("Build multiple pages, place GG widget ideas on a four-column grid, then save or share your plan. WidgetKit decides its own refresh timing.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.80))
        }
    }

    private var layoutName: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                RoyalSectionHeader("Layout", subtitle: "Saved locally in GG Customizer.")
                TextField("Layout name", text: $draft.name)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Layout name")
            }
        }
    }

    private var pageSelector: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    RoyalSectionHeader("Pages", subtitle: "Preview one saved page at a time.")
                    Spacer()
                    Button {
                        addPage()
                    } label: {
                        Label("Add page", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                    .tint(RoyalPalette.gold)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) {
                        ForEach(Array(draft.pages.enumerated()), id: \.element.id) { index, page in
                            HomePageSelectionButton(
                                page: page,
                                isSelected: index == selectedPageIndex,
                                select: {
                                    selectedPageIndex = index
                                    selectionHaptic()
                                }
                            )
                        }
                    }
                }
                if draft.pages.indices.contains(selectedPageIndex) {
                    HStack {
                        TextField("Page title", text: $draft.pages[selectedPageIndex].title)
                            .textFieldStyle(.roundedBorder)
                        if draft.pages.count > 1 {
                            Button(role: .destructive) { removeSelectedPage() } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("Delete current page")
                        }
                    }
                }
            }
        }
    }

    private var preview: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    RoyalSectionHeader("iPhone preview", subtitle: "A scale preview of this saved GG layout.")
                    Spacer()
                    Text("4 columns").font(.caption.weight(.medium)).foregroundStyle(.secondary)
                }
                if let selectedPage {
                    HomeLayoutPreview(page: selectedPage, palette: store.activeTheme.palette)
                        .frame(height: 420)
                        .accessibilityLabel("Preview for \(selectedPage.title)")
                }
            }
        }
    }

    private var widgetPalette: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                RoyalSectionHeader("Add a GG widget", subtitle: "Weather needs location permission and a configured data source. Other apps’ widgets cannot be styled here.")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 102), spacing: 10)], spacing: 10) {
                    ForEach(HomeWidgetKind.allCases) { kind in
                        Button { addWidget(kind) } label: {
                            VStack(spacing: 7) {
                                Image(systemName: kind.symbol).font(.title3)
                                Text(kind.title).font(.caption.weight(.semibold)).lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 74)
                            .foregroundStyle(.primary)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add \(kind.title) widget")
                    }
                }
            }
        }
    }

    private var placementInspector: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                RoyalSectionHeader("Arrange page", subtitle: "Use grid values to fine-tune a local layout plan.")
                if let page = selectedPage, page.placements.isEmpty {
                    Text("Add a widget above to begin arranging this page.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if draft.pages.indices.contains(selectedPageIndex) {
                    ForEach(draft.pages[selectedPageIndex].placements) { placement in
                        PlacementEditor(
                            placement: binding(for: placement.id),
                            onDelete: { deleteWidget(placement.id) }
                        )
                        if placement.id != draft.pages[selectedPageIndex].placements.last?.id { Divider() }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var savedActions: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                RoyalSectionHeader("Save, refresh & share", subtitle: "All actions affect GG Customizer files and its optional widgets only.")
                Button(action: saveLayout) {
                    Label("Save local layout", systemImage: "square.and.arrow.down.on.square")
                }
                .buttonStyle(RoyalButtonStyle())
                HStack(spacing: 10) {
                    Button {
                        WidgetCenter.shared.reloadAllTimelines()
                        announce("Asked iOS to refresh GG widgets. iOS controls the final refresh time.")
                        haptic(.success)
                    } label: {
                        Label("Refresh GG widgets", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    Button { prepareExport() } label: {
                        Label("Prepare JSON", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label("Share layout file", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(RoyalPalette.amethyst)
                }
                Button { showingSavedLayouts = true } label: {
                    Label("Open saved layouts (\(store.homeLayouts.count))", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func binding(for id: UUID) -> Binding<HomeWidgetPlacement> {
        Binding {
            guard draft.pages.indices.contains(selectedPageIndex),
                  let placement = draft.pages[selectedPageIndex].placements.first(where: { $0.id == id }) else {
                return HomeWidgetPlacement(id: id, kind: .clock, column: 0, row: 0)
            }
            return placement
        } set: { replacement in
            guard draft.pages.indices.contains(selectedPageIndex),
                  let index = draft.pages[selectedPageIndex].placements.firstIndex(where: { $0.id == id }) else { return }
            draft.pages[selectedPageIndex].placements[index] = replacement
        }
    }

    private func addPage() {
        draft.pages.append(HomeScreenPage(title: "Page \(draft.pages.count + 1)"))
        selectedPageIndex = draft.pages.count - 1
        selectionHaptic()
    }

    private func removeSelectedPage() {
        guard draft.pages.count > 1, draft.pages.indices.contains(selectedPageIndex) else { return }
        draft.pages.remove(at: selectedPageIndex)
        selectedPageIndex = min(selectedPageIndex, draft.pages.count - 1)
        haptic(.warning)
    }

    private func addWidget(_ kind: HomeWidgetKind) {
        guard draft.pages.indices.contains(selectedPageIndex) else { return }
        let placements = draft.pages[selectedPageIndex].placements
        let index = placements.count
        let column = (index * 2) % 4
        let row = (index / 2) * 2
        draft.pages[selectedPageIndex].placements.append(HomeWidgetPlacement(kind: kind, column: column, row: row, width: 2, height: 2))
        selectionHaptic()
    }

    private func deleteWidget(_ id: UUID) {
        guard draft.pages.indices.contains(selectedPageIndex) else { return }
        draft.pages[selectedPageIndex].placements.removeAll { $0.id == id }
        haptic(.warning)
    }

    private func saveLayout() {
        draft.updatedAt = .now
        store.save(homeLayout: draft)
        WidgetCenter.shared.reloadAllTimelines()
        announce("Saved \(draft.name) locally. GG widgets were asked to refresh.")
        haptic(.success)
    }

    private func prepareExport() {
        do {
            exportURL = try HomeLayoutTransfer.export(draft)
            announce("Your local layout JSON is ready to share.")
            haptic(.success)
        } catch {
            announce("Could not prepare the layout file: \(error.localizedDescription)")
            haptic(.error)
        }
    }

    private func announce(_ message: String) { statusMessage = message }

    private func haptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        HapticService.notification(type, enabled: store.settings.hapticsEnabled)
    }

    private func selectionHaptic() {
        HapticService.selection(enabled: store.settings.hapticsEnabled)
    }
}

private struct HomePageSelectionButton: View {
    let page: HomeScreenPage
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(alignment: .leading, spacing: 2) {
                Text(page.title).lineLimit(1)
                Text("\(page.placements.count) widgets").font(.caption2)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .foregroundStyle(isSelected ? RoyalPalette.midnight : .primary)
            .background(
                isSelected ? RoyalPalette.gold.opacity(0.95) : Color.white.opacity(0.12),
                in: RoundedRectangle(cornerRadius: 13, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct HomeLayoutPreview: View {
    let page: HomeScreenPage
    let palette: ThemePalette

    var body: some View {
        GeometryReader { proxy in
            let horizontalInset: CGFloat = 18
            let verticalInset: CGFloat = 18
            let gap: CGFloat = 7
            let cellWidth = (proxy.size.width - horizontalInset * 2 - gap * 3) / 4
            let cellHeight = cellWidth * 1.02
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(uiColor: ThemeEngine.color(from: palette.background)),
                                Color(uiColor: ThemeEngine.color(from: palette.surface))
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                VStack(spacing: 0) {
                    HStack {
                        Text("9:41").font(.caption.bold())
                        Spacer()
                        Image(systemName: "wifi").font(.caption)
                        Image(systemName: "battery.100").font(.caption)
                    }
                    .padding(.horizontal, 19)
                    .padding(.top, 15)
                    Spacer()
                }
                ForEach(page.placements) { placement in
                    let width = min(max(placement.width, 1), 4)
                    let height = min(max(placement.height, 1), 4)
                    MiniWidget(kind: placement.kind, palette: palette)
                        .frame(width: cellWidth * CGFloat(width) + gap * CGFloat(width - 1), height: cellHeight * CGFloat(height) + gap * CGFloat(height - 1))
                        .position(
                            x: horizontalInset + cellWidth * CGFloat(placement.column) + (cellWidth * CGFloat(width) + gap * CGFloat(width - 1)) / 2 + gap * CGFloat(placement.column),
                            y: verticalInset + 34 + cellHeight * CGFloat(placement.row) + (cellHeight * CGFloat(height) + gap * CGFloat(height - 1)) / 2 + gap * CGFloat(placement.row)
                        )
                        .clipped()
                }
                if page.placements.isEmpty {
                    VStack(spacing: 9) {
                        Image(systemName: "rectangle.grid.2x2").font(.largeTitle)
                        Text("Add widgets to this page")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white.opacity(0.62))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .foregroundStyle(Color(uiColor: ThemeEngine.color(from: palette.text)))
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 34, style: .continuous).stroke(.white.opacity(0.22)) }
        }
    }
}

private struct MiniWidget: View {
    let kind: HomeWidgetKind
    let palette: ThemePalette

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: kind.symbol).font(.caption)
            Text(kind.previewText).font(.caption2.weight(.semibold)).lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(9)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(uiColor: ThemeEngine.color(from: palette.primary, alpha: 0.72)), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.white.opacity(0.25)) }
    }
}

private struct PlacementEditor: View {
    @Binding var placement: HomeWidgetPlacement
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label(placement.kind.title, systemImage: placement.kind.symbol).font(.subheadline.weight(.semibold))
                Spacer()
                Button(role: .destructive, action: onDelete) { Image(systemName: "trash") }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete \(placement.kind.title) widget")
            }
            HStack(spacing: 12) {
                Stepper("Column \(placement.column + 1)", value: $placement.column, in: 0...3)
                Stepper("Row \(placement.row + 1)", value: $placement.row, in: 0...6)
            }
            HStack(spacing: 12) {
                Stepper("Width \(placement.width)", value: $placement.width, in: 1...4)
                Stepper("Height \(placement.height)", value: $placement.height, in: 1...4)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .font(.footnote)
    }
}

private struct SavedLayoutsSheet: View {
    let layouts: [HomeScreenLayout]
    let onLoad: (HomeScreenLayout) -> Void
    let onDelete: (UUID) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if layouts.isEmpty {
                    RoyalEmptyState(symbol: "folder", title: "No saved layouts", message: "Save a design board to keep it on this device.")
                } else {
                    List {
                        ForEach(layouts) { layout in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(layout.name).font(.headline)
                                    Text("\(layout.pages.count) page\(layout.pages.count == 1 ? "" : "s") · updated \(layout.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.footnote).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Load") { onLoad(layout) }.buttonStyle(.bordered)
                            }
                            .swipeActions {
                                Button(role: .destructive) { onDelete(layout.id) } label: { Label("Delete", systemImage: "trash") }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Saved layouts")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}

private enum HomeLayoutTransfer {
    static func export(_ layout: HomeScreenLayout) throws -> URL {
        let directory = GGFileLocations.exportsDirectory()
        let safeName = layout.name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let url = directory.appendingPathComponent("\(safeName.isEmpty ? "GG-Layout" : safeName)-\(UUID().uuidString).gglayout.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(layout).write(to: url, options: .atomic)
        return url
    }
}

private extension HomeWidgetKind {
    var title: String {
        switch self {
        case .clock: return "Clock"
        case .weather: return "Weather"
        case .battery: return "Battery"
        case .calendar: return "Calendar"
        case .photos: return "Photos"
        case .quote: return "Quote"
        case .deviceInfo: return "Device"
        }
    }

    var symbol: String {
        switch self {
        case .clock: return "clock.fill"
        case .weather: return "cloud.sun.fill"
        case .battery: return "battery.100percent"
        case .calendar: return "calendar"
        case .photos: return "photo.on.rectangle"
        case .quote: return "quote.opening"
        case .deviceInfo: return "iphone"
        }
    }

    var previewText: String {
        switch self {
        case .clock: return "09:41"
        case .weather: return "24° Clear"
        case .battery: return "85%"
        case .calendar: return "Next event"
        case .photos: return "Memories"
        case .quote: return "Create boldly"
        case .deviceInfo: return "iPhone"
        }
    }
}
