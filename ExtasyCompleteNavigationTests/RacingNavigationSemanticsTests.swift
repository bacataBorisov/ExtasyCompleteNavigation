import XCTest
@testable import ExtasyCompleteNavigation

final class RacingNavigationSemanticsTests: XCTestCase {

    func testWaypointSelectedPrefersMarkApproachOverPolar() {
        XCTAssertEqual(
            RacingNavigationSemantics.sailingStateForWaypointTackUI(
                isWaypointTargetSelected: true,
                waypointApproachState: "Upwind",
                polarSailingState: "Downwind"
            ),
            "Upwind"
        )
    }

    func testNoWaypointFallsBackToPolar() {
        XCTAssertEqual(
            RacingNavigationSemantics.sailingStateForWaypointTackUI(
                isWaypointTargetSelected: false,
                waypointApproachState: "Upwind",
                polarSailingState: "Downwind"
            ),
            "Downwind"
        )
    }

    func testMarkApproachRuleMatchesWaypointProcessorAngles() {
        let twd = 86.0
        let limit = 93.0
        // Mark almost upwind of boat → approach upwind
        XCTAssertTrue(
            RacingNavigationSemantics.markApproachIsUpwind(
                trueMarkBearingDegrees: 95,
                trueWindDirectionDegrees: twd,
                sailingStateLimitDegrees: limit
            )
        )
        // Mark abeam / downwind sector → approach downwind
        XCTAssertFalse(
            RacingNavigationSemantics.markApproachIsUpwind(
                trueMarkBearingDegrees: 260,
                trueWindDirectionDegrees: twd,
                sailingStateLimitDegrees: limit
            )
        )
    }

    func testTackTargetHeadingsMirrorTackAlignmentBarFormulas() {
        let twd = 135.0
        let up = 42.0
        let dn = 140.0
        XCTAssertEqual(
            RacingNavigationSemantics.starboardTackTargetHeading(
                trueWindDirection: twd, optimalUpTWA: up, optimalDnTWA: dn, sailingState: "Upwind"
            ),
            normalizeAngle(twd - up),
            accuracy: 1e-9
        )
        XCTAssertEqual(
            RacingNavigationSemantics.portTackTargetHeading(
                trueWindDirection: twd, optimalUpTWA: up, optimalDnTWA: dn, sailingState: "Upwind"
            ),
            normalizeAngle(twd + up),
            accuracy: 1e-9
        )
        XCTAssertEqual(
            RacingNavigationSemantics.starboardTackTargetHeading(
                trueWindDirection: twd, optimalUpTWA: up, optimalDnTWA: dn, sailingState: "Downwind"
            ),
            normalizeAngle(twd - dn),
            accuracy: 1e-9
        )
    }

    /// Documents an edge case: polar says *downwind* angles while the mark is still *upwind*
    /// of the boat (bearing-to-mark vs TWD inside the limit). Laylines use mark mode; if the
    /// tack bar used polar-only up/down, targets would disagree with the chart by tens of degrees.
    func testPolarDownwindAndMarkUpwindCanCoexist() {
        let twd = 0.0
        let markBearing = 45.0
        let limit = 90.0
        XCTAssertTrue(
            RacingNavigationSemantics.markApproachIsUpwind(
                trueMarkBearingDegrees: markBearing,
                trueWindDirectionDegrees: twd,
                sailingStateLimitDegrees: limit
            )
        )
        let uiWhenSelected = RacingNavigationSemantics.sailingStateForWaypointTackUI(
            isWaypointTargetSelected: true,
            waypointApproachState: "Upwind",
            polarSailingState: "Downwind"
        )
        XCTAssertEqual(uiWhenSelected, "Upwind")

        let stbdUp = RacingNavigationSemantics.starboardTackTargetHeading(
            trueWindDirection: twd, optimalUpTWA: 40, optimalDnTWA: 150, sailingState: "Upwind"
        )
        let stbdDn = RacingNavigationSemantics.starboardTackTargetHeading(
            trueWindDirection: twd, optimalUpTWA: 40, optimalDnTWA: 150, sailingState: "Downwind"
        )
        XCTAssertGreaterThan(abs(normalizeAngleTo180(stbdUp - stbdDn)), 1.0, "Different modes must shift target headings.")
    }
}
