import XCTest
import CoreLocation
@testable import ExtasyCompleteNavigation

final class WaypointTripTimeTests: XCTestCase {

    func testTripUsesSumOfTacticalLegsWhenBothProvided() {
        // Same scenario class as UI: small VMC but healthy SOG — leg sum must win.
        let dtmNM = 62.1
        let dtmMeters = dtmNM / toNauticalMiles
        let sog = 5.9
        let leg1 = 10.5
        let leg2 = 3.4
        let trip = WaypointProcessor.tripDurationToWaypointHours(
            distanceToMarkMeters: dtmMeters,
            effectiveSOGKnots: sog,
            leg1Hours: leg1,
            leg2Hours: leg2
        )
        XCTAssertEqual(trip!, leg1 + leg2, accuracy: 1e-6)
        XCTAssertLessThan(trip!, 24, "Trip should be hours-scale, not hundreds of hours from DTM/VMC.")
    }

    func testTripFallsBackToRhumbLineWhenNoLegs() {
        let dtmMeters = 100.0 / toNauticalMiles // ≈ 100 NM
        let sog = 10.0
        let trip = WaypointProcessor.tripDurationToWaypointHours(
            distanceToMarkMeters: dtmMeters,
            effectiveSOGKnots: sog,
            leg1Hours: nil,
            leg2Hours: nil
        )
        XCTAssertEqual(trip!, 10.0, accuracy: 1e-6)
    }

    func testTripNilWhenSOGZero() {
        let trip = WaypointProcessor.tripDurationToWaypointHours(
            distanceToMarkMeters: 50_000,
            effectiveSOGKnots: 0,
            leg1Hours: 1,
            leg2Hours: 2
        )
        XCTAssertNil(trip)
    }

    /// Regression: `DTM / currentTackVMC` with VMC ≈ 0.37 kn gave ~168 h while leg rows summed ~13 h.
    func testTinyVMCRhumbWouldBeAbsurdButLegSumIsReasonable() {
        let dtmMeters = 62.1 / toNauticalMiles
        let sog = 5.9
        let vmcIfMisused = 0.37
        let wrongHours = (dtmMeters * toNauticalMiles) / vmcIfMisused
        XCTAssertGreaterThan(wrongHours, 100)

        let legSum = WaypointProcessor.tripDurationToWaypointHours(
            distanceToMarkMeters: dtmMeters,
            effectiveSOGKnots: sog,
            leg1Hours: 10.43,
            leg2Hours: 3.45
        )!
        XCTAssertEqual(legSum, 13.88, accuracy: 0.02)
        XCTAssertLessThan(legSum, wrongHours / 5)
    }
}
