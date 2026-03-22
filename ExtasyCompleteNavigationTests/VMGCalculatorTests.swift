import XCTest
@testable import ExtasyCompleteNavigation

// MARK: - Helpers

extension VMGCalculatorTests {

    /// A small but valid polar diagram (5 wind speeds × 4 angles) for self-contained tests.
    /// Format: row 0 = header [0.0, TWS1, TWS2, …], subsequent rows = [TWA, speed1, speed2, …]
    static let minimalDiagram: [[Double]] = [
        [0.0,  5.0,  10.0, 15.0, 20.0],  // header: TWS columns
        [45.0, 4.5,   6.0,  7.0,  7.5],  // TWA=45
        [90.0, 5.0,   7.5,  8.5,  9.0],  // TWA=90
        [135.0, 4.0,  6.5,  8.0,  9.0],  // TWA=135
        [180.0, 2.0,  4.5,  6.5,  7.5],  // TWA=180
    ]

    /// Tack table rows sourced from the Beneteau First 40.7 VPP (optimal_tack.txt).
    /// Columns: TWS, OptUpTWA, OptDnTWA, MaxUpSpeed, MaxDnSpeed, MaxUpVMG, MaxDnVMG, StateThreshold
    static let first407TackTable: [[Double]] = [
        [ 4.0, 46.8, 140.7, 3.583, 3.263, 2.453, 2.527, 100.0],
        [ 6.0, 45.2, 143.2, 4.977, 4.672, 3.510, 3.739,  90.0],
        [ 8.0, 43.4, 146.3, 5.878, 5.775, 4.281, 4.806,  90.0],
        [10.0, 41.7, 149.9, 6.375, 6.574, 4.764, 5.685,  80.0],
        [12.0, 40.4, 155.4, 6.611, 6.993, 5.037, 6.358,  90.0],
        [14.0, 39.4, 164.8, 6.734, 7.195, 5.207, 6.943, 100.0],
        [16.0, 38.8, 168.3, 6.800, 7.600, 5.302, 7.441, 100.0],
        [20.0, 39.0, 170.5, 6.877, 8.384, 5.348, 8.268, 110.0],
        [25.0, 40.5, 168.3, 6.931, 9.458, 5.271, 9.263, 110.0],
        [30.0, 42.9, 157.3, 6.948, 11.617, 5.089, 10.716, 120.0],
    ]

    func makeCalculator() -> VMGCalculator {
        guard let calc = VMGCalculator(diagram: Self.minimalDiagram) else {
            XCTFail("Failed to create VMGCalculator from minimal diagram")
            fatalError()
        }
        return calc
    }

    func makeCalculatorWithTackTable() -> VMGCalculator {
        let calc = makeCalculator()
        calc.loadTackTable(from: Self.first407TackTable)
        return calc
    }
}

// MARK: - Tests

final class VMGCalculatorTests: XCTestCase {

    // MARK: B-spline formula

    func testCubicSplineConstantFunction() {
        let calc = makeCalculator()
        // For a constant function, the spline must return the constant regardless of u
        XCTAssertEqual(calc.eval_cubic_spline(u: 0.0,  xa: 5.0, xb: 5.0, xc: 5.0, xd: 5.0), 5.0, accuracy: 1e-9)
        XCTAssertEqual(calc.eval_cubic_spline(u: 0.5,  xa: 5.0, xb: 5.0, xc: 5.0, xd: 5.0), 5.0, accuracy: 1e-9)
        XCTAssertEqual(calc.eval_cubic_spline(u: 1.0,  xa: 5.0, xb: 5.0, xc: 5.0, xd: 5.0), 5.0, accuracy: 1e-9)
    }

    func testCubicSplineLinearFunctionAtMidpoint() {
        let calc = makeCalculator()
        // Linear data: xa=1, xb=2, xc=3, xd=4 → midpoint u=0.5 should be 2.5 (midpoint of xb and xc)
        // (xa + 4xb + xc)/6 at u=0 = (1+8+3)/6 = 2.0 = xb ✓ for linear
        // at u=0.5: c = 0.125*0 + 0.25*0 + 0.5*(−3+9) + (1+8+3) = 3 + 12 = 15 → 15/6 = 2.5
        XCTAssertEqual(calc.eval_cubic_spline(u: 0.5, xa: 1.0, xb: 2.0, xc: 3.0, xd: 4.0), 2.5, accuracy: 1e-9)
    }

