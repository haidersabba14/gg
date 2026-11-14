import Foundation
import ZIPFoundation

/// Portable, app-scoped files used by GG Customizer. These documents never contain a
/// device passcode, Photos-library content, system settings, certificates, or credentials.
struct GGThemePackageDocument: Codable, Sendable {
    static let formatIdentifier = "com.haidersabba14.ggcustomizer.theme"
    static let currentFormatVersion = 1

    let format: String
    let formatVersion: Int
    let exportedAt: Date
    let theme: ThemePackage

    init(theme: ThemePackage, exportedAt: Date = .now) {
        self.format = Self.formatIdentifier
        self.formatVersion = Self.currentFormatVersion
        self.exportedAt = exportedAt
        self.theme = theme
    }
}

/// A user-exported backup of GG-managed data. It is intentionally a backup artifact,
/// not an automatic way to overwrite an iPhone's system appearance or data.
struct GGRecoveryBackupDocument: Codable, Sendable {
    static let formatIdentifier = "com.haidersabba14.ggcustomizer.recovery"
    static let currentFormatVersion = 1

    let format: String
    let formatVersion: Int
    let exportedAt: Date
    let activeThemeID: UUID?
    let themes: [ThemePackage]
    let iconDesigns: [IconDesign]
    let passcodeDesigns: [PasscodeDesign]
    let homeLayouts: [HomeScreenLayout]
    let settings: AppSettings
    let profile: LocalProfile
    let history: [ThemeHistoryEntry]

    init(
        activeThemeID: UUID?,
        themes: [ThemePackage],
        iconDesigns: [IconDesign],
        passcodeDesigns: [PasscodeDesign],
        homeLayouts: [HomeScreenLayout],
        settings: AppSettings,
        profile: LocalProfile,
        history: [ThemeHistoryEntry],
        exportedAt: Date = .now
    ) {
        self.format = Self.formatIdentifier
        self.formatVersion = Self.currentFormatVersion
        self.exportedAt = exportedAt
        self.activeThemeID = activeThemeID
        self.themes = themes
        self.iconDesigns = iconDesigns
        self.passcodeDesigns = passcodeDesigns
        self.homeLayouts = homeLayouts
        self.settings = settings
        self.profile = profile
        self.history = history
    }
}

enum ThemeTransferError: LocalizedError, Equatable {
    case unsupportedFile
    case malformedPackage
    case unsupportedFormat(Int)
    case invalidTheme(String)
    case packageTooLarge
    case zipUnavailable
    case packageMissingFromArchive

    var errorDescription: String? {
        switch self {
        case .unsupportedFile:
            return "Choose a .ggtheme, .json, or .zip theme package."
        case .malformedPackage:
            return "This file is not a valid GG Customizer package."
        case let .unsupportedFormat(version):
            return "This package uses format version \(version), which this version of GG Customizer does not support."
        case let .invalidTheme(reason):
            return "This theme cannot be imported: \(reason)"
        case .packageTooLarge:
            return "This package is too large for a local GG theme document."
        case .zipUnavailable:
            return "ZIP package support is unavailable in this build. Try importing the .ggtheme file instead."
        case .packageMissingFromArchive:
            return "No .ggtheme or .json package was found in this ZIP archive."
        }
    }
}

/// Imports and exports are intentionally local: callers present the system share/file UI,
/// while this service only reads or creates files inside app-controlled locations.
enum ThemeTransferService {
    static let themeFileExtension = "ggtheme"
    static let recoveryFileExtension = "ggrecovery"
    static let maximumDocumentBytes = 1_048_576 // 1 MiB: theme settings should be compact JSON.

    // MARK: Theme packages

    static func exportTheme(_ theme: ThemePackage, fileManager: FileManager = .default) throws -> URL {
        let document = GGThemePackageDocument(theme: theme)
        let data = try makeEncoder().encode(document)
        let destination = try nextExportURL(
            basename: sanitizedFilename(theme.name, fallback: "GG-Theme"),
            fileExtension: themeFileExtension,
            fileManager: fileManager
        )
        try data.write(to: destination, options: .atomic)
        return destination
    }

