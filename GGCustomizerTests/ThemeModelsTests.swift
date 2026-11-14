import XCTest
@testable import GGCustomizer

final class ThemeModelsTests: XCTestCase {
    func testBuiltInCatalogContainsTheRequestedTwentyUniqueThemes() {
        let themes = ThemePackage.seedThemes

        XCTAssertEqual(themes.count, 20)
        XCTAssertEqual(Set(themes.map(\.id)).count, 20)
        XCTAssertEqual(Set(themes.map(\.name)).count, 20)
        XCTAssertTrue(themes.allSatisfy(\.isBuiltIn))
        XCTAssertEqual(themes.first(where: { $0.name == "Haider Signature" })?.palette.accent, "#F1C85A")
    }

    func testSeedCatalogUsesStableIdentifiersAcrossReads() {
        let firstRead = ThemePackage.seedThemes
        let secondRead = ThemePackage.seedThemes

        XCTAssertEqual(firstRead.map(\.id), secondRead.map(\.id))
    }

    func testPaletteNormalizesShortAndLowercaseHexValues() {
        let palette = ThemePalette(
            primary: "abc",
            secondary: "#deF",
            accent: "112233",
            background: "#0a0b0c",
            surface: "bad-value",
            text: "#000000FF"
        )

        XCTAssertEqual(palette.primary, "#AABBCC")
        XCTAssertEqual(palette.secondary, "#DDEEFF")
        XCTAssertEqual(palette.accent, "#112233")
        XCTAssertEqual(palette.background, "#0A0B0C")
        XCTAssertEqual(palette.surface, "#6E5BFF")
        XCTAssertEqual(palette.text, "#000000FF")
        XCTAssertTrue(palette.allHexValues.allSatisfy(ThemeEngine.isValid(hex:)))
    }

    func testThemeSearchMatchesNamesTagsAndArabicTextWithoutCaseSensitivity() {
        let theme = ThemePackage(
            name: "Royal Sapphire",
            subtitle: "A private collection",
            summary: "Designed locally",
            palette: ThemePalette(primary: "#123456", secondary: "#234567", accent: "#345678", background: "#000000", surface: "#101010", text: "#FFFFFF"),
            tags: ["Luxury", "ملكي"]
        )

        XCTAssertTrue(theme.matches("sapphire"))
        XCTAssertTrue(theme.matches("LUXURY"))
        XCTAssertTrue(theme.matches("ملكي"))
        XCTAssertFalse(theme.matches("carbon"))
        XCTAssertTrue(theme.matches("   "))
    }

    func testRandomThemeIsPortableAndValid() {
        let theme = ThemeEngine.randomTheme()

        XCTAssertFalse(theme.isBuiltIn)
        XCTAssertTrue(theme.palette.allHexValues.allSatisfy(ThemeEngine.isValid(hex:)))
        XCTAssertTrue(theme.tags.contains("local"))
        XCTAssertTrue(theme.tags.contains("generated"))
    }
}
