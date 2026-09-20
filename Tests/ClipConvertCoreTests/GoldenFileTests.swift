import XCTest
@testable import ClipConvertCore

final class GoldenFileTests: XCTestCase {

    /// Set to true, run once, then set back to false. Regenerates every
    /// .html file from current renderer output. Review the diff before
    /// committing — that diff is the actual review.
    static let regenerate = false

    func testFixturesMatchGoldenOutput() throws {
        let fixtures = try urls(inResourceDirectory: "Fixtures", extension: "md")
        XCTAssertFalse(fixtures.isEmpty, "no fixtures found — check Package.swift resources")

        for markdownURL in fixtures {
            let markdown = try String(contentsOf: markdownURL, encoding: .utf8)
            let actual = markdownToHTML(markdown)
            let goldenURL = markdownURL.deletingPathExtension().appendingPathExtension("html")

            if Self.regenerate {
                try actual.write(to: goldenURL, atomically: true, encoding: .utf8)
                continue
            }

            guard let expected = try? String(contentsOf: goldenURL, encoding: .utf8) else {
                XCTFail("missing golden file for \(markdownURL.lastPathComponent) — set regenerate = true once")
                continue
            }

            XCTAssertEqual(
                actual,
                expected,
                "output changed for \(markdownURL.lastPathComponent)"
            )
        }
    }

    func testAllFixturesAreDetectedAsMarkdown() throws {
        for markdownURL in try urls(inResourceDirectory: "Fixtures", extension: "md") {
            let markdown = try String(contentsOf: markdownURL, encoding: .utf8)
            XCTAssertTrue(
                shouldConvert(markdown),
                "real AI output was not detected: \(markdownURL.lastPathComponent)"
            )
        }
    }

    func testNegativeCorpusIsNeverConverted() throws {
        let samples = try urls(inResourceDirectory: "Negative", extension: "txt")
        XCTAssertFalse(samples.isEmpty, "no negative samples found")

        for sampleURL in samples {
            let text = try String(contentsOf: sampleURL, encoding: .utf8)
            XCTAssertFalse(
                shouldConvert(text),
                "false positive — would have mangled \(sampleURL.lastPathComponent)"
            )
        }
    }

    private func urls(
        inResourceDirectory directory: String,
        extension ext: String
    ) throws -> [URL] {
        guard let base = Bundle.module.url(forResource: directory, withExtension: nil) else {
            XCTFail("resource directory \(directory) not found in test bundle")
            return []
        }
        let contents = try FileManager.default.contentsOfDirectory(
            at: base,
            includingPropertiesForKeys: nil
        )
        return contents.filter { $0.pathExtension == ext }.sorted { $0.path < $1.path }
    }
}
