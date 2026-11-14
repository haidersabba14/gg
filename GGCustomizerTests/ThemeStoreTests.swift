import Foundation
import XCTest
@testable import GGCustomizer

@MainActor
final class ThemeStoreTests: XCTestCase {
    private var storageDirectory: URL!

    override func setUpWithError() throws {
        storageDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("GGCustomizerTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let storageDirectory {
            try? FileManager.default.removeItem(at: storageDirectory)
        }
        storageDirectory = nil
    }

    func testApplyAndQuickUndoRestoreThePreviousTheme() {
        let store = makeStore()
        let originalID = store.activeTheme.id
        let otherTheme = try! XCTUnwrap(store.themes.first(where: { $0.id != originalID }))

        store.apply(themeID: otherTheme.id)

        XCTAssertEqual(store.activeTheme.id, otherTheme.id)
        XCTAssertTrue(store.history.contains { $0.action == .applied && $0.themeID == otherTheme.id })
        XCTAssertTrue(store.undo())
        XCTAssertEqual(store.activeTheme.id, originalID)
    }

    func testAutomaticBackupIsCreatedBeforeMutationAndCanRestoreState() {
        let store = makeStore()
        let originalID = store.activeTheme.id
        let nextTheme = try! XCTUnwrap(store.themes.first(where: { $0.id != originalID }))

        store.apply(themeID: nextTheme.id)

        XCTAssertFalse(store.backups.isEmpty)
        XCTAssertTrue(store.restoreLastWorkingTheme())
        XCTAssertEqual(store.activeTheme.id, originalID)
    }

    func testResetOnlyResetsGGLocalDataAndKeepsSafetyBackup() {
        let store = makeStore()
        let customTheme = ThemeEngine.randomTheme()
        store.upsert(theme: customTheme)
        store.apply(themeID: customTheme.id)
        store.save(iconDesign: IconDesign(name: "Test Icon"))
        store.save(passcodeDesign: PasscodeDesign(name: "Preview", material: .neon, digitHex: "#FF00FF", backgroundHex: "#000000"))
        store.save(homeLayout: HomeScreenLayout(name: "Preview Layout"))

        let report = store.resetAllCustomizations()

        XCTAssertEqual(store.themes.count, ThemePackage.seedThemes.count)
        XCTAssertFalse(store.themes.contains(where: { $0.id == customTheme.id }))
        XCTAssertTrue(store.iconDesigns.isEmpty)
        XCTAssertTrue(store.passcodeDesigns.isEmpty)
        XCTAssertTrue(store.homeLayouts.isEmpty)
        XCTAssertFalse(store.backups.isEmpty)
        XCTAssertTrue(report.protectedItems.contains { $0.localizedCaseInsensitiveContains("Photos") })
        XCTAssertTrue(report.protectedItems.contains { $0.localizedCaseInsensitiveContains("system files") })
    }

    func testHealthRepairRemovesInvalidCustomThemeAndRetainsCatalog() {
        let store = makeStore()
        let malformed = ThemePackage(
            schemaVersion: ThemePackage.currentSchemaVersion + 1,
            name: "Broken",
            subtitle: "",
            summary: "",
            palette: ThemePalette(primary: "#123456", secondary: "#123456", accent: "#123456", background: "#123456", surface: "#123456", text: "#123456")
        )
        store.upsert(theme: malformed)

        let healthBeforeRepair = store.checkHealth()
        XCTAssertTrue(healthBeforeRepair.invalidThemeIDs.contains(malformed.id))

        let healthAfterRepair = store.repairThemeDatabase()
        XCTAssertFalse(healthAfterRepair.invalidThemeIDs.contains(malformed.id))
        XCTAssertFalse(store.themes.contains(where: { $0.id == malformed.id }))
        XCTAssertEqual(store.themes.filter(\.isBuiltIn).count, ThemePackage.seedThemes.count)
    }

    func testStatePersistsAcrossStoreInstances() {
        let firstStore = makeStore()
        let selected = try! XCTUnwrap(firstStore.themes.dropFirst().first)
        firstStore.setFavorite(themeID: selected.id, isFavorite: true)
        firstStore.rate(themeID: selected.id, rating: 5)
        firstStore.apply(themeID: selected.id)

        let reloadedStore = ThemeStore(storageDirectory: storageDirectory)
        let reloaded = try! XCTUnwrap(reloadedStore.themes.first(where: { $0.id == selected.id }))

        XCTAssertEqual(reloadedStore.activeTheme.id, selected.id)
        XCTAssertTrue(reloaded.isFavorite)
        XCTAssertEqual(reloaded.localRating, 5)
    }

    func testCapabilityReportMakesProtectedSystemChangesExplicitlyUnsupported() {
        let capabilities = DeviceCompatibilityService.capabilities()
        let statuses = Dictionary(uniqueKeysWithValues: capabilities.map { ($0.capability, $0.status) })

        XCTAssertEqual(statuses[.otherAppIconReplacement], .unsupported)
        XCTAssertEqual(statuses[.installedAppSearch], .unsupported)
        XCTAssertEqual(statuses[.systemPasscodeReplacement], .unsupported)
        XCTAssertEqual(statuses[.springBoardLayout], .unsupported)
        XCTAssertEqual(statuses[.setSystemWallpaper], .unsupported)
        XCTAssertEqual(statuses[.systemDialerReplacement], .unsupported)
        XCTAssertEqual(statuses[.localBackupRecovery], .supported)
    }

    func testThemeZIPRoundTripStaysInAppScopedPackageFormat() throws {
        let theme = ThemeEngine.randomTheme()
        let archiveURL = try ThemeTransferService.exportThemeZIP(theme)
        defer { try? FileManager.default.removeItem(at: archiveURL) }

        let imported = try ThemeTransferService.importTheme(from: archiveURL)

        XCTAssertEqual(imported.name, theme.name)
        XCTAssertEqual(imported.palette, theme.palette)
        XCTAssertFalse(imported.isBuiltIn)
    }

    func testOversizedZIPIsRejectedBeforeArchiveProcessing() throws {
        let archiveURL = storageDirectory.appendingPathComponent("oversized.zip")
        let oversizedData = Data(repeating: 0, count: ThemeTransferService.maximumArchiveBytes + 1)
        try oversizedData.write(to: archiveURL, options: .atomic)

        XCTAssertThrowsError(try ThemeTransferService.importTheme(from: archiveURL)) { error in
            XCTAssertEqual(error as? ThemeTransferError, .packageTooLarge)
        }
    }

    private func makeStore() -> ThemeStore {
        ThemeStore(storageDirectory: storageDirectory)
    }
}
