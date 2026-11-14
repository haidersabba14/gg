import Foundation
import UIKit

enum ThemeEngine {
    static func color(from hex: String, alpha: CGFloat = 1) -> UIColor {
        let cleaned = ThemePalette.normalizedHex(hex).dropFirst()
        let value = UInt64(cleaned, radix: 16) ?? 0x6E5BFF
        let red = CGFloat((value >> 16) & 0xFF) / 255
        let green = CGFloat((value >> 8) & 0xFF) / 255
        let blue = CGFloat(value & 0xFF) / 255
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    static func hex(from color: UIColor) -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return "#6E5BFF" }
        return String(format: "#%02X%02X%02X", Int((red * 255).rounded()), Int((green * 255).rounded()), Int((blue * 255).rounded()))
    }

    /// Extracts a dominant average from an image entirely on device. It deliberately samples
    /// a small bitmap to avoid retaining or uploading the user's original image.
    static func palette(from image: UIImage) -> ThemePalette? {
        guard let cgImage = image.cgImage else { return nil }
        let side = 32
        var bytes = [UInt8](repeating: 0, count: side * side * 4)
        guard let context = CGContext(
            data: &bytes,
            width: side,
            height: side,
            bitsPerComponent: 8,
            bytesPerRow: side * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))

        var red = 0.0
        var green = 0.0
        var blue = 0.0
        var total = 0.0
        for index in stride(from: 0, to: bytes.count, by: 4) {
            let alpha = Double(bytes[index + 3]) / 255
            guard alpha > 0.08 else { continue }
            red += Double(bytes[index]) * alpha
            green += Double(bytes[index + 1]) * alpha
            blue += Double(bytes[index + 2]) * alpha
            total += alpha
        }
        guard total > 0 else { return nil }

        let base = UIColor(
            red: CGFloat(red / total / 255),
            green: CGFloat(green / total / 255),
            blue: CGFloat(blue / total / 255),
            alpha: 1
        )
        return palette(from: base)
    }

    static func palette(from base: UIColor) -> ThemePalette {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        guard base.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return ThemePalette(primary: "#6E5BFF", secondary: "#A092FF", accent: "#F3C96A", background: "#0B0C19", surface: "#1C1E38", text: "#FFFFFF")
        }

        func make(_ hueOffset: CGFloat, _ sat: CGFloat, _ light: CGFloat) -> String {
            let adjustedHue = (hue + hueOffset).truncatingRemainder(dividingBy: 1)
            return hex(from: UIColor(hue: adjustedHue < 0 ? adjustedHue + 1 : adjustedHue, saturation: min(max(sat, 0.18), 1), brightness: min(max(light, 0.1), 1), alpha: 1))
        }

        return ThemePalette(
            primary: make(0, max(saturation, 0.55), max(brightness, 0.55)),
            secondary: make(0.08, max(saturation * 0.58, 0.3), min(brightness + 0.24, 0.96)),
            accent: make(0.5, max(saturation, 0.5), min(max(brightness, 0.7), 0.98)),
            background: make(0, min(saturation * 0.7, 0.8), 0.09),
            surface: make(0.02, min(saturation * 0.65, 0.85), 0.20),
            text: brightness > 0.64 ? "#111118" : "#F9FAFF"
        )
    }

    static func suggestedPalettes(from image: UIImage) -> [ThemePalette] {
        guard let base = palette(from: image) else { return [] }
        let primary = color(from: base.primary)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        guard primary.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else { return [base] }
        return [
            base,
            palette(from: UIColor(hue: (hue + 0.14).truncatingRemainder(dividingBy: 1), saturation: max(saturation, 0.62), brightness: max(brightness, 0.63), alpha: 1)),
            palette(from: UIColor(hue: (hue + 0.5).truncatingRemainder(dividingBy: 1), saturation: max(saturation, 0.58), brightness: max(brightness, 0.58), alpha: 1))
        ]
    }

    static func randomTheme() -> ThemePackage {
        let primary = UIColor(
            hue: CGFloat.random(in: 0 ... 1),
            saturation: CGFloat.random(in: 0.58 ... 0.92),
            brightness: CGFloat.random(in: 0.64 ... 0.98),
            alpha: 1
        )
        let palette = palette(from: primary)
        let names = ["Aurora", "Velvet", "Prism", "Nova", "Orbit", "Crown", "Solstice", "Mirage"]
        let descriptors = ["Edition", "Pulse", "Glass", "Night", "Spectrum", "Signature"]
        return ThemePackage(
            name: "\(names.randomElement() ?? "Nova") \(descriptors.randomElement() ?? "Edition")",
            subtitle: "Generated on this device",
            summary: "A locally generated palette. Review it before applying in GG Customizer.",
            palette: palette,
            iconTreatment: IconTreatment.allCases.randomElement() ?? .glass,
            wallpaperTreatment: WallpaperTreatment.allCases.randomElement() ?? .gradient,
            tags: ["local", "generated"]
        )
    }

    static func isValid(hex: String) -> Bool {
        let normalized = ThemePalette.normalizedHex(hex)
        return normalized.count == 7 || normalized.count == 9
    }
}
