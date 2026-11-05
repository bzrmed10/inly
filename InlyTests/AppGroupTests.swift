import XCTest
@testable import Inly

final class AppGroupTests: XCTestCase {
    func testAppGroupIdentifier() {
        XCTAssertEqual(AppGroup.identifier, "group.com.bzrmed.inly")
    }
}
