import SwiftUI

struct RoyalButtonStyle: ButtonStyle {
    var isDestructive = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isDestructive ? .white : RoyalPalette.midnight)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                if isDestructive {
                    Capsule().fill(RoyalPalette.danger)
                } else {
                    Capsule().fill(RoyalPalette.goldGradient)
                }
            }
            .opacity(configuration.isPressed ? 0.74 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

struct RoyalSectionHeader: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?

    init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.title3.bold()).foregroundStyle(.primary)
            if let subtitle { Text(subtitle).font(.footnote).foregroundStyle(.secondary) }
        }
        .accessibilityElement(children: .combine)
    }
}
