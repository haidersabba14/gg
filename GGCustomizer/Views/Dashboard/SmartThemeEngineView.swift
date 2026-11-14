import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

/// Local palette tools. Pixel analysis happens in `ThemeEngine` on the device;
/// no image or palette is uploaded to a service.
struct SmartThemeEngineView: View {
    @EnvironmentObject private var store: ThemeStore
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var importedImage: UIImage?
    @State private var suggestions: [ThemePalette] = []
    @State private var selectedPalette: ThemePalette?
    @State private var statusMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                photoInput
                suggestionSection
                randomSection
                scheduleSection
            }
            .padding()
            .padding(.bottom, 28)
        }
        .background(RoyalBackground())
        .navigationTitle("Smart Theme Engine")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Smart Theme Engine", isPresented: Binding(get: { statusMessage != nil }, set: { if !$0 { statusMessage = nil } })) {
            Button("OK", role: .cancel) { statusMessage = nil }
        } message: { Text(statusMessage ?? "") }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Intelligent, private color direction", systemImage: "wand.and.stars")
                .font(.title2.bold()).foregroundStyle(RoyalPalette.champagne)
            Text("Sample a local image, create a coherent GG palette, or generate a fresh random theme. Nothing leaves your iPhone.")
                .font(.subheadline).foregroundStyle(.white.opacity(0.78))
        }
    }

    private var photoInput: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                RoyalSectionHeader("Extract colors locally", subtitle: "The engine samples a small on-device bitmap; the original photo is never uploaded or retained by this tool.")
                if let importedImage {
                    Image(uiImage: importedImage)
                        .resizable().scaledToFill().frame(height: 155).frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label(importedImage == nil ? "Choose local image" : "Choose another image", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .onChange(of: selectedPhoto) { _, item in loadPalette(from: item) }
            }
        }
    }

    @ViewBuilder
    private var suggestionSection: some View {
        if !suggestions.isEmpty {
            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    RoyalSectionHeader("Suggested collections", subtitle: "Select a palette, name it, then save it as a local GG theme.")
                    ForEach(Array(suggestions.enumerated()), id: \.offset) { index, palette in
                        Button {
                            selectedPalette = palette
                            HapticService.selection(enabled: store.settings.hapticsEnabled)
                        } label: {
                            HStack(spacing: 12) {
                                PaletteStrip(palette: palette)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(index == 0 ? "Natural extraction" : "Harmony \(index + 1)")
                                        .font(.subheadline.weight(.semibold))
                                    Text(palette.primary).font(.caption.monospaced()).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: selectedPalette == palette ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedPalette == palette ? RoyalPalette.gold : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Button(action: saveSuggestedTheme) {
                        Label("Save & apply selected GG theme", systemImage: "checkmark.seal.fill")
                    }
                    .buttonStyle(RoyalButtonStyle())
                    .disabled(selectedPalette == nil)
                }
            }
        }
    }

    private var randomSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                RoyalSectionHeader("Surprise me", subtitle: "Create an unlimited number of compact, local themes within available device storage.")
                Button {
                    let theme = store.createRandomTheme()
                    store.apply(themeID: theme.id)
                    statusMessage = "Created and applied \(theme.name) inside GG Customizer."
                    HapticService.notification(.success, enabled: store.settings.hapticsEnabled)
                } label: {
                    Label("Generate random theme", systemImage: "shuffle")
                }
                .buttonStyle(RoyalButtonStyle())
            }
        }
    }

    private var scheduleSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                RoyalSectionHeader("Change timing", subtitle: "A best-effort GG-only schedule; iOS controls background execution.")
                Picker("Theme schedule", selection: Binding(
                    get: { store.settings.themeScheduleRule },
                    set: { store.settings.themeScheduleRule = $0 }
                )) {
                    ForEach(ThemeScheduleRule.allCases) { rule in Text(rule.smartTitle).tag(rule) }
                }
                .pickerStyle(.menu)
                Text("The schedule never changes the iOS system appearance or other apps. It runs only when iOS lets GG Customizer execute.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    private func loadPalette(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                await MainActor.run { statusMessage = "That image could not be read locally." }
                return
            }
            let generated = ThemeEngine.suggestedPalettes(from: image)
            await MainActor.run {
                importedImage = image
                suggestions = generated
                selectedPalette = generated.first
                statusMessage = generated.isEmpty ? "No usable colors were found in that image." : "Created \(generated.count) on-device palette suggestions."
            }
        }
    }

    private func saveSuggestedTheme() {
        guard let palette = selectedPalette else { return }
        let theme = ThemePackage(
            name: "Local Palette \(Date.now.formatted(.dateTime.month(.abbreviated).day()))",
            subtitle: "Extracted on this device",
            summary: "A GG-only color collection generated from a local image.",
            palette: palette,
            iconTreatment: .glass,
            wallpaperTreatment: .gradient,
            tags: ["local", "extracted"]
        )
        store.upsert(theme: theme)
        store.apply(themeID: theme.id)
        statusMessage = "Saved and applied your local palette in GG Customizer."
        HapticService.notification(.success, enabled: store.settings.hapticsEnabled)
    }
}

private struct PaletteStrip: View {
    let palette: ThemePalette
    var body: some View {
        HStack(spacing: 0) {
            ForEach(palette.allHexValues, id: \.self) { hex in
                Color(uiColor: ThemeEngine.color(from: hex)).frame(width: 18, height: 42)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(.white.opacity(0.18)) }
    }
}

private extension ThemeScheduleRule {
    var smartTitle: String {
        switch self { case .disabled: return "Disabled"; case .onAppLaunch: return "When GG opens"; case .daily: return "Daily when iOS allows"; case .weekly: return "Weekly when iOS allows" }
    }
}
