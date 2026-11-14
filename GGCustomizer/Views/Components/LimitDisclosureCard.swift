import SwiftUI

struct LimitDisclosureCard: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    var icon = "lock.shield.fill"

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(RoyalPalette.gold)
                .font(.title3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.subheadline.bold())
                Text(message).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(RoyalPalette.gold.opacity(0.11), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(RoyalPalette.gold.opacity(0.32), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
