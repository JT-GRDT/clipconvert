import XCTest
@testable import ClipConvertCore

final class MarkdownLibraryTests: XCTestCase {
    func testParsesTopLevelBlocks() {
        let markdown = """
        # Title

        A paragraph.

        - one
        - two
        """
        // heading, paragraph, list
        XCTAssertEqual(parsedBlockCount(markdown), 3)
    }

    func testParsesGFMTable() {
        let markdown = """
        | a | b |
        |---|---|
        | 1 | 2 |
        """
        // Must assert the NODE TYPE, not the block count. With the GFM
        // extension off, those three lines parse as one Paragraph joined
        // by soft breaks — so a count of 1 passes either way and proves
        // nothing.
        XCTAssertTrue(firstBlockIsTable(markdown))
    }

    func testProseIsNotATable() {
        XCTAssertFalse(firstBlockIsTable("Just a sentence."))
    }
}
