import Combine
import Foundation

/// The single source of truth for user-created GG Customizer content.
///
/// All files stay in the app sandbox. `ThemeStore` intentionally has no APIs for
/// changing SpringBoard, passcode, wallpaper, or other apps because iOS does not permit it.
@MainActor
final class ThemeStore: ObservableObject {
    @Published private(set) var themes: [ThemePackage] = []
    @Published private(set) var activeThemeID: UUID?
    @Published private(set) var iconDesigns: [IconDesign] = []
    @Published private(set) var passcodeDesigns: [PasscodeDesign] = []
    @Published private(set) var homeLayouts: [HomeScreenLayout] = []
    @Published private(set) var history: [ThemeHistoryEntry] = []
    @Published private(set) var backups: [ThemeBackup] = []
    @Published private(set) var recoveryReports: [RecoveryReport] = []
    @Published private(set) var healthReport = ThemeHealthReport(checkedAt: .now, validThemeCount: 0, invalidThemeIDs: [], warnings: [])
    @Published private(set) var lastError: String?

    @Published var settings: AppSettings {
        didSet { persistIfPossible() }
    }

    @Published var profile: LocalProfile {
        didSet { persistIfPossible() }
    }

    private let fileManager: FileManager
    private let storageURL: URL
    private var undoStack: [ThemeStateSnapshot] = []
    private var isLoading = true
    private var isSuppressingPersistence = false

    init(storageDirectory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let directory = storageDirectory ?? GGFileLocations.applicationSupportDirectory(fileManager: fileManager)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        self.storageURL = directory.appendingPathComponent("theme-state.json", isDirectory: false)
        self.settings = .default
        self.profile = .default

        load()
        isLoading = false

        if themes.isEmpty {
            themes = ThemePackage.seedThemes
            activeThemeID = themes.first?.id
            addHistory(.created, theme: themes.first, detail: "Built-in theme catalog initialized.")
            persist()
        } else {
            mergeBuiltInCatalog()
            _ = checkHealth(shouldPersist: false)
            persist()
        }
    }

    var activeTheme: ThemePackage {
        if let activeThemeID, let found = themes.first(where: { $0.id == activeThemeID }) {
            return found
        }
        return themes.first ?? ThemePackage.seedThemes[0]
    }

    var favoriteThemes: [ThemePackage] {
        themes.filter(\.isFavorite)
    }

    var userThemes: [ThemePackage] {
        themes.filter { !$0.isBuiltIn }
    }

    // MARK: Theme lifecycle

    func apply(themeID: UUID, scope: ThemeApplicationScope = .ggCustomizer) {
        guard let theme = themes.first(where: { $0.id == themeID }) else {
            setError("The selected theme no longer exists.")
            return
        }
        prepareForMutation(reason: "Before applying \(theme.name)")
        activeThemeID = themeID
        WidgetDataBridge.publish(theme: theme)
        addHistory(.applied, theme: theme, detail: applicationScopeDetail(scope))
        persist()
    }

    func restorePreviousTheme() -> Bool {
        guard let snapshot = undoStack.popLast() else {
            setError("There is no earlier GG Customizer change to undo.")
            return false
        }
        restore(snapshot: snapshot)
        addHistory(.restored, theme: activeTheme, detail: "Previous local state restored.")
        persist()
        return true
    }

    /// A user-facing alias for Quick Undo.
    @discardableResult
    func undo() -> Bool {
        restorePreviousTheme()
    }

    @discardableResult
    func restoreLastWorkingTheme() -> Bool {
        guard let backup = backups.first else {
            setError("No GG Customizer backup is available yet.")
            return false
        }
        restore(snapshot: backup.snapshot)
        addHistory(.restored, theme: activeTheme, detail: "Restored backup: \(backup.reason)")
        persist()
        return true
    }

    func upsert(theme: ThemePackage) {
        prepareForMutation(reason: "Before saving \(theme.name)")
        var edited = theme
        edited.touch()
        if let index = themes.firstIndex(where: { $0.id == edited.id }) {
            themes[index] = edited
            addHistory(.updated, theme: edited, detail: "Theme saved locally.")
        } else {
            themes.append(edited)
            addHistory(.created, theme: edited, detail: "Custom theme created locally.")
        }
        persist()
    }

    func createRandomTheme() -> ThemePackage {
        var theme = ThemeEngine.randomTheme()
        theme.isBuiltIn = false
        upsert(theme: theme)
        return theme
    }

