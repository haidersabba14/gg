import Foundation

// MARK: - Theme package

/// A portable, local-only theme. A theme changes GG Customizer and its widgets;
/// it never represents a modification to SpringBoard or another app.
struct ThemePackage: Identifiable, Codable, Hashable, Sendable {
    static let currentSchemaVersion = 1

    var id: UUID
    var schemaVersion: Int
    var name: String
    var subtitle: String
    var summary: String
    var palette: ThemePalette
    var iconTreatment: IconTreatment
    var wallpaperTreatment: WallpaperTreatment
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    var isBuiltIn: Bool
    var isFavorite: Bool
    var localRating: Int

    init(
        id: UUID = UUID(),
        schemaVersion: Int = ThemePackage.currentSchemaVersion,
        name: String,
        subtitle: String,
        summary: String,
        palette: ThemePalette,
        iconTreatment: IconTreatment = .glass,
        wallpaperTreatment: WallpaperTreatment = .gradient,
        tags: [String] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isBuiltIn: Bool = false,
        isFavorite: Bool = false,
        localRating: Int = 0
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.name = name
        self.subtitle = subtitle
        self.summary = summary
        self.palette = palette
        self.iconTreatment = iconTreatment
        self.wallpaperTreatment = wallpaperTreatment
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isBuiltIn = isBuiltIn
        self.isFavorite = isFavorite
        self.localRating = min(max(localRating, 0), 5)
    }

    var searchIndex: String {
        ([name, subtitle, summary] + tags).joined(separator: " ").folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    func matches(_ query: String) -> Bool {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty || searchIndex.localizedCaseInsensitiveContains(normalized)
    }

    mutating func touch() {
        updatedAt = .now
    }
}

struct ThemePalette: Codable, Hashable, Sendable {
    /// `#RRGGBB` values are deliberate: portable themes do not serialize UIKit or SwiftUI types.
    var primary: String
    var secondary: String
    var accent: String
    var background: String
    var surface: String
    var text: String

    init(primary: String, secondary: String, accent: String, background: String, surface: String, text: String) {
        self.primary = ThemePalette.normalizedHex(primary)
        self.secondary = ThemePalette.normalizedHex(secondary)
        self.accent = ThemePalette.normalizedHex(accent)
        self.background = ThemePalette.normalizedHex(background)
        self.surface = ThemePalette.normalizedHex(surface)
        self.text = ThemePalette.normalizedHex(text)
    }

    static func normalizedHex(_ input: String) -> String {
        let allowed = input.uppercased().filter { $0.isHexDigit }
        if allowed.count == 3 {
            let expanded = allowed.map { "\($0)\($0)" }.joined()
            return "#\(expanded)"
        }
        guard allowed.count == 6 || allowed.count == 8 else { return "#6E5BFF" }
        return "#\(allowed)"
    }

    var allHexValues: [String] { [primary, secondary, accent, background, surface, text] }
}

enum IconTreatment: String, Codable, CaseIterable, Identifiable, Sendable {
    case glass
    case gold
    case neon
    case chrome
    case carbon
    case crystal

    var id: String { rawValue }
}

enum WallpaperTreatment: String, Codable, CaseIterable, Identifiable, Sendable {
    case gradient
    case frostedGlass
    case galaxy
    case carbon
    case liquid
    case solid

    var id: String { rawValue }
}

enum ThemeApplicationScope: String, Codable, CaseIterable, Identifiable, Sendable {
    case ggCustomizer
    case ggWidgets
    case exportedPackage
    case systemPreview

