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

final class BlockRenderingTests: XCTestCase {
    func testUnorderedList() {
        XCTAssertEqual(
            markdownToHTML("- one\n- two"),
            "<ul><li><p>one</p></li><li><p>two</p></li></ul>"
        )
    }

    func testOrderedList() {
        XCTAssertEqual(
            markdownToHTML("1. one\n2. two"),
            "<ol><li><p>one</p></li><li><p>two</p></li></ol>"
        )
    }

    func testNestedList() {
        let markdown = """
        - outer
          - inner
        """
        XCTAssertEqual(
            markdownToHTML(markdown),
            "<ul><li><p>outer</p><ul><li><p>inner</p></li></ul></li></ul>"
        )
    }

    func testBlockQuote() {
        XCTAssertEqual(
            markdownToHTML("> quoted"),
            "<blockquote><p>quoted</p></blockquote>"
        )
    }

    func testFencedCodeBlockIsEscaped() {
        let markdown = """
        ```swift
        if a < b { print("x") }
        ```
        """
        XCTAssertEqual(
            markdownToHTML(markdown),
            "<pre><code>if a &lt; b { print(&quot;x&quot;) }\n</code></pre>"
        )
    }

    func testThematicBreak() {
        XCTAssertEqual(markdownToHTML("---"), "<hr>")
    }
}

final class TableRenderingTests: XCTestCase {
    func testSimpleTable() {
        let markdown = """
        | Region | Revenue |
        |--------|---------|
        | EMEA   | 1.2M    |
        """
        let expected = "<table border=\"1\" cellspacing=\"0\" cellpadding=\"4\">"
            + "<thead><tr><th>Region</th><th>Revenue</th></tr></thead>"
            + "<tbody><tr><td>EMEA</td><td>1.2M</td></tr></tbody>"
            + "</table>"
        XCTAssertEqual(markdownToHTML(markdown), expected)
    }

    func testTableWithInlineFormatting() {
        let markdown = """
        | Flag | Meaning |
        |------|---------|
        | `-v` | **verbose** |
        """
        let html = markdownToHTML(markdown)
        XCTAssertTrue(html.contains("<td><code>-v</code></td>"))
        XCTAssertTrue(html.contains("<td><strong>verbose</strong></td>"))
    }

    func testTableCellContentIsEscaped() {
        let markdown = """
        | Expr |
        |------|
        | a < b |
        """
        XCTAssertTrue(markdownToHTML(markdown).contains("<td>a &lt; b</td>"))
    }

    func testMultipleBodyRows() {
        let markdown = """
        | n |
        |---|
        | 1 |
        | 2 |
        """
        let html = markdownToHTML(markdown)
        XCTAssertTrue(html.contains("<tr><td>1</td></tr><tr><td>2</td></tr>"))
    }
}

final class RawHTMLRenderingTests: XCTestCase {
    func testBreakTagInsideTableCellIsPreserved() {
        let markdown = """
        | n |
        |---|
        | first<br>second |
        """
        XCTAssertTrue(
            markdownToHTML(markdown).contains("<td>first<br>second</td>"),
            "a <br> inside a cell must not fuse the two words together"
        )
    }

    func testUnknownInlineHTMLIsEscapedNotDropped() {
        let html = markdownToHTML("before <span>x</span> after")
        XCTAssertTrue(
            html.contains("&lt;span&gt;x&lt;/span&gt;"),
            "unrecognized raw HTML must appear as visible escaped text, not vanish"
        )
    }

    func testHTMLBlockIsEscapedNotDropped() {
        let markdown = """
        Before.

        <div>raw block</div>

        After.
        """
        let html = markdownToHTML(markdown)
        XCTAssertTrue(
            html.contains("&lt;div&gt;raw block&lt;/div&gt;"),
            "a raw HTML block must appear as visible escaped text, not vanish"
        )
        XCTAssertTrue(html.contains("Before."))
        XCTAssertTrue(html.contains("After."))
    }
}

final class OrderedListStartIndexTests: XCTestCase {
    func testOrderedListStartingAtThreeEmitsStartAttribute() {
        let markdown = "3. three\n4. four"
        XCTAssertEqual(
            markdownToHTML(markdown),
            "<ol start=\"3\"><li><p>three</p></li><li><p>four</p></li></ol>"
        )
    }
}