    /// Produces a standard ZIP archive containing one portable `.ggtheme` JSON document.
    /// ZIPFoundation is an audited MIT-licensed Swift Package; archive work is local and
    /// no file is uploaded to a service.
    static func exportThemeZIP(_ theme: ThemePackage, fileManager: FileManager = .default) throws -> URL {
        let data = try makeEncoder().encode(GGThemePackageDocument(theme: theme))
        let archiveURL = try nextExportURL(
            basename: sanitizedFilename(theme.name, fallback: "GG-Theme"),
            fileExtension: "zip",
            fileManager: fileManager
        )
        do {
            let archive = try Archive(url: archiveURL, accessMode: .create)
            try archive.addEntry(
                with: "theme.\(themeFileExtension)",
                type: .file,
                uncompressedSize: Int64(data.count),
                compressionMethod: .deflate,
                provider: { position, size in
                    let start = Int(position)
                    return data.subdata(in: start..<min(start + size, data.count))
                }
            )
            return archiveURL
        } catch {
            try? fileManager.removeItem(at: archiveURL)
            throw error
        }
    }

    /// Decodes a direct `.ggtheme`/`.json` file or a ZIP archive containing one.
    /// A security-scoped source is opened only for the duration of this call.
    static func importTheme(from sourceURL: URL, fileManager: FileManager = .default) throws -> ThemePackage {
        let isSecurityScoped = sourceURL.startAccessingSecurityScopedResource()
        defer { if isSecurityScoped { sourceURL.stopAccessingSecurityScopedResource() } }

        let documentData = try packageDocumentData(from: sourceURL, fileManager: fileManager)
        let document = try makeDecoder().decode(GGThemePackageDocument.self, from: documentData)
        return try validatedImportedTheme(from: document)
    }

    /// Inspects a recovery export without making any changes. Recovery imports need an
    /// explicit user-confirmed restore flow rather than silently replacing local state.
    static func inspectRecoveryBackup(from sourceURL: URL) throws -> GGRecoveryBackupDocument {
        let isSecurityScoped = sourceURL.startAccessingSecurityScopedResource()
        defer { if isSecurityScoped { sourceURL.stopAccessingSecurityScopedResource() } }
        try enforceSizeLimit(at: sourceURL)
        let document = try makeDecoder().decode(GGRecoveryBackupDocument.self, from: Data(contentsOf: sourceURL))
        guard document.format == GGRecoveryBackupDocument.formatIdentifier else { throw ThemeTransferError.malformedPackage }
        guard document.formatVersion <= GGRecoveryBackupDocument.currentFormatVersion else {
            throw ThemeTransferError.unsupportedFormat(document.formatVersion)
        }
        return document
    }

    // MARK: Recovery export

    static func exportRecoveryBackup(
        activeThemeID: UUID?,
        themes: [ThemePackage],
        iconDesigns: [IconDesign],
        passcodeDesigns: [PasscodeDesign],
        homeLayouts: [HomeScreenLayout],
        settings: AppSettings,
        profile: LocalProfile,
        history: [ThemeHistoryEntry],
        fileManager: FileManager = .default
    ) throws -> URL {
        let document = GGRecoveryBackupDocument(
            activeThemeID: activeThemeID,
            themes: themes,
            iconDesigns: iconDesigns,
            passcodeDesigns: passcodeDesigns,
            homeLayouts: homeLayouts,
            settings: settings,
            profile: profile,
            history: history
        )
        let data = try makeEncoder().encode(document)
        let destination = try nextExportURL(
            basename: "GG-Recovery-\(Int(Date().timeIntervalSince1970))",
            fileExtension: recoveryFileExtension,
            fileManager: fileManager
        )
        try data.write(to: destination, options: .atomic)
        return destination
    }

    // MARK: Internal validation and files

    private static func packageDocumentData(from sourceURL: URL, fileManager: FileManager) throws -> Data {
        let extensionName = sourceURL.pathExtension.lowercased()
        guard [themeFileExtension, "json", "zip"].contains(extensionName) else { throw ThemeTransferError.unsupportedFile }
        guard extensionName == "zip" else {
            try enforceSizeLimit(at: sourceURL, fileManager: fileManager)
            return try Data(contentsOf: sourceURL)
        }

        let archive = try Archive(url: sourceURL, accessMode: .read)
        let candidates = archive.filter { entry in
            let parts = entry.path.split(separator: "/")
            let safePath = !entry.path.hasPrefix("/") && !parts.contains("..")
            let validExtension = [themeFileExtension, "json"].contains(URL(fileURLWithPath: entry.path).pathExtension.lowercased())
            return entry.type == .file && safePath && validExtension && entry.uncompressedSize <= UInt64(maximumDocumentBytes)
        }
        guard let candidate = candidates.sorted(by: { $0.path < $1.path }).first else {
            throw ThemeTransferError.packageMissingFromArchive
        }

        var data = Data()
        try archive.extract(candidate) { chunk in
            guard data.count <= maximumDocumentBytes - chunk.count else { throw ThemeTransferError.packageTooLarge }
            data.append(chunk)
        }
        return data
    }

