import CoreLocation
import XCTest
@testable import ExtasyCompleteNavigation

final class WaypointDataTests: XCTestCase {
    func testResetClearsCoreNavigationState() {
        var data = WaypointData()
        data.boatLocation = CLLocationCoordinate2D(latitude: -33.87, longitude: 151.20)
        data.waypointCoordinate = CLLocationCoordinate2D(latitude: -33.86, longitude: 151.21)
        data.distanceToMark = 1250
        data.trueMarkBearing = 45
        data.tripDurationToWaypoint = 0.5
        data.currentTackState = "Starboard"
        data.waypointApproachState = "Upwind"
        data.isVMCNegative = true
        data.starboardLayline = Layline(
            start: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            end: CLLocationCoordinate2D(latitude: 1, longitude: 0)
        )
        data.starboardIntersection = (
            intersection: CLLocationCoordinate2D(latitude: 0.5, longitude: 0),
            distanceBoat: 1,
            distanceWaypoint: 2
        )

        data.reset()

        XCTAssertNil(data.boatLocation)
        XCTAssertNil(data.waypointCoordinate)
        XCTAssertNil(data.distanceToMark)
        XCTAssertNil(data.trueMarkBearing)
        XCTAssertNil(data.tripDurationToWaypoint)
        XCTAssertNil(data.currentTackState)
        XCTAssertNil(data.waypointApproachState)
        XCTAssertFalse(data.isVMCNegative)
        XCTAssertNil(data.starboardLayline)
        XCTAssertNil(data.starboardIntersection)
    }

    func testResetIsIdempotent() {
        var data = WaypointData()
        data.distanceToMark = 100
        data.reset()
        data.reset()
        XCTAssertNil(data.distanceToMark)
    }
}
