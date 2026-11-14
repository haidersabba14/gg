import XCTest
@testable import GGCustomizer

final class VerifiedIntegrationTests: XCTestCase {
    func testSafeManifestAcceptsOnlyDocumentedFileAndShareCapabilities() throws {
        let manifest = VerifiedIntegrationManifest(
            id: "com.example.theme-library",
            name: "Example Theme Library",
            provider: "Example",
            documentationURL: try XCTUnwrap(URL(string: "https://example.com/docs")),
            capabilities: [.importThemePackage, .exportThemePackage, .openDocumentation],
            notes: "Documentation-only handoff."
        )

        let validated = try IntegrationManifestValidator.validate(manifest)
        XCTAssertEqual(validated.id, manifest.id)
        XCTAssertEqual(validated.capabilities, manifest.capabilities)
    }

    func testManifestRejectsNonHTTPSDocumentationLink() throws {
        let manifest = VerifiedIntegrationManifest(
            id: "com.example.unsafe",
            name: "Unsafe",
            provider: "Example",
            documentationURL: try XCTUnwrap(URL(string: "http://example.com")),
            capabilities: [.openDocumentation],
            notes: ""
        )

        XCTAssertThrowsError(try IntegrationManifestValidator.validate(manifest)) { error in
            XCTAssertEqual(error as? IntegrationManifestError, .untrustedURL)
        }
    }

    func testManifestRejectsNoCapabilities() throws {
        let manifest = VerifiedIntegrationManifest(
            id: "com.example.empty",
            name: "Empty",
            provider: "Example",
            documentationURL: try XCTUnwrap(URL(string: "https://example.com")),
            capabilities: [],
            notes: ""
        )

        XCTAssertThrowsError(try IntegrationManifestValidator.validate(manifest)) { error in
            XCTAssertEqual(error as? IntegrationManifestError, .emptyCapabilities)
        }
    }

    func testUnknownPrivilegedCapabilityCannotDecode() throws {
        let payload = """
        {
          "format":"com.haidersabba14.ggcustomizer.integration-manifest",
          "formatVersion":1,
          "id":"com.example.privileged",
          "name":"Privileged Tool",
          "provider":"Example",
          "documentationURL":"https://example.com/docs",
          "capabilities":["runExploit"],
          "notes":"",
          "reviewedAt":"2026-01-01T00:00:00Z"
        }
        """
        XCTAssertThrowsError(try JSONDecoder().decode(VerifiedIntegrationManifest.self, from: Data(payload.utf8)))
    }

    func testSecurityCompatibilityEngineKeepsPrivilegedSystemCustomizationDisabled() {
        let assessment = SecurityCompatibilityEngine.protectedSystemAssessment()
        XCTAssertEqual(assessment.status, .unsupported)
        XCTAssertEqual(assessment.capability, .otherAppIconReplacement)
        XCTAssertTrue(assessment.detail.localizedCaseInsensitiveContains("does not execute exploits"))
    }
}
