import SwiftUI
import UniformTypeIdentifiers
import UIKit

/// A local artwork editor. It deliberately exports icon artwork instead of attempting to
/// replace the icon of another installed app, which iOS does not permit for sandboxed apps.
struct IconStudioView: View {
    @State private var sourceImage: UIImage?
    @State private var iconScale = 0.88
    @State private var shape: IconStudioShape = .rounded
    @State private var effect: IconStudioEffect = .glass
    @State private var drawingEnabled = false
    @State private var strokes: [IconStroke] = []
    @State private var selectedInk = Color.white
    @State private var isImporterPresented = false
    @State private var isRemovingBackground = false
    @State private var alertMessage: String?
    @State private var savedArtwork: SavedIconArtwork?

    private var renderedImage: UIImage? {
        IconArtworkRenderer.render(source: sourceImage, scale: iconScale, shape: shape, effect: effect, strokes: strokes)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                LimitDisclosureCard(
                    title: "Original app icons stay protected",
                    message: "iOS does not allow GG Customizer to replace the original icons of other installed apps. This studio creates exportable icon artwork and packs only.",
                    icon: "app.badge.checkmark"
                )
                preview
                importAndActions
                editorControls
                drawingControls
                exportSection
            }
            .padding()
            .padding(.bottom, 28)
        }
        .background(RoyalBackground())
        .navigationTitle("Ultimate Icon Studio")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.png, .webP], allowsMultipleSelection: false) { result in
            importImage(result)
        }
        .alert("Icon Studio", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Create an icon fit for a crown", systemImage: "crown.fill")
                .font(.title2.bold())
                .foregroundStyle(RoyalPalette.champagne)
            Text("Import PNG or WebP, draw directly on your design, then save a reusable local icon collection.")
                .foregroundStyle(.white.opacity(0.78))
                .font(.subheadline)
        }
    }

    private var preview: some View {
        GlassCard {
            VStack(spacing: 15) {
                HStack {
                    RoyalSectionHeader("Live icon preview", subtitle: "Circle, square, and glass treatments are previews for exported artwork.")
                    Spacer()
                    Image(systemName: "eye.fill").foregroundStyle(RoyalPalette.gold)
                }
                IconArtworkPreview(image: renderedImage, shape: shape)
                    .frame(maxWidth: .infinity)
                    .frame(height: 245)
                    .accessibilityLabel("Icon artwork preview")
                HStack(spacing: 8) {
                    ForEach(IconStudioShape.allCases) { candidate in
                        Button {
                            shape = candidate
                            RoyalHaptics.selection()
                        } label: {
                            Image(systemName: candidate.symbol)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .foregroundStyle(shape == candidate ? RoyalPalette.midnight : .primary)
                                .background(shape == candidate ? AnyShapeStyle(RoyalPalette.goldGradient) : AnyShapeStyle(.thinMaterial), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(candidate.title)
                    }
                }
            }
        }
    }

    private var importAndActions: some View {
        HStack(spacing: 12) {
            Button { isImporterPresented = true } label: {
                Label("Import PNG / WebP", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(RoyalButtonStyle())

            Button { restoreOriginalDraft() } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.headline)
                    .frame(width: 48, height: 48)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Restore original design")
        }
    }

    private var editorControls: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                RoyalSectionHeader("Finish", subtitle: "All effects are rendered on-device before export.")
                VStack(alignment: .leading, spacing: 5) {
                    HStack { Text("Artwork scale"); Spacer(); Text(iconScale, format: .percent.precision(.fractionLength(0))) }
                        .font(.subheadline)
                    Slider(value: $iconScale, in: 0.45...1.15, step: 0.01).tint(RoyalPalette.gold)
                }
                Picker("Signature effect", selection: $effect) {
                    ForEach(IconStudioEffect.allCases) { option in Label(option.title, systemImage: option.symbol).tag(option) }
                }
                .pickerStyle(.menu)

                if BackgroundRemovalService.isAvailable {
                    Button { removeBackground() } label: {
                        Label(isRemovingBackground ? "Removing background…" : "Remove background locally", systemImage: "person.crop.rectangle")
                    }
                    .disabled(sourceImage == nil || isRemovingBackground)
                    .buttonStyle(.bordered)
                    .tint(RoyalPalette.gold)
                } else {
                    Label("Local background removal requires iOS 17 or later.", systemImage: "info.circle")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var drawingControls: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    RoyalSectionHeader("Draw details", subtitle: "Drawn strokes stay with this artwork draft.")
                    Spacer()
                    Toggle("Draw", isOn: $drawingEnabled).labelsHidden().tint(RoyalPalette.gold)
                }
                ColorPicker("Ink", selection: $selectedInk, supportsOpacity: true)
                HStack {
                    Button(role: .destructive) { strokes.removeAll() } label: { Label("Clear strokes", systemImage: "eraser") }
                        .disabled(strokes.isEmpty)
                    Spacer()
                    Text(drawingEnabled ? "Draw on the canvas" : "Turn on Draw to add detail")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                IconDrawingCanvas(strokes: $strokes, ink: selectedInk, isEnabled: drawingEnabled)
                    .frame(height: drawingEnabled ? 220 : 0)
                    .opacity(drawingEnabled ? 1 : 0)
                    .clipped()
                    .animation(.snappy, value: drawingEnabled)
            }
        }
    }

    @ViewBuilder
    private var exportSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                RoyalSectionHeader("Save & export", subtitle: "Packages live only on this device until you share them.")
                Button { saveArtwork() } label: { Label("Save icon collection", systemImage: "square.and.arrow.down.on.square") }
                    .buttonStyle(RoyalButtonStyle())
                    .disabled(renderedImage == nil)

                if let savedArtwork {
                    ShareLink(item: savedArtwork.fileURL, preview: SharePreview("GG icon artwork", image: Image(uiImage: savedArtwork.preview))) {
                        Label("Export PNG", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(RoyalPalette.amethyst)
                } else {
                    Text("Save the artwork to enable a system share sheet export.").font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func importImage(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let secured = url.startAccessingSecurityScopedResource()
            defer { if secured { url.stopAccessingSecurityScopedResource() } }
            guard let image = UIImage(data: try Data(contentsOf: url)) else { throw IconStudioError.unreadableImage }
            sourceImage = image
            savedArtwork = nil
            RoyalHaptics.success()
        } catch { alertMessage = error.localizedDescription }
    }

    private func restoreOriginalDraft() {
        sourceImage = nil; iconScale = 0.88; shape = .rounded; effect = .glass; strokes.removeAll(); savedArtwork = nil
        RoyalHaptics.selection()
    }

    private func removeBackground() {
        guard let sourceImage else { return }
        isRemovingBackground = true
        Task.detached(priority: .userInitiated) {
            do {
                let result = try BackgroundRemovalService.removeBackground(from: sourceImage)
                await MainActor.run {
                    self.sourceImage = result; self.isRemovingBackground = false; self.savedArtwork = nil; RoyalHaptics.success()
                }
            } catch {
                await MainActor.run {
                    self.isRemovingBackground = false
                    self.alertMessage = "This image could not be separated locally. Try a clear foreground subject."
                    RoyalHaptics.error()
                }
            }
        }
    }

    private func saveArtwork() {
        guard let renderedImage else { return }
        do { savedArtwork = try IconArtworkLibrary.save(renderedImage); RoyalHaptics.success() }
        catch { alertMessage = "The icon could not be saved: \(error.localizedDescription)" }
    }
}

private struct IconArtworkPreview: View {
    let image: UIImage?
    let shape: IconStudioShape
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous).fill(.black.opacity(0.22))
            if let image {
                Image(uiImage: image).resizable().scaledToFit().frame(width: 190, height: 190)
                    .clipShape(shape.previewShape).shadow(color: .black.opacity(0.45), radius: 15, y: 10)
            } else {
                VStack(spacing: 9) {
                    Image(systemName: "photo.badge.plus").font(.system(size: 45))
                    Text("Import artwork to begin").font(.subheadline.weight(.semibold))
                }.foregroundStyle(.secondary)
            }
        }
    }
}