    func delete(themeID: UUID) {
        guard let index = themes.firstIndex(where: { $0.id == themeID }) else { return }
        let theme = themes[index]
        guard !theme.isBuiltIn else {
            setError("Built-in themes are kept so Restore Original Design is always available.")
            return
        }
        prepareForMutation(reason: "Before deleting \(theme.name)")
        themes.remove(at: index)
        if activeThemeID == themeID { activeThemeID = ThemePackage.seedThemes.first?.id }
        addHistory(.deleted, theme: theme, detail: "Custom theme removed from GG Customizer.")
        persist()
    }

    func setFavorite(themeID: UUID, isFavorite: Bool? = nil) {
        guard let index = themes.firstIndex(where: { $0.id == themeID }) else { return }
        prepareForMutation(reason: "Before changing favorite")
        themes[index].isFavorite = isFavorite ?? !themes[index].isFavorite
        themes[index].touch()
        addHistory(.updated, theme: themes[index], detail: themes[index].isFavorite ? "Added to favorites." : "Removed from favorites.")
        persist()
    }

    func rate(themeID: UUID, rating: Int) {
        guard let index = themes.firstIndex(where: { $0.id == themeID }) else { return }
        themes[index].localRating = min(max(rating, 0), 5)
        themes[index].touch()
        persist()
    }

    // MARK: Designs and layouts

    func save(iconDesign: IconDesign) {
        prepareForMutation(reason: "Before saving icon design")
        if let index = iconDesigns.firstIndex(where: { $0.id == iconDesign.id }) {
            iconDesigns[index] = iconDesign
        } else {
            iconDesigns.append(iconDesign)
        }
        persist()
    }

    func delete(iconDesignID: UUID) {
        prepareForMutation(reason: "Before deleting icon design")
        iconDesigns.removeAll { $0.id == iconDesignID }
        persist()
    }

    func save(passcodeDesign: PasscodeDesign) {
        prepareForMutation(reason: "Before saving passcode design")
        if let index = passcodeDesigns.firstIndex(where: { $0.id == passcodeDesign.id }) {
            passcodeDesigns[index] = passcodeDesign
        } else {
            passcodeDesigns.append(passcodeDesign)
        }
        persist()
    }

    func delete(passcodeDesignID: UUID) {
        prepareForMutation(reason: "Before deleting passcode design")
        passcodeDesigns.removeAll { $0.id == passcodeDesignID }
        persist()
    }

    func save(homeLayout: HomeScreenLayout) {
        prepareForMutation(reason: "Before saving home layout")
        if let index = homeLayouts.firstIndex(where: { $0.id == homeLayout.id }) {
            homeLayouts[index] = homeLayout
        } else {
            homeLayouts.append(homeLayout)
        }
        persist()
    }

    func delete(homeLayoutID: UUID) {
        prepareForMutation(reason: "Before deleting home layout")
        homeLayouts.removeAll { $0.id == homeLayoutID }
        persist()
    }

    // MARK: Backup, recovery and health

    @discardableResult
    func makeBackup(reason: String) -> ThemeBackup {
        let backup = ThemeBackup(reason: reason, snapshot: snapshot())
        backups.insert(backup, at: 0)
        backups = Array(backups.prefix(30))
        persist()
        return backup
    }

    func restore(backup: ThemeBackup) {
        prepareForMutation(reason: "Before restoring backup")
        restore(snapshot: backup.snapshot)
        addHistory(.restored, theme: activeTheme, detail: "Restored backup: \(backup.reason)")
        persist()
    }

    /// Resets only GG Customizer's local state. No system files, photos, apps, or device
    /// settings are touched. A safety backup remains available in Theme History.
    @discardableResult
    func resetAllCustomizations() -> RecoveryReport {
        let safetyBackup = ThemeBackup(reason: "Before Reset All Customizations", snapshot: snapshot())
        undoStack.append(snapshot())
        undoStack = Array(undoStack.suffix(10))
        backups.insert(safetyBackup, at: 0)
        backups = Array(backups.prefix(30))

        suppressPersistence {
            themes = ThemePackage.seedThemes
            activeThemeID = themes.first?.id
            iconDesigns = []
            passcodeDesigns = []
            homeLayouts = []
            settings = .default
            profile = .default
        }
        let removedExports = GGFileLocations.removeTemporaryExports(fileManager: fileManager)
        let report = RecoveryReport(
            title: "Reset All Customizations",
            actions: [
                "Restored the built-in GG theme catalog.",
                "Removed saved GG icon, passcode, and home-layout designs.",
                "Removed \(removedExports) temporary export file(s).",
                "Created a local safety backup before resetting."
            ],
            protectedItems: [
                "Your Photos library was not changed.",
                "No system files, installed apps, passcode, or wallpapers were touched.",
                "The backup is kept inside GG Customizer only."
            ]
        )
        recoveryReports.insert(report, at: 0)
        recoveryReports = Array(recoveryReports.prefix(20))
        addHistory(.reset, theme: activeTheme, detail: "GG Customizer local state reset.")
        _ = checkHealth(shouldPersist: false)
        persist()
        return report
    }

