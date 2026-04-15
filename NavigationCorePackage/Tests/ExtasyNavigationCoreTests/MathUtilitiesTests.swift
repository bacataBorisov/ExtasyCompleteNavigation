import XCTest
import CoreLocation
@testable import ExtasyNavigationCore

final class MathUtilitiesTests: XCTestCase {
    func testPreciseRoundNegativeHalfAwayFromZero() {
        XCTAssertEqual(preciseRound(-3.5, precision: .whole), -4.0, accuracy: 1e-10)
    }

    func testNormalizeAngleTinyNegativeWrapsNear360() {
        XCTAssertEqual(normalizeAngle(-0.0001), 359.9999, accuracy: 1e-8)
    }

    func testNormalizeAngleLargeMultipleTurns() {
        XCTAssertEqual(normalizeAngle(1080 + 17.25), 17.25, accuracy: 1e-10)
        XCTAssertEqual(normalizeAngle(-1080 - 17.25), 342.75, accuracy: 1e-10)
    }

    func testNormalizeTo180JustAboveBoundaryWrapsNegative() {
        XCTAssertEqual(normalizeAngleTo180(180.0001), -179.9999, accuracy: 1e-8)
    }

    func testNormalizeTo180JustBelowNegativeBoundaryWrapsPositive() {
        XCTAssertEqual(normalizeAngleTo180(-180.0001), 179.9999, accuracy: 1e-8)
    }

    func testNormalizeTo180LargeTurnsPreserveSignedOffset() {
        XCTAssertEqual(normalizeAngleTo180(720 + 45), 45, accuracy: 1e-10)
        XCTAssertEqual(normalizeAngleTo180(-720 - 45), -45, accuracy: 1e-10)
    }

    func testNormalizeTo180PreservesNegativeBoundary() {
        XCTAssertEqual(normalizeAngleTo180(-180.0), -180.0, accuracy: 1e-10)
    }

    func testVMGWrapsAcrossZeroDegrees() {
        let result = vmg(speed: 8.0, target_angle: 1.0, boat_angle: 359.0)
        XCTAssertEqual(result, 8.0 * cos(toRadians(2.0)), accuracy: 1e-9)
    }

    func testBearingAcrossDateLineEastbound() {
        let start = CLLocationCoordinate2D(latitude: 0.0, longitude: 179.0)
        let end = CLLocationCoordinate2D(latitude: 0.0, longitude: -179.0)
        XCTAssertEqual(calculateBearing(from: start, to: end), 90.0, accuracy: 0.5)
    }

    func testBearingAcrossDateLineWestbound() {
        let start = CLLocationCoordinate2D(latitude: 0.0, longitude: -179.0)
        let end = CLLocationCoordinate2D(latitude: 0.0, longitude: 179.0)
        XCTAssertEqual(calculateBearing(from: start, to: end), 270.0, accuracy: 0.5)
    }

    func testBearingDueNorth() {
        let start = CLLocationCoordinate2D(latitude: 10.0, longitude: 20.0)
        let end = CLLocationCoordinate2D(latitude: 11.0, longitude: 20.0)
        XCTAssertEqual(calculateBearing(from: start, to: end), 0.0, accuracy: 0.1)
    }
}