private enum IconStudioShape: String, CaseIterable, Identifiable {
    case rounded, circle, square
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var symbol: String { switch self { case .rounded: return "app.fill"; case .circle: return "circle.fill"; case .square: return "square.fill" } }
    var previewShape: AnyShape {
        switch self {
        case .rounded: return AnyShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
        case .circle: return AnyShape(Circle())
        case .square: return AnyShape(Rectangle())
        }
    }
}

private enum IconStudioEffect: String, CaseIterable, Identifiable {
    case none, glass, gold, neon, dimensional
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self { case .none: return "circle"; case .glass: return "sparkles"; case .gold: return "crown.fill"; case .neon: return "bolt.fill"; case .dimensional: return "cube.fill" }
    }
}

private struct IconPoint: Codable, Hashable { let x: CGFloat; let y: CGFloat }
private struct IconStroke: Codable, Identifiable, Hashable { let id: UUID; var points: [IconPoint]; let colorHex: String; let lineWidth: CGFloat }

private struct IconDrawingCanvas: View {
    @Binding var strokes: [IconStroke]
    let ink: Color
    let isEnabled: Bool
    @State private var activeStrokeID: UUID?
    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                for stroke in strokes {
                    guard let first = stroke.points.first else { continue }
                    var path = Path(); path.move(to: CGPoint(x: first.x * size.width, y: first.y * size.height))
                    for point in stroke.points.dropFirst() { path.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height)) }
                    context.stroke(path, with: .color(Color(uiColor: UIColor(hex: stroke.colorHex))), lineWidth: stroke.lineWidth)
                }
            }
            .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.white.opacity(0.16)) }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { append($0.location, in: proxy.size) }.onEnded { _ in activeStrokeID = nil })
        }
        .allowsHitTesting(isEnabled).accessibilityLabel("Drawing canvas")
    }
    private func append(_ location: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let point = IconPoint(x: min(max(location.x / size.width, 0), 1), y: min(max(location.y / size.height, 0), 1))
        if let activeStrokeID, let index = strokes.firstIndex(where: { $0.id == activeStrokeID }) { strokes[index].points.append(point) }
        else {
            let id = UUID()
            strokes.append(IconStroke(id: id, points: [point], colorHex: UIColor(ink).hex, lineWidth: 5)); activeStrokeID = id
        }
    }
}

