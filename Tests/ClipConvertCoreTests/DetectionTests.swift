import XCTest
@testable import ClipConvertCore

final class DetectionTests: XCTestCase {
    func testDetectsTableDelimiterRow() {
        let text = """
        | Region | Revenue |
        |--------|---------|
        | EMEA   | 1.2M    |
        """
        XCTAssertTrue(detectSignals(text).tableDelimiter)
    }

    func testDetectsAlignedTableDelimiterRow() {
        let text = """
        | a | b |
        |:---|---:|
        | 1 | 2 |
        """
        XCTAssertTrue(detectSignals(text).tableDelimiter)
    }

    func testSingleColumnDashLineIsNotATable() {
        // A horizontal rule or an underlined heading must not read as a table.
        XCTAssertFalse(detectSignals("-----").tableDelimiter)
    }

    func testDetectsCodeFence() {
        let text = """
        Here you go:

        ```swift
        let x = 1
        ```
        """
        XCTAssertTrue(detectSignals(text).fence)
    }

    func testDetectsHeading() {
        XCTAssertTrue(detectSignals("# Title").heading)
        XCTAssertTrue(detectSignals("### Deeper").heading)
    }

    func testHashWithoutSpaceIsNotAHeading() {
        // "#include" and "#1" are not headings.
        XCTAssertFalse(detectSignals("#include <stdio.h>").heading)
        XCTAssertFalse(detectSignals("#1 priority").heading)
    }

    func testDetectsUnorderedList() {
        XCTAssertTrue(detectSignals("- one\n- two").unorderedList)
        XCTAssertTrue(detectSignals("* one").unorderedList)
    }

    func testDetectsOrderedList() {
        XCTAssertTrue(detectSignals("1. first\n2. second").orderedList)
    }

    func testDetectsBlockQuote() {
        XCTAssertTrue(detectSignals("> quoted").blockQuote)
    }

    func testPlainProseHasNoBlockSignals() {
        let signals = detectSignals("Just an ordinary sentence about nothing.")
        XCTAssertFalse(signals.tableDelimiter)
        XCTAssertFalse(signals.fence)
        XCTAssertFalse(signals.heading)
        XCTAssertFalse(signals.unorderedList)
        XCTAssertFalse(signals.orderedList)
        XCTAssertFalse(signals.blockQuote)
    }
}