    @discardableResult
    func checkHealth(shouldPersist: Bool = true) -> ThemeHealthReport {
        var invalidIDs: [UUID] = []
        var warnings: [String] = []
        for theme in themes {
            let validColors = theme.palette.allHexValues.allSatisfy(ThemeEngine.isValid(hex:))
            if !validColors || theme.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || theme.schemaVersion > ThemePackage.currentSchemaVersion {
                invalidIDs.append(theme.id)
            }
        }
        if themes.isEmpty { warnings.append("Theme catalog was empty; built-in themes will be restored.") }
        if let activeThemeID, !themes.contains(where: { $0.id == activeThemeID }) {
            warnings.append("The active theme was missing and will be repaired.")
        }
        let report = ThemeHealthReport(checkedAt: .now, validThemeCount: max(themes.count - invalidIDs.count, 0), invalidThemeIDs: invalidIDs, warnings: warnings)
        healthReport = report
        if shouldPersist { persist() }
        return report
    }

    @discardableResult
    func repairThemeDatabase() -> ThemeHealthReport {
        prepareForMutation(reason: "Before health repair")
        let report = checkHealth(shouldPersist: false)
        if !report.invalidThemeIDs.isEmpty {
            themes.removeAll { report.invalidThemeIDs.contains($0.id) }
        }
        mergeBuiltInCatalog()
        if themes.isEmpty { themes = ThemePackage.seedThemes }
        if let activeThemeID, !themes.contains(where: { $0.id == activeThemeID }) { self.activeThemeID = themes.first?.id }
        let repaired = checkHealth(shouldPersist: false)
        addHistory(.healthRepair, theme: activeTheme, detail: "Theme database repair completed.")
        persist()
        return repaired
    }

    func setSafeMode(_ enabled: Bool) {
        settings.safeModeEnabled = enabled
        addHistory(.safeMode, theme: activeTheme, detail: enabled ? "Emergency Safe Mode enabled." : "Emergency Safe Mode disabled.")
        persist()
    }

    // MARK: Scheduling

    /// iOS does not promise exact background execution. This is intentionally evaluated while
    /// GG Customizer is open (or when its app refresh opportunity occurs).
    @discardableResult
    func applyScheduledThemeIfDue(now: Date = .now) -> ThemePackage? {
        let rule = settings.themeScheduleRule
        guard rule != .disabled, themes.count > 1 else { return nil }
        guard isScheduleDue(rule: rule, last: settings.lastScheduleEvaluation, now: now) else { return nil }
        let candidates = themes.filter { $0.id != activeThemeID }
        guard let next = candidates.randomElement() else { return nil }
        settings.lastScheduleEvaluation = now
        apply(themeID: next.id)
        return next
    }

    // MARK: Private persistence

    private struct PersistedState: Codable {
        var version: Int
        var themes: [ThemePackage]
        var activeThemeID: UUID?
        var iconDesigns: [IconDesign]
        var passcodeDesigns: [PasscodeDesign]
        var homeLayouts: [HomeScreenLayout]
        var history: [ThemeHistoryEntry]
        var backups: [ThemeBackup]
        var recoveryReports: [RecoveryReport]
        var undoStack: [ThemeStateSnapshot]
        var settings: AppSettings
        var profile: LocalProfile
    }