    var id: String { rawValue }
}

// MARK: - Built-in catalog

extension ThemePackage {
    static var seedThemes: [ThemePackage] {
        let date = Date(timeIntervalSince1970: 1_735_689_600) // Stable previews and predictable test fixtures.
        return [
            seed("Royal Gold", "Crowned warmth", "Gold glass and midnight velvet.", ["#D7A92A", "#FFF2AE", "#E4C35A", "#100D08", "#251B09", "#FFF8E1"], .gold, .gradient, ["royal", "gold"], date),
            seed("Black Diamond", "Precision in darkness", "Charcoal facets with diamond highlights.", ["#22242B", "#737988", "#E6E9F0", "#050507", "#15161B", "#F8F9FC"], .crystal, .solid, ["black", "luxury"], date),
            seed("Cyberpunk 2077 Style", "Electric city", "Vivid cyan against nocturnal magenta.", ["#00E5FF", "#FF2AA1", "#FFE600", "#090714", "#19112A", "#F4F6FF"], .neon, .galaxy, ["cyberpunk", "neon"], date),
            seed("Liquid Glass Ultra", "Clear and luminous", "Soft translucent blues with a glass finish.", ["#84D7FF", "#D6F5FF", "#FFFFFF", "#112434", "#203B4D", "#F7FCFF"], .glass, .liquid, ["glass", "liquid"], date),
            seed("Titanium Pro", "Engineered restraint", "Cool titanium and clean silver contrast.", ["#8D98A7", "#CCD2DB", "#6DDBFF", "#111418", "#222831", "#F4F7FA"], .chrome, .solid, ["titanium", "pro"], date),
            seed("Neon Purple", "Ultraviolet pulse", "Purple energy over a deep OLED canvas.", ["#9E4DFF", "#E76DFF", "#50F5FF", "#0A0612", "#1E1031", "#F7F0FF"], .neon, .galaxy, ["purple", "neon"], date),
            seed("Red Carbon", "Velocity", "Carbon texture with high-performance red.", ["#E2373F", "#7E1119", "#FF8C8C", "#10090A", "#241315", "#FFF5F5"], .carbon, .carbon, ["red", "carbon"], date),
            seed("Luxury White", "Quiet confidence", "Pearl surfaces and champagne detail.", ["#D7C7A5", "#FFFFFF", "#8A7250", "#F4F0E9", "#FFFFFF", "#1F1C18"], .glass, .solid, ["white", "luxury"], date),
            seed("Space Black", "Deep orbit", "Black glass with a starlight accent.", ["#343943", "#78869B", "#B4D5FF", "#030407", "#10131A", "#F5F8FF"], .glass, .galaxy, ["space", "black"], date),
            seed("Blue Sapphire", "Faceted blue", "Sapphire light over polished navy.", ["#1677FF", "#45B3FF", "#A6E1FF", "#06152C", "#0D2C52", "#EFF8FF"], .crystal, .gradient, ["blue", "sapphire"], date),
            seed("Emerald Edition", "Living green", "Emerald depth and pale mint highlights.", ["#00A86B", "#37D6A0", "#B6FFD9", "#051A12", "#0C3224", "#EDFFF5"], .glass, .gradient, ["emerald", "green"], date),
            seed("Crystal Glass", "Prismatic clarity", "Iridescent glass over a calm blue-black base.", ["#B8D8FF", "#EAD7FF", "#FFFFFF", "#0C1320", "#1B2B40", "#F8FBFF"], .crystal, .frostedGlass, ["crystal", "glass"], date),
            seed("Midnight Pro", "After-hours focus", "Indigo shadows with crisp blue illumination.", ["#3347A9", "#627BFF", "#A9B8FF", "#070A1A", "#131A3A", "#F2F5FF"], .glass, .galaxy, ["midnight", "pro"], date),
            seed("Golden Dragon", "Imperial fire", "Dragon gold with restrained crimson energy.", ["#E4AA28", "#F4D576", "#C52D30", "#1A0D06", "#35200D", "#FFF6D5"], .gold, .gradient, ["gold", "dragon"], date),
            seed("Haider Signature", "Personal royalty", "A luminous royal blue signature palette.", ["#465BFF", "#8A7CFF", "#F1C85A", "#0A0C22", "#1B1D48", "#F7F7FF"], .glass, .liquid, ["haider", "signature"], date),
            seed("Frosted Glass", "Soft focus", "Cool mist, pearl and translucent ice.", ["#A9C8E8", "#E8F5FF", "#FFFFFF", "#15202B", "#294250", "#F6FBFF"], .glass, .frostedGlass, ["frosted", "glass"], date),
            seed("OLED Ultra Black", "Absolute black", "Pure black with an efficient blue signal.", ["#1E90FF", "#4DC6FF", "#FFFFFF", "#000000", "#0A0A0A", "#FFFFFF"], .neon, .solid, ["oled", "black"], date),
            seed("Silver Chrome", "Machined shine", "Chrome highlights over graphite metal.", ["#B3BAC5", "#EFF2F7", "#7C8CA5", "#0C0E12", "#20242B", "#FAFBFF"], .chrome, .solid, ["silver", "chrome"], date),
            seed("Dark Galaxy", "Beyond midnight", "A blue-violet nebula on a pitch-dark field.", ["#725CFF", "#C463FF", "#7EEAFF", "#05030D", "#17102B", "#F9F7FF"], .neon, .galaxy, ["dark", "galaxy"], date),
            seed("Rainbow Neon", "Full spectrum", "A celebratory neon spectrum with black contrast.", ["#FF2C8D", "#8B5CFF", "#00E8FF", "#0A0810", "#1C122A", "#FFFFFF"], .neon, .gradient, ["rainbow", "neon"], date)
        ]
    }