    func testCubicSplineAtUZeroReturnsWeightedMean() {
        let calc = makeCalculator()
        // At u=0: result = (xa + 4*xb + xc) / 6
        let expected = (1.0 + 4.0 * 3.0 + 5.0) / 6.0
        XCTAssertEqual(calc.eval_cubic_spline(u: 0.0, xa: 1.0, xb: 3.0, xc: 5.0, xd: 7.0), expected, accuracy: 1e-9)
    }

    func testCubicSplineAtUOneReturnsWeightedMean() {
        let calc = makeCalculator()
        // At u=1: result = (xb + 4*xc + xd) / 6
        let expected = (3.0 + 4.0 * 5.0 + 7.0) / 6.0
        XCTAssertEqual(calc.eval_cubic_spline(u: 1.0, xa: 1.0, xb: 3.0, xc: 5.0, xd: 7.0), expected, accuracy: 1e-9)
    }

    func testCubicSplineInvalidUReturnsZero() {
        let calc = makeCalculator()
        XCTAssertEqual(calc.eval_cubic_spline(u: -0.1, xa: 1, xb: 2, xc: 3, xd: 4), 0.0)
        XCTAssertEqual(calc.eval_cubic_spline(u:  1.1, xa: 1, xb: 2, xc: 3, xd: 4), 0.0)
    }

    // MARK: VMGCalculator initialiser

    func testInitFailsOnEmptyDiagram() {
        XCTAssertNil(VMGCalculator(diagram: []))
    }

    func testInitFailsOnSingleRow() {
        XCTAssertNil(VMGCalculator(diagram: [[0.0, 5.0, 10.0]]))
    }

    func testInitParsesWindAndAngles() {
        let calc = makeCalculator()
        XCTAssertEqual(calc.wind,   [5.0, 10.0, 15.0, 20.0])
        XCTAssertEqual(calc.gradus, [45.0, 90.0, 135.0, 180.0])
        XCTAssertEqual(calc.diagram.count, 4)
    }

    // MARK: evaluateDiagram – boundary conditions

    func testEvaluateDiagramZeroWind() {
        let calc = makeCalculator()
        // windForce ≤ wind[0]=5.0 → returns 0
        XCTAssertEqual(calc.evaluateDiagram(windForce: 0.0, windAngle: 90.0), 0.0)
        XCTAssertEqual(calc.evaluateDiagram(windForce: 5.0, windAngle: 90.0), 0.0)
    }

    func testEvaluateDiagramExcessiveWind() {
        let calc = makeCalculator()
        // windForce > max wind (20.0) → no upper index found → returns 0
        XCTAssertEqual(calc.evaluateDiagram(windForce: 100.0, windAngle: 90.0), 0.0)
    }

    func testEvaluateDiagramTooSmallAngle() {
        let calc = makeCalculator()
        // Angle below gradus[0]=45° → guard i>0 fails → returns 0
        XCTAssertEqual(calc.evaluateDiagram(windForce: 10.0, windAngle: 10.0), 0.0)
    }

    func testEvaluateDiagramNegativeAngleIsFolded() {
        let calc = makeCalculator()
        // Negative angle is converted to abs(), so −90° == 90°
        let positive = calc.evaluateDiagram(windForce: 10.0, windAngle:  90.0)
        let negative = calc.evaluateDiagram(windForce: 10.0, windAngle: -90.0)
        XCTAssertEqual(positive, negative, accuracy: 1e-9)
    }

    func testEvaluateDiagramPortStarboardSymmetry() {
        let calc = makeCalculator()
        // 200° folded to 360-200=160° (in the 135–180 bucket)
        let a = calc.evaluateDiagram(windForce: 12.0, windAngle: 160.0)
        let b = calc.evaluateDiagram(windForce: 12.0, windAngle: 200.0)
        XCTAssertEqual(a, b, accuracy: 1e-9, "Port and starboard should be symmetric")
    }