private enum IconArtworkRenderer {
    static func render(source: UIImage?, scale: Double, shape: IconStudioShape, effect: IconStudioEffect, strokes: [IconStroke]) -> UIImage? {
        guard let source else { return nil }
        let size = CGSize(width: 1024, height: 1024)
        let format = UIGraphicsImageRendererFormat.default(); format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { rendererContext in
            let context = rendererContext.cgContext; let iconRect = CGRect(origin: .zero, size: size)
            context.saveGState(); applyClip(shape: shape, rect: iconRect, context: context)
            UIColor.black.withAlphaComponent(0.30).setFill(); context.fill(iconRect)
            let aspect = source.size.width / max(source.size.height, 1); let base = max(size.width, size.height) * scale
            let drawSize = aspect >= 1 ? CGSize(width: base * aspect, height: base) : CGSize(width: base, height: base / aspect)
            source.draw(in: CGRect(x: (size.width - drawSize.width) / 2, y: (size.height - drawSize.height) / 2, width: drawSize.width, height: drawSize.height))
            drawEffect(effect, in: iconRect, context: context); drawStrokes(strokes, size: size, context: context); context.restoreGState()
        }
    }
    private static func applyClip(shape: IconStudioShape, rect: CGRect, context: CGContext) {
        switch shape { case .rounded: context.addPath(UIBezierPath(roundedRect: rect, cornerRadius: 205).cgPath); case .circle: context.addEllipse(in: rect); case .square: context.addRect(rect) }; context.clip()
    }
    private static func drawEffect(_ effect: IconStudioEffect, in rect: CGRect, context: CGContext) {
        switch effect {
        case .none: break
        case .glass:
            let colors = [UIColor.white.withAlphaComponent(0.54).cgColor, UIColor.white.withAlphaComponent(0.03).cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.56])!
            context.drawLinearGradient(gradient, start: CGPoint(x: rect.midX, y: rect.minY), end: CGPoint(x: rect.midX, y: rect.maxY), options: [])
            UIColor.white.withAlphaComponent(0.22).setStroke(); context.setLineWidth(11); context.stroke(rect.insetBy(dx: 6, dy: 6))
        case .gold:
            UIColor(red: 0.95, green: 0.74, blue: 0.28, alpha: 0.32).setFill(); context.fill(rect)
            UIColor(red: 1, green: 0.93, blue: 0.68, alpha: 0.93).setStroke(); context.setLineWidth(18); context.stroke(rect.insetBy(dx: 9, dy: 9))
        case .neon:
            context.setShadow(offset: .zero, blur: 42, color: UIColor.systemPurple.withAlphaComponent(0.95).cgColor)
            UIColor.systemPurple.withAlphaComponent(0.45).setStroke(); context.setLineWidth(26); context.stroke(rect.insetBy(dx: 16, dy: 16)); context.setShadow(offset: .zero, blur: 0, color: nil)
        case .dimensional:
            let shade = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [UIColor.black.withAlphaComponent(0.50).cgColor, UIColor.clear.cgColor] as CFArray, locations: [0, 0.62])!
            context.drawLinearGradient(shade, start: CGPoint(x: rect.maxX, y: rect.maxY), end: CGPoint(x: rect.minX, y: rect.minY), options: [])
        }
    }
    private static func drawStrokes(_ strokes: [IconStroke], size: CGSize, context: CGContext) {
        context.setLineCap(.round); context.setLineJoin(.round)
        for stroke in strokes where stroke.points.count > 1 {
            guard let first = stroke.points.first else { continue }; context.beginPath(); context.move(to: CGPoint(x: first.x * size.width, y: first.y * size.height))
            for point in stroke.points.dropFirst() { context.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height)) }
            context.setStrokeColor(UIColor(hex: stroke.colorHex).cgColor); context.setLineWidth(stroke.lineWidth * 4); context.strokePath()
        }
    }
}

