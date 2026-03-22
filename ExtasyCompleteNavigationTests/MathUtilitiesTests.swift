import XCTest
import CoreLocation
@testable import ExtasyCompleteNavigation

final class MathUtilitiesTests: XCTestCase {

    // MARK: - toRadians / toDegrees

    func testToRadiansZero() {
        XCTAssertEqual(toRadians(0), 0, accuracy: 1e-10)
    }

    func testToRadians90() {
        XCTAssertEqual(toRadians(90), .pi / 2, accuracy: 1e-10)
    }

    func testToRadians180() {
        XCTAssertEqual(toRadians(180), .pi, accuracy: 1e-10)
    }

    func testToDegreesRoundTrip() {
        let angles = [0.0, 30.0, 45.0, 90.0, 135.0, 180.0, 270.0, 360.0]
        for angle in angles {
            XCTAssertEqual(toDegrees(toRadians(angle)), angle, accuracy: 1e-9,
                           "Round-trip failed for \(angle)°")
        }
    }

    // MARK: - normalizeAngle (0–360)

    func testNormalizeAngleZero() {
        XCTAssertEqual(normalizeAngle(0), 0, accuracy: 1e-10)
    }

    func testNormalizeAngle360() {
        XCTAssertEqual(normalizeAngle(360), 0, accuracy: 1e-10)
    }

    func testNormalizeAngle370() {
        XCTAssertEqual(normalizeAngle(370), 10, accuracy: 1e-10)
    }

    func testNormalizeAngleNegative() {
        XCTAssertEqual(normalizeAngle(-90), 270, accuracy: 1e-10)
    }

    func testNormalizeAngleNegative180() {
        XCTAssertEqual(normalizeAngle(-180), 180, accuracy: 1e-10)
    }

    func testNormalizeAngle540() {
        XCTAssertEqual(normalizeAngle(540), 180, accuracy: 1e-10)
    }

    func testNormalizeAngle180() {
        XCTAssertEqual(normalizeAngle(180), 180, accuracy: 1e-10)
    }

    // MARK: - normalizeAngleTo180 (-180…+180)

    func testNormalizeTo180_Zero() {
        XCTAssertEqual(normalizeAngleTo180(0), 0, accuracy: 1e-10)
    }

    func testNormalizeTo180_Positive90() {
        XCTAssertEqual(normalizeAngleTo180(90), 90, accuracy: 1e-10)
    }

    func testNormalizeTo180_Positive180() {
        XCTAssertEqual(normalizeAngleTo180(180), 180, accuracy: 1e-10)
    }

    func testNormalizeTo180_Positive270() {
        XCTAssertEqual(normalizeAngleTo180(270), -90, accuracy: 1e-10)
    }

    func testNormalizeTo180_Positive360() {
        XCTAssertEqual(normalizeAngleTo180(360), 0, accuracy: 1e-10)
    }

    func testNormalizeTo180_Negative90() {
        XCTAssertEqual(normalizeAngleTo180(-90), -90, accuracy: 1e-10)
    }

    func testNormalizeTo180_Negative270() {
        XCTAssertEqual(normalizeAngleTo180(-270), 90, accuracy: 1e-10)
    }

    func testNormalizeTo180_Negative180() {
        XCTAssertEqual(normalizeAngleTo180(-180), -180, accuracy: 1e-10)
    }

    // MARK: - preciseRound

    func testPreciseRoundWhole() {
        XCTAssertEqual(preciseRound(3.7, precision: .whole),  4.0, accuracy: 1e-10)
        XCTAssertEqual(preciseRound(3.4, precision: .whole),  3.0, accuracy: 1e-10)
        // Swift's round() rounds half away from zero: round(-3.5) = -4.0
        XCTAssertEqual(preciseRound(-3.5, precision: .whole), -4.0, accuracy: 1e-10)
        XCTAssertEqual(preciseRound(-3.4, precision: .whole), -3.0, accuracy: 1e-10)
    }

    func testPreciseRoundTenths() {
        XCTAssertEqual(preciseRound(3.75, precision: .tenths), 3.8, accuracy: 1e-10)
        XCTAssertEqual(preciseRound(3.74, precision: .tenths), 3.7, accuracy: 1e-10)
    }

    func testPreciseRoundHundredths() {
        XCTAssertEqual(preciseRound(3.756, precision: .hundredths), 3.76, accuracy: 1e-10)
        XCTAssertEqual(preciseRound(3.754, precision: .hundredths), 3.75, accuracy: 1e-10)
    }

    // MARK: - VMG to waypoint

    func testVMGOnCourse() {
        // Heading directly at the mark
        let result = vmg(speed: 6.0, target_angle: 90.0, boat_angle: 90.0)
        XCTAssertEqual(result, 6.0, accuracy: 1e-9)
    }

    func testVMGPerpendicular() {
        // 90° off the mark — no progress
        let result = vmg(speed: 6.0, target_angle: 90.0, boat_angle: 0.0)
        XCTAssertEqual(result, 0.0, accuracy: 1e-9)
    }

    func testVMG180Degrees() {
        // Sailing directly away
        let result = vmg(speed: 6.0, target_angle: 0.0, boat_angle: 180.0)
        XCTAssertEqual(result, -6.0, accuracy: 1e-9)
    }

    func testVMG45Degrees() {
        // 45° off — VMG = speed × cos(45°) ≈ 4.243
        let result = vmg(speed: 6.0, target_angle: 90.0, boat_angle: 45.0)
        XCTAssertEqual(result, 6.0 * cos(toRadians(45.0)), accuracy: 1e-9)
    }

    func testVMGWrappingAngles() {
        // Bearing=350°, COG=10° → offset = 20°
        let result = vmg(speed: 5.0, target_angle: 350.0, boat_angle: 10.0)
        XCTAssertEqual(result, 5.0 * cos(toRadians(20.0)), accuracy: 1e-9)
    }

    // MARK: - calculateBearing

    func testBearingDueNorth() {
        let start = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let end   = CLLocationCoordinate2D(latitude: 1, longitude: 0)
        XCTAssertEqual(calculateBearing(from: start, to: end), 0.0, accuracy: 0.01)
    }

    func testBearingDueEast() {
        let start = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let end   = CLLocationCoordinate2D(latitude: 0, longitude: 1)
        XCTAssertEqual(calculateBearing(from: start, to: end), 90.0, accuracy: 0.1)
    }

    func testBearingRoundTrip() {
        let start = CLLocationCoordinate2D(latitude: 43.0, longitude: 28.0) // Black Sea
        let end   = CLLocationCoordinate2D(latitude: 43.5, longitude: 28.5)
        let bearing = calculateBearing(from: start, to: end)
        XCTAssertGreaterThan(bearing, 0)
        XCTAssertLessThan(bearing, 90)
    }
}