    func testEvaluateDiagramReturnsPositiveValue() {
        let calc = makeCalculator()
        let speed = calc.evaluateDiagram(windForce: 12.0, windAngle: 90.0)
        XCTAssertGreaterThan(speed, 0.0)
    }

    func testEvaluateDiagramRegressionBeamReach() {
        let calc = makeCalculator()
        // TWS=7.5 (midpoint 5–10), TWA=90 — pre-computed B-spline result ≈ 7.051
        // Verified manually by applying the cubic B-spline formula to the minimal diagram above.
        let speed = calc.evaluateDiagram(windForce: 7.5, windAngle: 90.0)
        XCTAssertEqual(speed, 7.051, accuracy: 0.01)
    }

    func testEvaluateDiagramHigherWindMeansHigherSpeed() {
        let calc = makeCalculator()
        let low  = calc.evaluateDiagram(windForce:  8.0, windAngle: 90.0)
        let high = calc.evaluateDiagram(windForce: 14.0, windAngle: 90.0)
        XCTAssertLessThan(low, high, "Higher wind should produce higher beam-reach speed")
    }

    // MARK: determineSailingState

    func testSailingStateUpwind() {
        let calc = makeCalculator()
        XCTAssertEqual(calc.determineSailingState(trueWindAngle: 40.0, threshold: 80.0), "Upwind")
    }

    func testSailingStateAtThreshold() {
        let calc = makeCalculator()
        // TWA == threshold → Upwind (≤)
        XCTAssertEqual(calc.determineSailingState(trueWindAngle: 80.0, threshold: 80.0), "Upwind")
    }

    func testSailingStateDownwind() {
        let calc = makeCalculator()
        XCTAssertEqual(calc.determineSailingState(trueWindAngle: 120.0, threshold: 80.0), "Downwind")
    }

    // MARK: interpolateTackTableUsingSpline – boundaries

    func testTackTableEmptyReturnsNil() {
        let calc = makeCalculator()
        // No tack table loaded → all nils
        let result = calc.interpolateTackTableUsingSpline(for: 10.0, trueWindAngle: 45.0)
        XCTAssertNil(result.interpolatedRow)
        XCTAssertNil(result.sailingState)
    }

    /// windSpeed < min (4 kts) — guard finds no lower bound → returns nil.
    /// The "below min" edge-case branch inside the function is only reached when
    /// windSpeed equals exactly the first table entry (4.0). Below that, it returns nil.
    func testTackTableWindBelowTableMinReturnsNil() {
        let calc = makeCalculatorWithTackTable()
        let result = calc.interpolateTackTableUsingSpline(for: 2.0, trueWindAngle: 45.0)
        XCTAssertNil(result.interpolatedRow, "Wind below table minimum (4 kts) should return nil")
    }

    /// windSpeed == exactly the first entry (4.0) hits the "≤ first" edge-case → returns first row.
    func testTackTableWindAtExactMinReturnsFirstRow() {
        let calc = makeCalculatorWithTackTable()
        let result = calc.interpolateTackTableUsingSpline(for: 4.0, trueWindAngle: 45.0)
        XCTAssertNotNil(result.interpolatedRow)
        XCTAssertEqual(result.interpolatedRow?[1] ?? 0, 46.8, accuracy: 0.01, "Should return first row OptUpTWA")
    }

    /// windSpeed > max (30 kts) — guard finds no upper bound → returns nil.
    /// NOTE: windSpeed == 30.0 (the last entry) also returns nil because the guard requires
    /// an element strictly greater than windSpeed. This is a known limitation.
    func testTackTableWindAboveTableMaxReturnsNil() {
        let calc = makeCalculatorWithTackTable()
        let result = calc.interpolateTackTableUsingSpline(for: 40.0, trueWindAngle: 45.0)
        XCTAssertNil(result.interpolatedRow, "Wind above table maximum (30 kts) should return nil")
    }

    // MARK: interpolateTackTableUsingSpline – accuracy (First 40.7 VPP data)