    private static func seed(
        _ name: String,
        _ subtitle: String,
        _ summary: String,
        _ colors: [String],
        _ icon: IconTreatment,
        _ wallpaper: WallpaperTreatment,
        _ tags: [String],
        _ date: Date
    ) -> ThemePackage {
        ThemePackage(
            id: stableSeedID(for: name),
            name: name,
            subtitle: subtitle,
            summary: summary,
            palette: ThemePalette(primary: colors[0], secondary: colors[1], accent: colors[2], background: colors[3], surface: colors[4], text: colors[5]),
            iconTreatment: icon,
            wallpaperTreatment: wallpaper,
            tags: tags,
            createdAt: date,
            updatedAt: date,
            isBuiltIn: true
        )
    }

    /// Swift's `hashValue` is intentionally randomized between launches, so it must not be
    /// used for persisted catalog identifiers. This tiny FNV-1a derivation stays stable.
    private static func stableSeedID(for name: String) -> UUID {
        var hash: UInt64 = 1_469_598_103_934_665_603
        for byte in name.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        let suffix = String(format: "%012llX", hash & 0x0000_FFFF_FFFF_FFFF)
        return UUID(uuidString: "00000000-0000-0000-0000-\(suffix)") ?? UUID()
    }
}

// MARK: - Studio designs

enum IconShape: String, Codable, CaseIterable, Identifiable, Sendable {
    case roundedSquare
    case circle
    case squircle
    case glassTile

    var id: String { rawValue }
}

enum IconEffect: String, Codable, CaseIterable, Identifiable, Sendable {
    case none
    case glass
    case gold
    case neon
    case dimensional
    case reflection

    var id: String { rawValue }
}

struct IconDesign: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    /// Relative filename in the app-managed artwork folder; external URLs are never persisted.
    var sourceImageFilename: String?
    var shape: IconShape
    var effect: IconEffect
    var scale: Double
    var cornerRadius: Double
    var shadowOpacity: Double
    var reflectionOpacity: Double
    var backgroundHex: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "Untitled Icon",
        sourceImageFilename: String? = nil,
        shape: IconShape = .roundedSquare,
        effect: IconEffect = .glass,
        scale: Double = 0.72,
        cornerRadius: Double = 0.24,
        shadowOpacity: Double = 0.25,
        reflectionOpacity: Double = 0.18,
        backgroundHex: String = "#182033",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.sourceImageFilename = sourceImageFilename
        self.shape = shape
        self.effect = effect
        self.scale = min(max(scale, 0.2), 1.0)
        self.cornerRadius = min(max(cornerRadius, 0), 0.5)
        self.shadowOpacity = min(max(shadowOpacity, 0), 1)
        self.reflectionOpacity = min(max(reflectionOpacity, 0), 1)
        self.backgroundHex = ThemePalette.normalizedHex(backgroundHex)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum PasscodeMaterial: String, Codable, CaseIterable, Identifiable, Sendable {
    case gold
    case silver
    case chrome
    case liquidGlass
    case neon
    case dimensional

    var id: String { rawValue }
}

struct PasscodeDesign: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var material: PasscodeMaterial
    var digitHex: String
    var backgroundHex: String
    var glowIntensity: Double
    var depth: Double
    var createdAt: Date

    init(id: UUID = UUID(), name: String, material: PasscodeMaterial, digitHex: String, backgroundHex: String, glowIntensity: Double = 0.4, depth: Double = 0.2, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.material = material
        self.digitHex = ThemePalette.normalizedHex(digitHex)
        self.backgroundHex = ThemePalette.normalizedHex(backgroundHex)
        self.glowIntensity = min(max(glowIntensity, 0), 1)
        self.depth = min(max(depth, 0), 1)
        self.createdAt = createdAt
    }
}

enum HomeWidgetKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case clock
    case weather
    case battery
    case calendar
    case photos
    case quote
    case deviceInfo

    var id: String { rawValue }
}

struct HomeWidgetPlacement: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var kind: HomeWidgetKind
    var column: Int
    var row: Int
    var width: Int
    var height: Int

    init(id: UUID = UUID(), kind: HomeWidgetKind, column: Int, row: Int, width: Int = 2, height: Int = 2) {
        self.id = id
        self.kind = kind
        self.column = max(column, 0)
        self.row = max(row, 0)
        self.width = min(max(width, 1), 4)
        self.height = min(max(height, 1), 4)
    }
}

struct HomeScreenPage: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var placements: [HomeWidgetPlacement]

    init(id: UUID = UUID(), title: String = "Page", placements: [HomeWidgetPlacement] = []) {
        self.id = id
        self.title = title
        self.placements = placements
    }
}