    private static func validatedImportedTheme(from document: GGThemePackageDocument) throws -> ThemePackage {
        guard document.format == GGThemePackageDocument.formatIdentifier else { throw ThemeTransferError.malformedPackage }
        guard document.formatVersion <= GGThemePackageDocument.currentFormatVersion else {
            throw ThemeTransferError.unsupportedFormat(document.formatVersion)
        }
        guard document.theme.schemaVersion <= ThemePackage.currentSchemaVersion else {
            throw ThemeTransferError.unsupportedFormat(document.theme.schemaVersion)
        }
        let trimmedName = document.theme.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw ThemeTransferError.invalidTheme("a name is required") }
        guard trimmedName.count <= 80 else { throw ThemeTransferError.invalidTheme("the name is too long") }
        guard document.theme.palette.allHexValues.allSatisfy(isRawHexColor) else {
            throw ThemeTransferError.invalidTheme("one or more color values are invalid")
        }

        var imported = document.theme
        // A shared file can never turn into a protected built-in catalog record.
        imported.isBuiltIn = false
        imported.name = trimmedName
        imported.localRating = min(max(imported.localRating, 0), 5)
        imported.updatedAt = .now
        return imported
    }

    private static func isRawHexColor(_ value: String) -> Bool {
        let stripped = value.hasPrefix("#") ? String(value.dropFirst()) : value
        return (stripped.count == 6 || stripped.count == 8) && stripped.allSatisfy { $0.isHexDigit }
    }

    private static func enforceSizeLimit(at url: URL, fileManager: FileManager = .default) throws {
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        if size > maximumDocumentBytes { throw ThemeTransferError.packageTooLarge }
    }

    private static func nextExportURL(basename: String, fileExtension: String, fileManager: FileManager) throws -> URL {
        let directory = GGFileLocations.exportsDirectory(fileManager: fileManager)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let stem = sanitizedFilename(basename, fallback: "GG-Export")
        var candidate = directory.appendingPathComponent(stem).appendingPathExtension(fileExtension)
        var index = 2
        while fileManager.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(stem)-\(index)").appendingPathExtension(fileExtension)
            index += 1
        }
        return candidate
    }

    private static func sanitizedFilename(_ input: String, fallback: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ "))
        let cleaned = input.unicodeScalars.map { allowed.contains($0) ? Character(String($0)) : Character("-") }
        let result = String(cleaned).trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? fallback : String(result.prefix(72))
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

@MainActor
extension ThemeStore {
    /// Imports a theme into GG Customizer's local store. This updates only app-owned
    /// settings and preserves the current iOS Home Screen, wallpaper, and other apps.
    @discardableResult
    func importThemePackage(from url: URL) throws -> ThemePackage {
        var theme = try ThemeTransferService.importTheme(from: url)
        // Avoid allowing a shared custom package to overwrite a bundled catalog entry.
        if themes.contains(where: { $0.id == theme.id && $0.isBuiltIn }) {
            theme.id = UUID()
        }
        upsert(theme: theme)
        return theme
    }

    func exportThemePackage(themeID: UUID) throws -> URL {
        guard let theme = themes.first(where: { $0.id == themeID }) else {
            throw ThemeTransferError.invalidTheme("the selected theme no longer exists")
        }
        return try ThemeTransferService.exportTheme(theme)
    }

    func exportThemeZIP(themeID: UUID) throws -> URL {
        guard let theme = themes.first(where: { $0.id == themeID }) else {
            throw ThemeTransferError.invalidTheme("the selected theme no longer exists")
        }
        return try ThemeTransferService.exportThemeZIP(theme)
    }

    func exportRecoveryBackup() throws -> URL {
        try ThemeTransferService.exportRecoveryBackup(
            activeThemeID: activeThemeID,
            themes: themes,
            iconDesigns: iconDesigns,
            passcodeDesigns: passcodeDesigns,
            homeLayouts: homeLayouts,
            settings: settings,
            profile: profile,
            history: history
        )
    }
}
