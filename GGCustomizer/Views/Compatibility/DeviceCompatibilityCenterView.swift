import SwiftUI
import UIKit

/// Shows only capabilities available through public Apple APIs at the current runtime.
struct DeviceCompatibilityCenterView: View {
    @State private var snapshot = DeviceCompatibilityService.snapshot()
    @State private var capabilities = DeviceCompatibilityService.capabilities()

    var body: some View {
        List {
            Section {
                LimitDisclosureCard(
                    title: "Public iOS capability report",
                    message: "GG Customizer does not scan for jailbreaks, private APIs, exploits, or unknown future system behavior. Statuses reflect public Apple APIs on this device.",
                    icon: "checkmark.shield.fill"
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }

            Section("This device") {
                CompatibilityValueRow(title: "System", value: "\(snapshot.systemName) \(snapshot.systemVersion)", symbol: "iphone")
                CompatibilityValueRow(title: "Device class", value: snapshot.deviceClass, symbol: "rectangle.on.rectangle")
                CompatibilityValueRow(title: "Dynamic Type", value: snapshot.supportsDynamicType ? "Supported" : "Unavailable", symbol: "textformat.size")
            }

            Section("Permission status") {
                CompatibilityValueRow(title: "Photos export", value: snapshot.photoAuthorization, symbol: "photo")
                CompatibilityValueRow(title: "Location / weather", value: snapshot.locationAuthorization, symbol: "location")
                CompatibilityValueRow(title: "Calendar widget", value: snapshot.calendarAuthorization, symbol: "calendar")
                Button {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                } label: {
                    Label("Open GG Settings", systemImage: "gear")
                }
            }

            capabilitySection(title: "Supported", status: .supported)
            capabilitySection(title: "Limited", status: .limited)
            capabilitySection(title: "Unsupported by iOS", status: .unsupported)
        }
        .scrollContentBackground(.hidden)
        .background(RoyalBackground())
        .navigationTitle("Compatibility Center")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { refresh() } label: { Image(systemName: "arrow.clockwise") }
                    .accessibilityLabel("Refresh compatibility")
            }
        }
        .refreshable { refresh() }
    }

    @ViewBuilder
    private func capabilitySection(title: String, status: CapabilityStatus) -> some View {
        let matching = capabilities.filter { $0.status == status }
        if !matching.isEmpty {
            Section(title) {
                ForEach(matching) { capability in
                    DeviceCapabilityRow(capability: capability)
                }
            }
        }
    }

    private func refresh() {
        snapshot = DeviceCompatibilityService.snapshot()
        capabilities = DeviceCompatibilityService.capabilities()
    }
}

private struct CompatibilityValueRow: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).foregroundStyle(RoyalPalette.gold).frame(width: 22)
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

private struct DeviceCapabilityRow: View {
    let capability: DeviceCapability

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(capability.title).font(.subheadline.weight(.semibold))
                Spacer()
                FeatureStatusBadge(status: badgeStatus)
            }
            Text(capability.detail).font(.footnote).foregroundStyle(.secondary)
            if let requirement = capability.requirement {
                Label(requirement, systemImage: "info.circle")
                    .font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var badgeStatus: FeatureStatusBadge.Status {
        switch capability.status {
        case .supported: return .supported
        case .limited: return .limited
        case .unsupported: return .unsupported
        }
    }
}
