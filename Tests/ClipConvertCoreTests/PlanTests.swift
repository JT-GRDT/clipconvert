import XCTest
@testable import ClipConvertCore

final class PlanTests: XCTestCase {
    func testSkipsWhenHTMLFlavorPresent() {
        // Already rich: converting could only make it worse.
        let action = plan(plainText: "# Title\n\n**bold**", hasHTMLFlavor: true)
        XCTAssertEqual(action, .skip(reason: .alreadyRich))
    }

    func testSkipsEmptyClipboard() {
        XCTAssertEqual(
            plan(plainText: "", hasHTMLFlavor: false),
            .skip(reason: .empty)
        )
        XCTAssertEqual(
            plan(plainText: "  \n ", hasHTMLFlavor: false),
            .skip(reason: .empty)
        )
    }

    func testEmptyIsCheckedBeforeMarkdown() {
        // Whitespace must report .empty, not .noMarkdownFound.
        XCTAssertEqual(
            plan(plainText: "\n\n", hasHTMLFlavor: false),
            .skip(reason: .empty)
        )
    }

    func testSkipsPlainProse() {
        XCTAssertEqual(
            plan(plainText: "Just a sentence.", hasHTMLFlavor: false),
            .skip(reason: .noMarkdownFound)
        )
    }

    func testSkipsSourceCode() {
        let shell = "# Install\nset -e\nnpm install"
        XCTAssertEqual(
            plan(plainText: shell, hasHTMLFlavor: false),
            .skip(reason: .noMarkdownFound)
        )
    }

    func testConvertsTable() {
        let markdown = "| a | b |\n|---|---|\n| 1 | 2 |"
        guard case .convert(let html) = plan(plainText: markdown, hasHTMLFlavor: false) else {
            return XCTFail("expected .convert")
        }
        XCTAssertTrue(html.contains("<table"))
        XCTAssertTrue(html.contains("<th>a</th>"))
    }

    func testConvertsHeadingPlusBold() {
        guard case .convert(let html) = plan(
            plainText: "# Title\n\nThis is **important**.",
            hasHTMLFlavor: false
        ) else {
            return XCTFail("expected .convert")
        }
        XCTAssertTrue(html.contains("<h1>Title</h1>"))
        XCTAssertTrue(html.contains("<strong>important</strong>"))
    }

    func testLeadingWhitespaceIsNotTrimmedBeforeRendering() {
        // Four-space indentation makes this an indented code block, not a
        // heading. plan() passes the UNTRIMMED text to markdownToHTML for
        // exactly this reason. If it passed the trimmed string, the indent
        // would vanish and line one would render as an <h1>.
        //
        // Note this pins the RENDERING call only: shouldConvert trims
        // internally, so the indent never reaches detection either way.
        let indented = "    # Not a heading\n\n    **not bold**"
        guard case .convert(let html) = plan(plainText: indented, hasHTMLFlavor: false) else {
            return XCTFail("expected .convert")
        }
        XCTAssertTrue(
            html.contains("<pre><code>"),
            "an indented block must render as code"
        )
        XCTAssertFalse(
            html.contains("<h1>"),
            "leading indentation must not be trimmed away into a heading"
        )
    }
}

final class ForceConvertTests: XCTestCase {
    func testForceConvertsTextThatWouldNormallySkip() {
        let prose = "Just a sentence with no Markdown structure at all."
        // Without force, this is plain prose and is skipped.
        XCTAssertEqual(
            plan(plainText: prose, hasHTMLFlavor: false),
            .skip(reason: .noMarkdownFound)
        )
        guard case .convert(let html) = plan(
            plainText: prose,
            hasHTMLFlavor: false,
            force: true
        ) else {
            return XCTFail("expected .convert when forced")
        }
        XCTAssertTrue(html.contains(prose))
    }

    func testForceStillSkipsAlreadyRichClipboard() {
        XCTAssertEqual(
            plan(plainText: "plain text", hasHTMLFlavor: true, force: true),
            .skip(reason: .alreadyRich)
        )
    }

    func testForceStillSkipsEmptyClipboard() {
        XCTAssertEqual(
            plan(plainText: "   \n ", hasHTMLFlavor: false, force: true),
            .skip(reason: .empty)
        )
    }
}

final class SkipReasonMessageTests: XCTestCase {
    func testEveryReasonHasNonEmptyMessage() {
        XCTAssertFalse(SkipReason.alreadyRich.message.isEmpty)
        XCTAssertFalse(SkipReason.noMarkdownFound.message.isEmpty)
        XCTAssertFalse(SkipReason.empty.message.isEmpty)
    }
}
