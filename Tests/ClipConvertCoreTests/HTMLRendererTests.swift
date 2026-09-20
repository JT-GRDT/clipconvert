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