private struct SavedIconArtwork { let fileURL: URL; let preview: UIImage }
private enum IconArtworkLibrary {
    static func save(_ image: UIImage) throws -> SavedIconArtwork {
        let root = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("GGCustomizer/IconCollections", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let url = root.appendingPathComponent("GG-Icon-\(UUID().uuidString).png")
        guard let data = image.pngData() else { throw IconStudioError.unreadableImage }; try data.write(to: url, options: .atomic)
        return SavedIconArtwork(fileURL: url, preview: image)
    }
}
private enum IconStudioError: LocalizedError {
    case unreadableImage
    var errorDescription: String? {
        switch self { case .unreadableImage: return "GG Customizer could not read that image. Use a PNG or a WebP supported by your iPhone." }
    }
}
private extension UTType { static let webP = UTType(filenameExtension: "webp") ?? .image }
private extension UIColor {
    convenience init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted); var value: UInt64 = 0; Scanner(string: sanitized).scanHexInt64(&value)
        self.init(red: CGFloat((value >> 16) & 0xFF) / 255, green: CGFloat((value >> 8) & 0xFF) / 255, blue: CGFloat(value & 0xFF) / 255, alpha: 1)
    }
    var hex: String { var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0; getRed(&r, green: &g, blue: &b, alpha: &a); return String(format: "%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255))) }
}
