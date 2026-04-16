import XCTest
@testable import ExtasyNavigationCore

final class VMGCalculatorTests: XCTestCase {
    static let minimalDiagram: [[Double]] = [
        [0.0, 5.0, 10.0, 15.0, 20.0],
        [45.0, 4.5, 6.0, 7.0, 7.5],
        [90.0, 5.0, 7.5, 8.5, 9.0],
        [135.0, 4.0, 6.5, 8.0, 9.0],
        [180.0, 2.0, 4.5, 6.5, 7.5]
    ]

    static let first407TackTable: [[Double]] = [
        [4.0, 46.8, 140.7, 3.583, 3.263, 2.453, 2.527, 100.0],
        [6.0, 45.2, 143.2, 4.977, 4.672, 3.510, 3.739, 90.0],
        [8.0, 43.4, 146.3, 5.878, 5.775, 4.281, 4.806, 90.0],
        [10.0, 41.7, 149.9, 6.375, 6.574, 4.764, 5.685, 80.0],
        [12.0, 40.4, 155.4, 6.611, 6.993, 5.037, 6.358, 90.0]
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

    func testCubicSplineLinearFunctionAtMidpoint() {
        let calc = makeCalculator()
        XCTAssertEqual(calc.eval_cubic_spline(u: 0.5, xa: 1.0, xb: 2.0, xc: 3.0, xd: 4.0), 2.5, accuracy: 1e-9)
    }

    func testTackTableWindBelowMinimumReturnsNil() {
        let calc = makeCalculatorWithTackTable()
        let result = calc.interpolateTackTableUsingSpline(for: 2.0, trueWindAngle: 45.0)
        XCTAssertNil(result.interpolatedRow)
        XCTAssertNil(result.sailingState)
        XCTAssertNil(result.sailingStateLimit)
    }

    func testTackTableWindAtExactMinimumReturnsFirstRow() {
        let calc = makeCalculatorWithTackTable()
        let result = calc.interpolateTackTableUsingSpline(for: 4.0, trueWindAngle: 45.0)
        XCTAssertEqual(result.interpolatedRow?[1] ?? 0.0, 46.8, accuracy: 0.01)
        XCTAssertEqual(result.sailingState, "Upwind")
        XCTAssertEqual(result.sailingStateLimit ?? 0.0, 100.0, accuracy: 0.01)
    }

    func testTackTableWindAboveMaximumReturnsNil() {
        let calc = makeCalculatorWithTackTable()
        let result = calc.interpolateTackTableUsingSpline(for: 40.0, trueWindAngle: 45.0)
        XCTAssertNil(result.interpolatedRow)
    }

    func testEvaluateDiagramRegressionBeamReach() {
        let calc = makeCalculator()
        let speed = calc.evaluateDiagram(windForce: 7.5, windAngle: 90.0)
        XCTAssertEqual(speed, 7.051, accuracy: 0.01)
    }

    func testTackTableOptUpTWAAtTWS9() {
        let calc = makeCalculatorWithTackTable()
        let result = calc.interpolateTackTableUsingSpline(for: 9.0, trueWindAngle: 45.0)
        XCTAssertEqual(result.interpolatedRow?[1] ?? 0, 42.56, accuracy: 0.05)
    }

    func testTackTableSailingStateDownwindAtInterpolatedWind() {
        let calc = makeCalculatorWithTackTable()
        let result = calc.interpolateTackTableUsingSpline(for: 9.0, trueWindAngle: 120.0)
        XCTAssertEqual(result.sailingState, "Downwind")
    }

    // MARK: - Init / malformed diagram

    func testInitReturnsNilForEmptyDiagram() {
        XCTAssertNil(VMGCalculator(diagram: []))
    }

    func testInitReturnsNilForSingleRowDiagram() {
        XCTAssertNil(VMGCalculator(diagram: [[0.0, 5.0, 10.0]]))
    }

    func testInitReturnsNilWhenWindHeaderRowHasNoTwsSamples() {
        XCTAssertNil(VMGCalculator(diagram: [[0.0], [45.0, 4.0]]))
    }

    // MARK: - Cubic spline edge cases

    func testCubicSplineReturnsZeroWhenUIsBelowZero() {
        let calc = makeCalculator()
        XCTAssertEqual(calc.eval_cubic_spline(u: -0.01, xa: 1, xb: 2, xc: 3, xd: 4), 0, accuracy: 0)
    }

    func testCubicSplineReturnsZeroWhenUIsAboveOne() {
        let calc = makeCalculator()
        XCTAssertEqual(calc.eval_cubic_spline(u: 1.01, xa: 1, xb: 2, xc: 3, xd: 4), 0, accuracy: 0)
    }

    func testCubicSplineEndpointsMatchCatmullRomWeights() {
        let calc = makeCalculator()
        let xa = 10.0, xb = 20.0, xc = 30.0, xd = 40.0
        let atZero = (xa + 4 * xb + xc) / 6.0
        XCTAssertEqual(calc.eval_cubic_spline(u: 0, xa: xa, xb: xb, xc: xc, xd: xd), atZero, accuracy: 1e-9)
        XCTAssertEqual(calc.eval_cubic_spline(u: 1, xa: xa, xb: xb, xc: xc, xd: xd), xc, accuracy: 1e-9)
    }

    // MARK: - evaluateDiagram boundaries

    func testEvaluateDiagramReturnsZeroWhenWindBelowGridMinimum() {
        let calc = makeCalculator()
        XCTAssertEqual(calc.evaluateDiagram(windForce: 4.0, windAngle: 90.0), 0, accuracy: 0)
    }

    func testEvaluateDiagramReturnsZeroWhenWindAboveGridMaximum() {
        let calc = makeCalculator()
        XCTAssertEqual(calc.evaluateDiagram(windForce: 25.0, windAngle: 90.0), 0, accuracy: 0)
    }

    func testEvaluateDiagramNormalizesAngleGreaterThan360() {
        let calc = makeCalculator()
        let a = calc.evaluateDiagram(windForce: 7.5, windAngle: 90.0)
        let b = calc.evaluateDiagram(windForce: 7.5, windAngle: 450.0)
        XCTAssertEqual(a, b, accuracy: 1e-9)
    }

    func testEvaluateDiagramMirrorsObtuseTrueWindAngle() {
        let calc = makeCalculator()
        let acute = calc.evaluateDiagram(windForce: 7.5, windAngle: 90.0)
        let obtuse = calc.evaluateDiagram(windForce: 7.5, windAngle: 270.0)
        XCTAssertEqual(acute, obtuse, accuracy: 1e-9)
    }

    func testEvaluateDiagramUsesAbsoluteNegativeAngle() {
        let calc = makeCalculator()
        let pos = calc.evaluateDiagram(windForce: 7.5, windAngle: 90.0)
        let neg = calc.evaluateDiagram(windForce: 7.5, windAngle: -90.0)
        XCTAssertEqual(pos, neg, accuracy: 1e-9)
    }

    func testEvaluateDiagramReturnsZeroWhenAnglePastPolarRange() {
        let calc = makeCalculator()
        XCTAssertEqual(calc.evaluateDiagram(windForce: 7.5, windAngle: 1.0), 0, accuracy: 0)
    }

    // MARK: - polarBoatSpeedCurve

    func testPolarBoatSpeedCurveMatchesGradusCount() {
        let calc = makeCalculator()
        let curve = calc.polarBoatSpeedCurve(forTrueWindSpeedKnots: 7.5)
        XCTAssertEqual(curve.count, calc.gradus.count)
        guard let first = curve.first else {
            XCTFail("expected non-empty polar curve")
            return
        }
        XCTAssertEqual(first.twa, 45.0, accuracy: 1e-9)
    }

    // MARK: - Sailing state / tack table

    func testDetermineSailingStateBoundaryAtThreshold() {
        let calc = makeCalculator()
        XCTAssertEqual(calc.determineSailingState(trueWindAngle: 90.0, threshold: 90.0), "Upwind")
        XCTAssertEqual(calc.determineSailingState(trueWindAngle: -90.0, threshold: 90.0), "Upwind")
        XCTAssertEqual(calc.determineSailingState(trueWindAngle: 90.01, threshold: 90.0), "Downwind")
    }

    func testInterpolateTackTableWhenTableEmpty() {
        let calc = makeCalculator()
        let result = calc.interpolateTackTableUsingSpline(for: 8.0, trueWindAngle: 45.0)
        XCTAssertNil(result.interpolatedRow)
        XCTAssertNil(result.sailingState)
    }

    func testInterpolateTackTableNearMaxWindStillInterpolates() {
        let calc = makeCalculatorWithTackTable()
        let result = calc.interpolateTackTableUsingSpline(for: 11.5, trueWindAngle: 45.0)
        guard let row = result.interpolatedRow else {
            XCTFail("expected interpolated row near max wind")
            return
        }
        XCTAssertEqual(row[0], 11.5, accuracy: 1e-9)
    }

    func testReadOptimalTackTableWithoutBundleResourceReturnsFalse() {
        let calc = makeCalculator()
        XCTAssertFalse(calc.readOptimalTackTable(fileName: "nonexistent_tack_table_xyz"))
    }
}
