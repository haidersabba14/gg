import SwiftUI
import UniformTypeIdentifiers

struct ThemeTransferView: View {
    @EnvironmentObject private var store: ThemeStore
    @State private var isImporting = false
    @State private var shareURL: URL?
    @State private var statusMessage: String?
    @State private var isPreparing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                exportSection
                importSection
                LimitDisclosureCard(
                    title: "Portable, not system-level",
                    message: "A GG package contains theme metadata only. It cannot include an Apple ID, device passcode, installed-app icons, system files, or a system-wide theme.",
                    icon: "lock.doc.fill"
                )
            }
            .padding()
            .padding(.bottom, 28)
        }
        .background(RoyalBackground())
        .navigationTitle("Theme Files")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.ggTheme, .json, .zip], allowsMultipleSelection: false) { result in
            importTheme(result)
        }
        .alert("Theme Files", isPresented: Binding(get: { statusMessage != nil }, set: { if !$0 { statusMessage = nil } })) {
            Button("OK", role: .cancel) { statusMessage = nil }
        } message: { Text(statusMessage ?? "") }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Share your style", systemImage: "square.and.arrow.up.on.square")
                .font(.title2.bold()).foregroundStyle(RoyalPalette.champagne)
            Text("Create compact local packages for AirDrop, Files, or any standard iOS share destination. No account or server is required.")
                .font(.subheadline).foregroundStyle(.white.opacity(0.78))
        }
    }

    private var exportSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                RoyalSectionHeader("Export active theme", subtitle: "\(store.activeTheme.name) is currently active in GG Customizer.")
                Button { prepareJSON() } label: {
                    Label("Prepare .ggtheme JSON", systemImage: "doc.text")
                }
                .buttonStyle(RoyalButtonStyle())
                Button { prepareZIP() } label: {
                    Label(isPreparing ? "Preparing ZIP…" : "Prepare ZIP package", systemImage: "archivebox")
                }
                .buttonStyle(.bordered)
                .disabled(isPreparing)
                if let shareURL {
                    ShareLink(item: shareURL) {
                        Label("Share \(shareURL.lastPathComponent)", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(RoyalPalette.amethyst)
                }
            }
        }
    }

    private var importSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                RoyalSectionHeader("Import a theme", subtitle: "Accepts validated .ggtheme, JSON, and ZIP packages selected by you.")
                Button { isImporting = true } label: {
                    Label("Choose theme file", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(RoyalButtonStyle())
                Text("Imported themes are marked as user-created and are checked before being saved. Invalid or future-format packages are rejected without changing your current theme.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    private func prepareJSON() {
        do {
            shareURL = try ThemeTransferService.exportTheme(store.activeTheme)
            statusMessage = "Your .ggtheme file is ready to share."
        } catch { statusMessage = error.localizedDescription }
    }

    private func prepareZIP() {
        guard #available(iOS 16.0, *) else {
            statusMessage = "ZIP packages require iOS 16 or later."
            return
        }
        isPreparing = true
        do {
            shareURL = try ThemeTransferService.exportThemeZIP(store.activeTheme)
            statusMessage = "Your ZIP package is ready to share."
        } catch { statusMessage = error.localizedDescription }
        isPreparing = false
    }

    private func importTheme(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let theme = try ThemeTransferService.importTheme(from: url)
            store.upsert(theme: theme)
            store.apply(themeID: theme.id)
            statusMessage = "Imported and applied \(theme.name) inside GG Customizer."
        } catch { statusMessage = error.localizedDescription }
    }
}

private extension UTType {
    static let ggTheme = UTType(filenameExtension: "ggtheme") ?? .json
}
