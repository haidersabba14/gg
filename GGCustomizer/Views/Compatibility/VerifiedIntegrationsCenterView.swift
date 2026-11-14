import SwiftUI
import UniformTypeIdentifiers

/// A review-first catalog for official Apple integrations and metadata-only
/// third-party descriptions. There is intentionally no exploit execution path.
struct VerifiedIntegrationsCenterView: View {
    @StateObject private var registry = VerifiedIntegrationRegistry()
    @State private var isImporting = false
    @State private var manifestPendingRemoval: VerifiedIntegrationManifest?

    private let appleIntegrations: [OfficialIntegration] = [
        .init("WidgetKit", "Apple", "GG Home and Lock Screen widgets that the user adds from the iOS gallery.", "checkmark.seal.fill", .supported),
        .init("ActivityKit", "Apple", "GG-only Live Activities for timers and task progress; iOS controls presentation.", "capsule.portrait.fill", .limited),
        .init("Theme package files", "GG Customizer", "Local .ggtheme JSON and ZIP import/export through the standard Files and share sheets.", "archivebox.fill", .supported),
        .init("Control Center", "Apple", "Uses Apple’s official control API only when the installed SDK and iOS version expose it.", "switch.2", .limited)
    ]

    var body: some View {
        List {
            Section {
                LimitDisclosureCard(
                    title: "Safe integration boundary",
                    message: "GG Customizer never downloads or executes exploits, jailbreak payloads, kernels, privilege-escalation chains, or tools that access protected system files. Imported manifests are documentation metadata only.",
                    icon: "lock.shield.fill"
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }

            Section("Official & app-scoped") {
                ForEach(appleIntegrations) { integration in
                    OfficialIntegrationRow(integration: integration)
                }
            }

            Section("Security compatibility") {
                DeviceCapabilityRowForIntegration(capability: SecurityCompatibilityEngine.protectedSystemAssessment())
                Text("For any external project, verify its upstream repository, release notes, device/version support, license, and source review yourself. A published advisory is not proof that it is safe or compatible with this device.")
                    .font(.footnote).foregroundStyle(.secondary)
            }

            Section("External tools — not integrated") {
                ExternalToolNotice(
                    name: "Erosion",
                    detail: "No documented stable API, manifest, or URL scheme was found for app-to-app integration. GG Customizer does not bundle, launch, download, or invoke it, and never grants an external tool access to GG data or system files.",
                    documentationURL: URL(string: "https://github.com/jailbreakdotparty/Erosion")!
                )
            }

            Section("Reviewed manifest metadata") {
                Button { isImporting = true } label: {
                    Label("Import verified integration manifest", systemImage: "doc.badge.plus")
                }
                Text("Accepted manifests can describe only local import/export, share, and documentation links. They cannot enable a system modification or run external code.")
                    .font(.footnote).foregroundStyle(.secondary)
                if registry.importedManifests.isEmpty {
                    Text("No third-party manifests have been imported.")
                        .font(.footnote).foregroundStyle(.secondary)
                } else {
                    ForEach(registry.importedManifests) { manifest in
                        ImportedManifestRow(manifest: manifest)
                            .swipeActions {
                                Button(role: .destructive) { manifestPendingRemoval = manifest } label: { Label("Remove", systemImage: "trash") }
                            }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(RoyalBackground())
        .navigationTitle("Verified Integrations")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.ggIntegrationManifest, .json], allowsMultipleSelection: false) { result in
            if case let .success(urls) = result, let url = urls.first { registry.importManifest(from: url) }
            if case let .failure(error) = result { registry.record(error: error) }
        }
        .confirmationDialog("Remove this manifest?", isPresented: Binding(get: { manifestPendingRemoval != nil }, set: { if !$0 { manifestPendingRemoval = nil } })) {
            Button("Remove", role: .destructive) {
                if let manifestPendingRemoval { registry.remove(id: manifestPendingRemoval.id) }
                manifestPendingRemoval = nil
            }
        }
        .alert("Integration review", isPresented: Binding(get: { registry.lastError != nil }, set: { if !$0 { registry.clearError() } })) {
            Button("OK", role: .cancel) { registry.clearError() }
        } message: { Text(registry.lastError ?? "") }
    }
}

private struct OfficialIntegration: Identifiable {
    let name: String
    let provider: String
    let detail: String
    let symbol: String
    let status: CapabilityStatus
    var id: String { name }

    init(_ name: String, _ provider: String, _ detail: String, _ symbol: String, _ status: CapabilityStatus) {
        self.name = name; self.provider = provider; self.detail = detail; self.symbol = symbol; self.status = status
    }
}

private struct OfficialIntegrationRow: View {
    let integration: OfficialIntegration
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: integration.symbol).foregroundStyle(RoyalPalette.gold).frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                HStack { Text(integration.name).font(.subheadline.weight(.semibold)); Spacer(); IntegrationStatusBadge(status: integration.status) }
                Text(integration.provider).font(.caption).foregroundStyle(.secondary)
                Text(integration.detail).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ImportedManifestRow: View {
    let manifest: VerifiedIntegrationManifest
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack { Text(manifest.name).font(.subheadline.weight(.semibold)); Spacer(); Text(manifest.provider).font(.caption).foregroundStyle(.secondary) }
            Text(manifest.notes).font(.footnote).foregroundStyle(.secondary)
            Text(manifest.capabilities.map(\.title).joined(separator: " · ")).font(.caption).foregroundStyle(RoyalPalette.gold)
            Link(destination: manifest.documentationURL) { Label("Open documentation", systemImage: "safari") }.font(.caption)
        }
        .padding(.vertical, 4)
    }
}

private struct ExternalToolNotice: View {
    let name: String
    let detail: String
    let documentationURL: URL

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name).font(.subheadline.weight(.semibold))
                Spacer()
                FeatureStatusBadge(status: .unsupported)
            }
            Text(detail).font(.footnote).foregroundStyle(.secondary)
            Label("Review only; no execution path in GG", systemImage: "lock.fill")
                .font(.caption).foregroundStyle(RoyalPalette.gold)
            Link(destination: documentationURL) { Label("Open upstream repository", systemImage: "safari") }
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

private struct DeviceCapabilityRowForIntegration: View {
    let capability: DeviceCapability
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack { Text(capability.title).font(.subheadline.weight(.semibold)); Spacer(); IntegrationStatusBadge(status: capability.status) }
            Text(capability.detail).font(.footnote).foregroundStyle(.secondary)
            if let requirement = capability.requirement { Text(requirement).font(.caption).foregroundStyle(.tertiary) }
        }
        .padding(.vertical, 4)
    }
}

private struct IntegrationStatusBadge: View {
    let status: CapabilityStatus
    var body: some View {
        switch status {
        case .supported: FeatureStatusBadge(status: .supported)
        case .limited: FeatureStatusBadge(status: .limited)
        case .unsupported: FeatureStatusBadge(status: .unsupported)
        }
    }
}

private extension UTType {
    static let ggIntegrationManifest = UTType(filenameExtension: "ggintegration") ?? .json
}
