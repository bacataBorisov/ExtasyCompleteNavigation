import CoreLocation
import XCTest
@testable import ExtasyNavigationCore

final class LaylineTests: XCTestCase {
    func testEqualitySameCoordinates() {
        let a = Layline(
            start: CLLocationCoordinate2D(latitude: -33.9, longitude: 151.2),
            end: CLLocationCoordinate2D(latitude: -34.0, longitude: 151.3)
        )
        let b = Layline(
            start: CLLocationCoordinate2D(latitude: -33.9, longitude: 151.2),
            end: CLLocationCoordinate2D(latitude: -34.0, longitude: 151.3)
        )
        XCTAssertEqual(a, b)
        XCTAssertTrue(a == b)
    }

    func testInequalityWhenEndDiffers() {
        let a = Layline(
            start: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            end: CLLocationCoordinate2D(latitude: 1, longitude: 0)
        )
        let b = Layline(
            start: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            end: CLLocationCoordinate2D(latitude: 1, longitude: 0.0001)
        )
        XCTAssertNotEqual(a, b)
    }

    func testInequalityWhenStartDiffers() {
        let a = Layline(
            start: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            end: CLLocationCoordinate2D(latitude: 1, longitude: 1)
        )
        let b = Layline(
            start: CLLocationCoordinate2D(latitude: 0.0001, longitude: 0),
            end: CLLocationCoordinate2D(latitude: 1, longitude: 1)
        )
        XCTAssertNotEqual(a, b)
    }

    func testSetDeduplicatesEqualLaylines() {
        let line = Layline(
            start: CLLocationCoordinate2D(latitude: 10, longitude: -175),
            end: CLLocationCoordinate2D(latitude: 10, longitude: 175)
        )
        let copy = Layline(
            start: CLLocationCoordinate2D(latitude: 10, longitude: -175),
            end: CLLocationCoordinate2D(latitude: 10, longitude: 175)
        )
        let set: Set<Layline> = [line, copy]
        XCTAssertEqual(set.count, 1)
    }

    func testHashingDistinctLaylinesStayDistinctInSet() {
        let a = Layline(
            start: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            end: CLLocationCoordinate2D(latitude: 1, longitude: 0)
        )
        let b = Layline(
            start: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            end: CLLocationCoordinate2D(latitude: 0, longitude: 1)
        )
        let set: Set<Layline> = [a, b]
        XCTAssertEqual(set.count, 2)
    }
}
