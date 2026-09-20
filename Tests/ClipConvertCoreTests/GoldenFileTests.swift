import XCTest
@testable import ClipConvertCore

final class GoldenFileTests: XCTestCase {

    /// Set to true, run once, then set back to false. Regenerates every
    /// .html file from current renderer output. Review the diff before
    /// committing — that diff is the actual review.
    static let regenerate = false

    func testFixturesMatchGoldenOutput() throws {
        XCTAssertFalse(
            Self.regenerate,
            "regenerate must be false when committed, or the golden tests silently rewrite their own expectations and can never fail"
        )

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

    /// Guards against the whole class of bug that motivated Fix 1: any
    /// node type the renderer fails to visit (a new `defaultVisit` leaf)
    /// silently drops its content. Every alphanumeric word of 4+
    /// characters in a fixture's source must show up somewhere in the
    /// rendered HTML.
    ///
    /// One exclusion: a fenced code block's info string (the language
    /// tag on the opening ``` line, e.g. "bash" in `list-with-code-*`)
    /// is fence syntax, not prose content — `visitCodeBlock` intentionally
    /// renders only `codeBlock.code`, not the language, and adding a
    /// `class="language-…"` attribute is out of scope for this fix wave.
    /// Excluding fence-opener lines here avoids a false failure unrelated
    /// to any dropped node.
    func testNoWordIsSilentlyDroppedFromFixtures() throws {
        let wordPattern = try NSRegularExpression(pattern: "[A-Za-z0-9]{4,}")

        for markdownURL in try urls(inResourceDirectory: "Fixtures", extension: "md") {
            let markdown = try String(contentsOf: markdownURL, encoding: .utf8)
            let html = markdownToHTML(markdown)

            let contentOnly = markdown
                .split(separator: "\n", omittingEmptySubsequences: false)
                .filter { !$0.hasPrefix("```") }
                .joined(separator: "\n")

            let nsContent = contentOnly as NSString
            let matches = wordPattern.matches(
                in: contentOnly,
                range: NSRange(location: 0, length: nsContent.length)
            )
            let words = Set(matches.map { nsContent.substring(with: $0.range) })

            for word in words {
                XCTAssertTrue(
                    html.contains(word),
                    "word '\(word)' from \(markdownURL.lastPathComponent) is missing from the " +
                    "rendered HTML — possible silent content loss"
                )
            }
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
