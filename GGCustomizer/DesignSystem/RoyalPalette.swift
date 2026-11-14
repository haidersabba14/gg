import SwiftUI

/// Shared visual language for GG Customizer. All colors are local and dynamic-type friendly.
enum RoyalPalette {
    static let midnight = Color(red: 0.035, green: 0.043, blue: 0.090)
    static let ink = Color(red: 0.075, green: 0.082, blue: 0.145)
    static let gold = Color(red: 0.93, green: 0.71, blue: 0.25)
    static let champagne = Color(red: 1.00, green: 0.91, blue: 0.68)
    static let amethyst = Color(red: 0.55, green: 0.30, blue: 0.94)
    static let sapphire = Color(red: 0.16, green: 0.56, blue: 0.98)
    static let emerald = Color(red: 0.18, green: 0.78, blue: 0.58)
    static let danger = Color(red: 0.95, green: 0.27, blue: 0.34)

    static var royalGradient: LinearGradient {
        LinearGradient(
            colors: [midnight, ink, amethyst.opacity(0.78)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var goldGradient: LinearGradient {
        LinearGradient(colors: [champagne, gold, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct RoyalBackground: View {
    var body: some View {
        ZStack {
            RoyalPalette.royalGradient
            Circle()
                .fill(RoyalPalette.amethyst.opacity(0.24))
                .frame(width: 330, height: 330)
                .blur(radius: 40)
                .offset(x: 160, y: -290)
            Circle()
                .fill(RoyalPalette.gold.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 46)
                .offset(x: -145, y: 310)
        }
        .ignoresSafeArea()
    }
}

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.22), radius: 18, y: 10)
    }
}

struct GoldCapsule: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.bold))
            .foregroundStyle(RoyalPalette.midnight)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(RoyalPalette.goldGradient, in: Capsule())
    }
}

extension View {
    func goldCapsule() -> some View { modifier(GoldCapsule()) }
}

struct FeatureStatusBadge: View {
    enum Status {
        case supported, limited, unsupported

        var text: String {
            switch self {
            case .supported: return String(localized: "Supported")
            case .limited: return String(localized: "Limited")
            case .unsupported: return String(localized: "Unsupported")
            }
        }

        var symbol: String {
            switch self {
            case .supported: return "checkmark.seal.fill"
            case .limited: return "exclamationmark.triangle.fill"
            case .unsupported: return "xmark.octagon.fill"
            }
        }

        var color: Color {
            switch self {
            case .supported: return RoyalPalette.emerald
            case .limited: return RoyalPalette.gold
            case .unsupported: return RoyalPalette.danger
            }
        }
    }

    let status: Status

    var body: some View {
        Label(status.text, systemImage: status.symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(status.color)
            .accessibilityLabel("\(status.text)")
    }
}
