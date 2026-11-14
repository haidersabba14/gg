import Combine
import Foundation

/// The only kinds of third-party handoff GG Customizer will describe or accept.
/// These actions are file/share-based and stay within public iOS APIs; none can
/// execute code, acquire privileges, access system files, or alter protected UI.
enum SafeIntegrationCapability: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case importThemePackage
    case exportThemePackage
    case importLayoutPlan
    case exportLayoutPlan
    case shareArtwork
    case openDocumentation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .importThemePackage: return "Import portable theme package"
        case .exportThemePackage: return "Export portable theme package"
        case .importLayoutPlan: return "Import local layout plan"
        case .exportLayoutPlan: return "Export local layout plan"
        case .shareArtwork: return "Share artwork with iOS"
        case .openDocumentation: return "Open public documentation"
        }
    }
}

struct VerifiedIntegrationManifest: Codable, Hashable, Identifiable, Sendable {
    static let formatIdentifier = "com.haidersabba14.ggcustomizer.integration-manifest"
    static let currentFormatVersion = 1

    var format: String
    var formatVersion: Int
    var id: String
    var name: String
    var provider: String
    var documentationURL: URL
    var capabilities: [SafeIntegrationCapability]
    var notes: String
    var reviewedAt: Date

    init(
        id: String,
        name: String,
        provider: String,
        documentationURL: URL,
        capabilities: [SafeIntegrationCapability],
        notes: String,
        reviewedAt: Date = .now
    ) {
        self.format = Self.formatIdentifier
        self.formatVersion = Self.currentFormatVersion
        self.id = id
        self.name = name
        self.provider = provider
        self.documentationURL = documentationURL
        self.capabilities = capabilities
        self.notes = notes
        self.reviewedAt = reviewedAt
    }
}

enum IntegrationManifestError: LocalizedError, Equatable {
    case fileTooLarge
    case invalidFormat
    case unsupportedFormat(Int)
    case invalidIdentifier
    case invalidName
    case untrustedURL
    case emptyCapabilities
    case unsafeCapability

    var errorDescription: String? {
        switch self {
        case .fileTooLarge: return "Integration manifests must be smaller than 256 KB."
        case .invalidFormat: return "This is not a GG Customizer integration manifest."
        case let .unsupportedFormat(version): return "This manifest uses unsupported format version \(version)."
        case .invalidIdentifier: return "The integration identifier is invalid."
        case .invalidName: return "The integration needs a short name and provider."
        case .untrustedURL: return "Only HTTPS documentation links are accepted."
        case .emptyCapabilities: return "A manifest must declare at least one safe file/share capability."
        case .unsafeCapability: return "This manifest requests an action outside GG Customizer’s safe file/share model."
        }
    }
}

enum IntegrationManifestValidator {
    static let maximumBytes = 262_144

    static func validate(_ manifest: VerifiedIntegrationManifest) throws -> VerifiedIntegrationManifest {
        guard manifest.format == VerifiedIntegrationManifest.formatIdentifier else { throw IntegrationManifestError.invalidFormat }
        guard manifest.formatVersion <= VerifiedIntegrationManifest.currentFormatVersion else {
            throw IntegrationManifestError.unsupportedFormat(manifest.formatVersion)
        }
        let validID = manifest.id.range(of: "^[A-Za-z0-9.-]{3,100}$", options: .regularExpression) != nil
        guard validID else { throw IntegrationManifestError.invalidIdentifier }
        guard !manifest.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !manifest.provider.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              manifest.name.count <= 80, manifest.provider.count <= 80 else {
            throw IntegrationManifestError.invalidName
        }
        guard manifest.documentationURL.scheme?.lowercased() == "https", manifest.documentationURL.host != nil else {
            throw IntegrationManifestError.untrustedURL
        }
        guard !manifest.capabilities.isEmpty else { throw IntegrationManifestError.emptyCapabilities }
        // Decoding into the closed enum above makes unknown/privileged requests fail before
        // this point. This explicit check documents that no execution capability exists.
        guard manifest.capabilities.allSatisfy({ SafeIntegrationCapability.allCases.contains($0) }) else {
            throw IntegrationManifestError.unsafeCapability
        }
        return manifest
    }
}

@MainActor
final class VerifiedIntegrationRegistry: ObservableObject {
    @Published private(set) var importedManifests: [VerifiedIntegrationManifest] = []
    @Published private(set) var lastError: String?

    private let fileManager: FileManager
    private let storageURL: URL

    init(fileManager: FileManager = .default, storageURL: URL? = nil) {
        self.fileManager = fileManager
        self.storageURL = storageURL ?? GGFileLocations.applicationSupportDirectory(fileManager: fileManager)
            .appendingPathComponent("verified-integrations.json")
        load()
    }

    /// Imports description-only metadata. It never downloads a payload, runs code,
    /// invokes an exploit, changes SpringBoard, or grants a tool elevated access.
    func importManifest(from sourceURL: URL) {
        let secured = sourceURL.startAccessingSecurityScopedResource()
        defer { if secured { sourceURL.stopAccessingSecurityScopedResource() } }
        do {
            let values = try sourceURL.resourceValues(forKeys: [.fileSizeKey])
            guard (values.fileSize ?? 0) <= IntegrationManifestValidator.maximumBytes else {
                throw IntegrationManifestError.fileTooLarge
            }
            let manifest = try JSONDecoder.ggIntegration.decode(VerifiedIntegrationManifest.self, from: Data(contentsOf: sourceURL))
            let validated = try IntegrationManifestValidator.validate(manifest)
            if let index = importedManifests.firstIndex(where: { $0.id == validated.id }) {
                importedManifests[index] = validated
            } else {
                importedManifests.append(validated)
            }
            importedManifests.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            persist()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func remove(id: String) {
        importedManifests.removeAll { $0.id == id }
        persist()
    }

    func record(error: Error) {
        lastError = error.localizedDescription
    }

    func clearError() {
        lastError = nil
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let saved = try? JSONDecoder.ggIntegration.decode([VerifiedIntegrationManifest].self, from: data) else { return }
        importedManifests = saved.compactMap { try? IntegrationManifestValidator.validate($0) }
    }

    private func persist() {
        do {
            try fileManager.createDirectory(at: storageURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder.ggIntegration.encode(importedManifests).write(to: storageURL, options: .atomic)
        } catch {
            lastError = "GG Customizer could not save the verified integration list."
        }
    }
}

/// A deliberately conservative assessment: the application has no exploit runner,
/// privilege-escalation module, or system-file access path. This is a safety boundary,
/// not a claim that an external vulnerability is applicable to a device.
enum SecurityCompatibilityEngine {
    static func protectedSystemAssessment() -> DeviceCapability {
        DeviceCapability(
            capability: .otherAppIconReplacement,
            status: .unsupported,
            title: "Privileged system customization",
            detail: "Disabled by design. GG Customizer does not execute exploits, request elevated privileges, or modify protected system files. Use only the app-scoped and Apple-documented integrations shown here.",
            requirement: "No documented public iOS API permits changing other apps’ icons, the system passcode keypad, or the Phone app UI."
        )
    }
}

private extension JSONEncoder {
    static var ggIntegration: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var ggIntegration: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