struct HomeScreenLayout: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var pages: [HomeScreenPage]
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, pages: [HomeScreenPage] = [HomeScreenPage(title: "Page 1")], createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.name = name
        self.pages = pages.isEmpty ? [HomeScreenPage(title: "Page 1")] : pages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - History, backup and recovery

enum ThemeHistoryAction: String, Codable, CaseIterable, Sendable {
    case applied
    case restored
    case imported
    case exported
    case created
    case updated
    case deleted
    case reset
    case healthRepair
    case safeMode
}

struct ThemeHistoryEntry: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var action: ThemeHistoryAction
    var themeID: UUID?
    var themeName: String
    var detail: String
    var date: Date

    init(id: UUID = UUID(), action: ThemeHistoryAction, themeID: UUID? = nil, themeName: String, detail: String, date: Date = .now) {
        self.id = id
        self.action = action
        self.themeID = themeID
        self.themeName = themeName
        self.detail = detail
        self.date = date
    }
}

struct ThemeStateSnapshot: Codable, Hashable, Sendable {
    var themes: [ThemePackage]
    var activeThemeID: UUID?
    var iconDesigns: [IconDesign]
    var passcodeDesigns: [PasscodeDesign]
    var homeLayouts: [HomeScreenLayout]
    var settings: AppSettings
    var profile: LocalProfile
}

struct ThemeBackup: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var reason: String
    var createdAt: Date
    var snapshot: ThemeStateSnapshot

    init(id: UUID = UUID(), reason: String, createdAt: Date = .now, snapshot: ThemeStateSnapshot) {
        self.id = id
        self.reason = reason
        self.createdAt = createdAt
        self.snapshot = snapshot
    }
}

struct ThemeHealthReport: Codable, Hashable, Sendable {
    var checkedAt: Date
    var validThemeCount: Int
    var invalidThemeIDs: [UUID]
    var warnings: [String]

    var isHealthy: Bool { invalidThemeIDs.isEmpty }
}

struct RecoveryReport: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var date: Date
    var title: String
    var actions: [String]
    var protectedItems: [String]

    init(id: UUID = UUID(), date: Date = .now, title: String, actions: [String], protectedItems: [String]) {
        self.id = id
        self.date = date
        self.title = title
        self.actions = actions
        self.protectedItems = protectedItems
    }
}

// MARK: - Settings and local profile

enum AppAppearance: String, Codable, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }
}

enum ThemeScheduleRule: String, Codable, CaseIterable, Identifiable, Sendable {
    case disabled
    case onAppLaunch
    case daily
    case weekly

    var id: String { rawValue }
}

struct AppSettings: Codable, Hashable, Sendable {
    var appearance: AppAppearance
    /// `system`, `en`, or `ar`. System language remains the default.
    var languageOverride: String
    var hapticsEnabled: Bool
    var soundsEnabled: Bool
    var automaticBackupEnabled: Bool
    var safeModeEnabled: Bool
    var themeScheduleRule: ThemeScheduleRule
    var lastScheduleEvaluation: Date?
    var hasCompletedWelcome: Bool

    static let `default` = AppSettings(
        appearance: .system,
        languageOverride: "system",
        hapticsEnabled: true,
        soundsEnabled: false,
        automaticBackupEnabled: true,
        safeModeEnabled: false,
        themeScheduleRule: .disabled,
        lastScheduleEvaluation: nil,
        hasCompletedWelcome: false
    )
}

struct LocalProfile: Codable, Hashable, Sendable {
    var displayName: String
    var bio: String
    var createdAt: Date

    static let `default` = LocalProfile(displayName: "GG Collector", bio: "", createdAt: .now)
}

// MARK: - Compatibility center

enum CapabilityStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case supported
    case limited
    case unsupported

    var id: String { rawValue }
}

enum CustomizationCapability: String, Codable, CaseIterable, Identifiable, Sendable {
    case localIconStudio
    case localBackgroundRemoval
    case otherAppIconReplacement
    case installedAppSearch
    case passcodePreview
    case systemPasscodeReplacement
    case themeExport
    case springBoardLayout
    case liveActivities
    case dynamicIsland
    case wallpaperExport
    case setSystemWallpaper
    case lockScreenWidgets
    case controlCenterControls
    case dialerPreview
    case systemDialerReplacement
    case localBackupRecovery
    case weatherData

    var id: String { rawValue }
}

struct DeviceCapability: Identifiable, Codable, Hashable, Sendable {
    var capability: CustomizationCapability
    var status: CapabilityStatus
    var title: String
    var detail: String
    var requirement: String?

    var id: String { capability.rawValue }
}