    private func load() {
        guard fileManager.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let state = try JSONDecoder.ggCustomizer.decode(PersistedState.self, from: data)
            themes = state.themes
            activeThemeID = state.activeThemeID
            iconDesigns = state.iconDesigns
            passcodeDesigns = state.passcodeDesigns
            homeLayouts = state.homeLayouts
            history = state.history
            backups = state.backups
            recoveryReports = state.recoveryReports
            undoStack = state.undoStack
            settings = state.settings
            profile = state.profile
        } catch {
            lastError = "The local theme database could not be read. A fresh catalog was created; no system data was affected."
            GGLogger.storage.error("Unable to decode theme state: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func persistIfPossible() {
        guard !isLoading, !isSuppressingPersistence else { return }
        persist()
    }

    private func persist() {
        guard !isLoading, !isSuppressingPersistence else { return }
        let state = PersistedState(
            version: 1,
            themes: themes,
            activeThemeID: activeThemeID,
            iconDesigns: iconDesigns,
            passcodeDesigns: passcodeDesigns,
            homeLayouts: homeLayouts,
            history: history,
            backups: backups,
            recoveryReports: recoveryReports,
            undoStack: undoStack,
            settings: settings,
            profile: profile
        )
        do {
            let data = try JSONEncoder.ggCustomizer.encode(state)
            try data.write(to: storageURL, options: .atomic)
            lastError = nil
        } catch {
            setError("GG Customizer could not save local changes. Please check available device storage.")
            GGLogger.storage.error("Unable to save theme state: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func snapshot() -> ThemeStateSnapshot {
        ThemeStateSnapshot(
            themes: themes,
            activeThemeID: activeThemeID,
            iconDesigns: iconDesigns,
            passcodeDesigns: passcodeDesigns,
            homeLayouts: homeLayouts,
            settings: settings,
            profile: profile
        )
    }

    private func restore(snapshot: ThemeStateSnapshot) {
        suppressPersistence {
            themes = snapshot.themes
            activeThemeID = snapshot.activeThemeID
            iconDesigns = snapshot.iconDesigns
            passcodeDesigns = snapshot.passcodeDesigns
            homeLayouts = snapshot.homeLayouts
            settings = snapshot.settings
            profile = snapshot.profile
        }
        mergeBuiltInCatalog()
        if let activeThemeID, !themes.contains(where: { $0.id == activeThemeID }) { self.activeThemeID = themes.first?.id }
    }

    private func prepareForMutation(reason: String) {
        let current = snapshot()
        undoStack.append(current)
        undoStack = Array(undoStack.suffix(10))
        if settings.automaticBackupEnabled {
            backups.insert(ThemeBackup(reason: reason, snapshot: current), at: 0)
            backups = Array(backups.prefix(30))
        }
    }

    private func mergeBuiltInCatalog() {
        let builtIns = ThemePackage.seedThemes
        for catalogTheme in builtIns where !themes.contains(where: { $0.id == catalogTheme.id }) {
            themes.append(catalogTheme)
        }
        if activeThemeID == nil { activeThemeID = themes.first?.id }
    }

    private func suppressPersistence(_ changes: () -> Void) {
        isSuppressingPersistence = true
        changes()
        isSuppressingPersistence = false
    }

    private func addHistory(_ action: ThemeHistoryAction, theme: ThemePackage?, detail: String) {
        let entry = ThemeHistoryEntry(action: action, themeID: theme?.id, themeName: theme?.name ?? "GG Customizer", detail: detail)
        history.insert(entry, at: 0)
        history = Array(history.prefix(100))
    }

    private func applicationScopeDetail(_ scope: ThemeApplicationScope) -> String {
        switch scope {
        case .ggCustomizer:
            return "Applied inside GG Customizer. iOS system appearance was not changed."
        case .ggWidgets:
            return "Saved for GG widgets where the user has added them through iOS."
        case .exportedPackage:
            return "Prepared a local package for sharing or export."
        case .systemPreview:
            return "Previewed only; iOS does not allow system-wide theme application."
        }
    }

    private func isScheduleDue(rule: ThemeScheduleRule, last: Date?, now: Date) -> Bool {
        guard let last else { return true }
        let calendar = Calendar.autoupdatingCurrent
        switch rule {
        case .disabled: return false
        case .onAppLaunch: return !calendar.isDate(last, equalTo: now, toGranularity: .minute)
        case .daily: return !calendar.isDate(last, inSameDayAs: now)
        case .weekly:
            return (calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: last, to: now).weekOfYear ?? 0) >= 1
        }
    }

    private func setError(_ message: String) {
        lastError = message
        GGLogger.storage.error("\(message, privacy: .public)")
    }
}

private extension JSONEncoder {
    static var ggCustomizer: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var ggCustomizer: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
