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

final class ShouldConvertTests: XCTestCase {
    // Strong signals convert on their own.

    func testTableConvertsAlone() {
        let text = """
        | a | b |
        |---|---|
        | 1 | 2 |
        """
        XCTAssertTrue(shouldConvert(text))
    }

    func testFencedCodeConvertsAlone() {
        XCTAssertTrue(shouldConvert("```python\nprint(1)\n```"))
    }

    // Weak signals need an inline signal alongside them.

    func testHeadingPlusBoldConverts() {
        XCTAssertTrue(shouldConvert("# Title\n\nThis is **important**."))
    }

    func testListPlusLinkConverts() {
        XCTAssertTrue(shouldConvert("- see [the docs](https://example.com)\n- and more"))
    }

    func testBareListDoesNotConvert() {
        // Loses nothing as plain text, so not worth the false-positive risk.
        XCTAssertFalse(shouldConvert("- milk\n- eggs\n- bread"))
    }

    func testBoldAloneDoesNotConvert() {
        XCTAssertFalse(shouldConvert("This is **important** and that is all."))
    }

    // The negative corpus: these must never convert.

    func testYAMLDoesNotConvert() {
        let yaml = """
        # deployment config
        services:
          - name: web
          - name: worker
        """
        XCTAssertFalse(shouldConvert(yaml))
    }

    func testShellScriptDoesNotConvert() {
        let shell = """
        # Install dependencies
        set -e
        npm install
        # Build the project
        npm run build
        """
        XCTAssertFalse(shouldConvert(shell))
    }

    func testPythonSourceDoesNotConvert() {
        let python = """
        # Compute the total
        def total(items):
            return sum(i.price for i in items)
        """
        XCTAssertFalse(shouldConvert(python))
    }

    func testCommandLineFlagsDoNotConvert() {
        XCTAssertFalse(shouldConvert("run --verbose -o out.txt"))
    }

    func testEmptyStringDoesNotConvert() {
        XCTAssertFalse(shouldConvert(""))
        XCTAssertFalse(shouldConvert("   \n  \n "))
    }
}