    /// At exactly TWS=6 with u=0, the B-spline gives (xa + 4*xb + xc)/6.
    /// With xa=46.8, xb=45.2, xc=43.4 → (46.8 + 180.8 + 43.4)/6 = 271.0/6 ≈ 45.17°.
    /// The VPP table value is 45.2°, so the B-spline is within 0.05°.
    func testTackTableOptUpTWAAtTWS6() {
        let calc = makeCalculatorWithTackTable()
        let result = calc.interpolateTackTableUsingSpline(for: 6.0, trueWindAngle: 45.0)
        XCTAssertEqual(result.interpolatedRow?[1] ?? 0, 45.17, accuracy: 0.05,
                       "OptUpTWA at TWS=6 should be ≈45.17° (B-spline of VPP control points)")
    }

    /// OptDnTWA at TWS=6: (xa=140.7, xb=143.2, xc=146.3) → (140.7+572.8+146.3)/6 ≈ 143.3°
    func testTackTableOptDnTWAAtTWS6() {
        let calc = makeCalculatorWithTackTable()
        let result = calc.interpolateTackTableUsingSpline(for: 6.0, trueWindAngle: 45.0)
        XCTAssertEqual(result.interpolatedRow?[2] ?? 0, 143.3, accuracy: 0.1)
    }

    /// MaxUpVMG at TWS=6: (xa=2.453, xb=3.510, xc=4.281) → ≈3.46 kts
    func testTackTableMaxUpVMGAtTWS6() {
        let calc = makeCalculatorWithTackTable()
        let result = calc.interpolateTackTableUsingSpline(for: 6.0, trueWindAngle: 45.0)
        XCTAssertEqual(result.interpolatedRow?[5] ?? 0, 3.46, accuracy: 0.05)
    }

    /// MaxDnVMG at TWS=6: (xa=2.527, xb=3.739, xc=4.806) → ≈3.72 kts
    func testTackTableMaxDnVMGAtTWS6() {
        let calc = makeCalculatorWithTackTable()
        let result = calc.interpolateTackTableUsingSpline(for: 6.0, trueWindAngle: 45.0)
        XCTAssertEqual(result.interpolatedRow?[6] ?? 0, 3.72, accuracy: 0.05)
    }

    /// At TWS=9 (midpoint 8–10), OptUpTWA should interpolate between 43.4° and 41.7° → ≈42.6°
    func testTackTableOptUpTWAAtTWS9() {
        let calc = makeCalculatorWithTackTable()
        let result = calc.interpolateTackTableUsingSpline(for: 9.0, trueWindAngle: 45.0)
        XCTAssertEqual(result.interpolatedRow?[1] ?? 0, 42.56, accuracy: 0.05)
    }

    /// At TWS=9, MaxUpVMG should interpolate between 4.281 and 4.764 → ≈4.51 kts
    func testTackTableMaxUpVMGAtTWS9() {
        let calc = makeCalculatorWithTackTable()
        let result = calc.interpolateTackTableUsingSpline(for: 9.0, trueWindAngle: 45.0)
        XCTAssertEqual(result.interpolatedRow?[5] ?? 0, 4.51, accuracy: 0.05)
    }

    // MARK: interpolateTackTableUsingSpline – sailing state

    func testTackTableSailingStateUpwindAtTWS10() {
        let calc = makeCalculatorWithTackTable()
        // TWS=10, threshold interpolates near 80°; TWA=45° → Upwind
        let result = calc.interpolateTackTableUsingSpline(for: 10.0, trueWindAngle: 45.0)
        XCTAssertEqual(result.sailingState, "Upwind")
    }

    func testTackTableSailingStateDownwindAtTWS10() {
        let calc = makeCalculatorWithTackTable()
        // TWS=10, threshold ~80°; TWA=120° → Downwind
        let result = calc.interpolateTackTableUsingSpline(for: 10.0, trueWindAngle: 120.0)
        XCTAssertEqual(result.sailingState, "Downwind")
    }

    func testTackTableSailingLimitIsFirstRowThreshold() {
        let calc = makeCalculatorWithTackTable()
        // sailingStateLimit is always first-row threshold (100°) per current implementation
        let result = calc.interpolateTackTableUsingSpline(for: 10.0, trueWindAngle: 45.0)
        XCTAssertEqual(result.sailingStateLimit ?? 0, 100.0, accuracy: 0.01)
    }
}
