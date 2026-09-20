import XCTest
@testable import ClipConvertCore

final class SmokeTests: XCTestCase {
    func testPackageBuildsAndTestsRun() {
        XCTAssertEqual(coreVersion, "0.1.0")
    }
}
