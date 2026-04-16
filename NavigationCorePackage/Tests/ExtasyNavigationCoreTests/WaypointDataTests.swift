import XCTest
@testable import ExtasyNavigationCore

final class WaypointDataTests: XCTestCase {
    func testResetIsCallableAndIdempotent() {
        var data = WaypointData()
        data.reset()
        data.reset()
    }
}
