import XCTest
@testable import ClipConvertCore

final class HTMLEscapingTests: XCTestCase {
    func testEscapesMarkupCharacters() {
        XCTAssertEqual(escapeHTML("a < b & c > d"), "a &lt; b &amp; c &gt; d")
    }

    func testEscapesQuotes() {
        XCTAssertEqual(escapeHTML(#"say "hi""#), "say &quot;hi&quot;")
    }

    func testLeavesPlainTextAlone() {
        XCTAssertEqual(escapeHTML("nothing to do"), "nothing to do")
    }
}

final class HTMLRendererTests: XCTestCase {
    func testParagraph() {
        XCTAssertEqual(markdownToHTML("Hello."), "<p>Hello.</p>")
    }

    func testHeadingLevels() {
        XCTAssertEqual(markdownToHTML("# One"), "<h1>One</h1>")
        XCTAssertEqual(markdownToHTML("### Three"), "<h3>Three</h3>")
    }

    func testEscapesTextContent() {
        XCTAssertEqual(
            markdownToHTML("5 < 6 & 7 > 2"),
            "<p>5 &lt; 6 &amp; 7 &gt; 2</p>"
        )
    }

    func testMultipleBlocks() {
        XCTAssertEqual(
            markdownToHTML("# Title\n\nBody."),
            "<h1>Title</h1><p>Body.</p>"
        )
    }
}

final class InlineRenderingTests: XCTestCase {
    func testStrong() {
        XCTAssertEqual(
            markdownToHTML("This is **bold**."),
            "<p>This is <strong>bold</strong>.</p>"
        )
    }

    func testEmphasis() {
        XCTAssertEqual(
            markdownToHTML("This is *italic*."),
            "<p>This is <em>italic</em>.</p>"
        )
    }

    func testInlineCodeIsEscaped() {
        XCTAssertEqual(
            markdownToHTML("Run `a < b`."),
            "<p>Run <code>a &lt; b</code>.</p>"
        )
    }

    func testLink() {
        XCTAssertEqual(
            markdownToHTML("See [docs](https://example.com)."),
            #"<p>See <a href="https://example.com">docs</a>.</p>"#
        )
    }

    func testLinkDestinationIsEscaped() {
        XCTAssertEqual(
            markdownToHTML(#"[x](https://e.com/?a=1&b=2)"#),
            #"<p><a href="https://e.com/?a=1&amp;b=2">x</a></p>"#
        )
    }

    func testHardLineBreak() {
        // Two trailing spaces produce a hard break.
        XCTAssertEqual(
            markdownToHTML("one  \ntwo"),
            "<p>one<br>two</p>"
        )
    }

    func testSoftBreakBecomesSpace() {
        XCTAssertEqual(markdownToHTML("one\ntwo"), "<p>one two</p>")
    }
}
