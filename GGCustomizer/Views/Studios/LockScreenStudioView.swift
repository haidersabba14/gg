import PhotosUI
import SwiftUI
import UIKit

/// Generates a local wallpaper image and explains the only supported way to
/// apply it: save/share it, then choose it manually in iOS Settings.
struct LockScreenStudioView: View {
    @State private var selectedStyle = LockWallpaperStyle.midnightGold
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var importedPhoto: UIImage?
    @State private var exportedURL: URL?
    @State private var isShowingInstructions = false
    @State private var exportError: String?

    var body: some View {
        ZStack {
            RoyalBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RoyalSectionHeader("Lock Screen Studio", subtitle: "Create a wallpaper, then apply it through iOS")
                        .foregroundStyle(.white)

                    LimitDisclosureCard(
                        title: "iOS applies wallpapers",
                        message: "GG Customizer cannot set your wallpaper, change the lock-screen clock, or guarantee a depth effect. Export your artwork and select it manually in the official iOS wallpaper flow.",
                        icon: "lock.rectangle.fill"
                    )

                    WallpaperPreview(style: selectedStyle, image: importedPhoto)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Lock screen wallpaper preview")

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            RoyalSectionHeader("Wallpaper library", subtitle: "All artwork stays on your device until you export it")
                            Picker("Wallpaper style", selection: $selectedStyle) {
                                ForEach(LockWallpaperStyle.allCases) { style in
                                    Text(style.title).tag(style)
                                }
                            }
                            .pickerStyle(.segmented)

                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Label(importedPhoto == nil ? "Add a local photo" : "Replace local photo", systemImage: "photo.on.rectangle.angled")
                                    .goldCapsule()
                            }
                            .onChange(of: selectedPhoto) { _, item in
                                guard let item else { return }
                                Task {
                                    guard let data = try? await item.loadTransferable(type: Data.self),
                                          let image = UIImage(data: data) else { return }
                                    await MainActor.run { importedPhoto = image }
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(spacing: 12) {
                            Button {
                                exportWallpaper()
                            } label: {
                                Label("Prepare Wallpaper Export", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(RoyalButtonStyle())

                            if let exportedURL {
                                ShareLink(item: exportedURL, preview: SharePreview("GG Customizer Wallpaper")) {
                                    Label("Share or Save Wallpaper", systemImage: "square.and.arrow.up.fill")
                                        .goldCapsule()
                                }
                                .frame(maxWidth: .infinity)
                            }

                            Button {
                                isShowingInstructions = true
                            } label: {
                                Label("Official iOS Setup Instructions", systemImage: "info.circle")
                            }
                            .font(.subheadline.weight(.semibold))
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Lock Screen Studio")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Export unavailable", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
            Button("OK", role: .cancel) { exportError = nil }
        } message: { Text(exportError ?? "") }
        .sheet(isPresented: $isShowingInstructions) {
            LockScreenInstructions()
                .presentationDetents([.medium])
        }
    }

    private func exportWallpaper() {
        let renderer = ImageRenderer(content: WallpaperArtwork(style: selectedStyle, image: importedPhoto).frame(width: 1290, height: 2796))
        renderer.scale = 1
        guard let image = renderer.uiImage, let data = image.pngData() else {
            exportError = "GG Customizer could not generate this image. Try another style."
            return
        }

        do {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("GGCustomizerExports", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let file = folder.appendingPathComponent("GG-Wallpaper-\(UUID().uuidString).png")
            try data.write(to: file, options: .atomic)
            exportedURL = file
        } catch {
            exportError = error.localizedDescription
        }
    }
}

private enum LockWallpaperStyle: String, CaseIterable, Identifiable {
    case midnightGold, sapphireGlass, emeraldBloom, blackDiamond
    var id: String { rawValue }
    var title: LocalizedStringKey {
        switch self {
        case .midnightGold: return "Midnight Gold"
        case .sapphireGlass: return "Sapphire Glass"
        case .emeraldBloom: return "Emerald Bloom"
        case .blackDiamond: return "Black Diamond"
        }
    }
    var colors: [Color] {
        switch self {
        case .midnightGold: return [RoyalPalette.midnight, .black, RoyalPalette.gold.opacity(0.75)]
        case .sapphireGlass: return [.black, RoyalPalette.sapphire.opacity(0.76), .cyan.opacity(0.32)]
        case .emeraldBloom: return [.black, RoyalPalette.emerald.opacity(0.65), .mint.opacity(0.28)]
        case .blackDiamond: return [.black, Color(red: 0.17, green: 0.17, blue: 0.21), .black]
        }
    }
    var accent: Color { colors.last ?? .white }
}

private struct WallpaperPreview: View {
    let style: LockWallpaperStyle
    let image: UIImage?
    var body: some View {
        WallpaperArtwork(style: style, image: image)
            .aspectRatio(9 / 19.5, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 38, style: .continuous).stroke(.white.opacity(0.24), lineWidth: 1) }
            .shadow(color: .black.opacity(0.4), radius: 22, y: 12)
    }
}

private struct WallpaperArtwork: View {
    let style: LockWallpaperStyle
    let image: UIImage?
    var body: some View {
        ZStack {
            LinearGradient(colors: style.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.60)
                    .clipped()
            }
            Circle()
                .fill(style.accent.opacity(0.4))
                .frame(width: 700, height: 700)
                .blur(radius: 90)
                .offset(x: 260, y: -600)
            VStack(spacing: 7) {
                Text("9:41")
                    .font(.system(size: 142, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                Text("Friday, November 13")
                    .font(.system(size: 31, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))
                Spacer()
                HStack(spacing: 22) {
                    Image(systemName: "flashlight.off.fill")
                    Image(systemName: "camera.fill")
                }
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.88))
                .padding(.bottom, 80)
            }
            .padding(.top, 145)
        }
        .clipped()
    }
}

private struct LockScreenInstructions: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("Apply a wallpaper") {
                    Label("Prepare and share the PNG from this studio.", systemImage: "1.circle.fill")
                    Label("Save it to Photos or Files using Apple’s share sheet.", systemImage: "2.circle.fill")
                    Label("Touch and hold your Lock Screen, then tap + to add a wallpaper.", systemImage: "3.circle.fill")
                    Label("Choose Photos, select your exported image, and adjust it in iOS.", systemImage: "4.circle.fill")
                }
                Section("About depth and clocks") {
                    Text("iOS decides whether an image qualifies for the depth effect. Clock fonts and Lock Screen widgets are selected in Apple’s editor, not by GG Customizer.")
                }
            }
            .navigationTitle("Official setup")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
