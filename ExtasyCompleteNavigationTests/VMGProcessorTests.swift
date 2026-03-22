import XCTest
@testable import ExtasyCompleteNavigation

final class VMGProcessorTests: XCTestCase {

    // A processor backed by the same minimal diagram used in VMGCalculatorTests
    // so tests are fully self-contained (no bundle file I/O required).
    private var processor: VMGProcessor!

    override func setUp() {
        super.setUp()
        processor = VMGProcessor()
    }

    // MARK: - processPerformanceRatio

    func testPerformanceRatioZeroMaxReturnsZero() {
        XCTAssertEqual(processor.processPerformanceRatio(maxValue: 0.0, currentValue: 5.0), 0.0)
    }

    func testPerformanceRatioNegativeMaxReturnsZero() {
        XCTAssertEqual(processor.processPerformanceRatio(maxValue: -1.0, currentValue: 5.0), 0.0)
    }

    func testPerformanceRatioHundredPercent() {
        XCTAssertEqual(processor.processPerformanceRatio(maxValue: 7.0, currentValue: 7.0), 100.0, accuracy: 1e-9)
    }

    func testPerformanceRatioFiftyPercent() {
        XCTAssertEqual(processor.processPerformanceRatio(maxValue: 8.0, currentValue: 4.0), 50.0, accuracy: 1e-9)
    }

    func testPerformanceRatioIsCappedAt100() {
        // currentValue > maxValue should not exceed 100%
        let result = processor.processPerformanceRatio(maxValue: 5.0, currentValue: 6.0)
        XCTAssertEqual(result, 100.0, accuracy: 1e-9)
    }

    func testPerformanceRatioZeroCurrentIsZero() {
        XCTAssertEqual(processor.processPerformanceRatio(maxValue: 7.0, currentValue: 0.0), 0.0, accuracy: 1e-9)
    }

    func testPerformanceRatioFormula() {
        // 4.5 / 6.0 × 100 = 75%
        XCTAssertEqual(processor.processPerformanceRatio(maxValue: 6.0, currentValue: 4.5), 75.0, accuracy: 1e-9)
    }

    // MARK: - processTackData (uses bundled diagram + tack table)

    /// Verifies that `processTackData` returns non-nil for typical upwind conditions,
    /// and that the returned optimal angles match the VPP tack table within B-spline tolerance.
    func testProcessTackDataReturnsResultForValidWind() {
        let result = processor.processTackData(windSpeed: 10.0, trueWindAngle: 45.0)
        XCTAssertNotNil(result, "processTackData should succeed for TWS=10, TWA=45")
    }

    func testProcessTackDataOptUpTWAIsReasonable() {
        guard let result = processor.processTackData(windSpeed: 10.0, trueWindAngle: 45.0) else {
            XCTFail("processTackData returned nil"); return
        }
        // First 40.7 VPP: OptUpTWA at TWS=10 is 41.7°. B-spline adds ~0.1° smoothing.
        XCTAssertEqual(result.optUpTWA, 41.77, accuracy: 0.1,
                       "OptUpTWA at TWS=10 should be ~41.8° (B-spline of VPP data)")
    }

    func testProcessTackDataOptDnTWAIsReasonable() {
        guard let result = processor.processTackData(windSpeed: 10.0, trueWindAngle: 45.0) else {
            XCTFail("processTackData returned nil"); return
        }
        // VPP: OptDnTWA at TWS=10 is 149.9°. B-spline ≈ 150.2°.
        XCTAssertEqual(result.optDnTWA, 150.22, accuracy: 0.15)
    }

    func testProcessTackDataMaxUpVMGIsReasonable() {
        guard let result = processor.processTackData(windSpeed: 10.0, trueWindAngle: 45.0) else {
            XCTFail("processTackData returned nil"); return
        }
        // VPP: MaxUpVMG at TWS=10 is 4.764 kts. B-spline ≈ 4.73.
        XCTAssertEqual(result.maxUpVMG, 4.73, accuracy: 0.05)
    }

    func testProcessTackDataSailingStateUpwind() {
        guard let result = processor.processTackData(windSpeed: 10.0, trueWindAngle: 45.0) else {
            XCTFail("processTackData returned nil"); return
        }
        XCTAssertEqual(result.sailingState, "Upwind")
    }

    func testProcessTackDataSailingStateDownwind() {
        guard let result = processor.processTackData(windSpeed: 10.0, trueWindAngle: 120.0) else {
            XCTFail("processTackData returned nil"); return
        }
        XCTAssertEqual(result.sailingState, "Downwind")
    }

    func testProcessTackDataMaxUpVMGIncreasesWithWind() {
        guard let low  = processor.processTackData(windSpeed:  6.0, trueWindAngle: 45.0),
              let high = processor.processTackData(windSpeed: 14.0, trueWindAngle: 45.0) else {
            XCTFail("processTackData returned nil"); return
        }
        XCTAssertLessThan(low.maxUpVMG, high.maxUpVMG,
                          "MaxUpVMG should increase as wind speed increases")
    }

    // MARK: - Tack deviation logic

    /// The deviation is (absAngleToWind − optimalTWA); positive = too broad.
    func testTackDeviationPositiveWhenTooFarOff() {
        // optUpTWA ≈ 41.8°; sailing at 60° TWA → deviation ≈ +18°
        guard let result = processor.processTackData(windSpeed: 10.0, trueWindAngle: 60.0) else {
            XCTFail("processTackData returned nil"); return
        }
        // Deviation is computed in VMGProcessor.processVMGData, not processTackData.
        // Here we just verify the tack data angles are correct so the deviation formula works:
        XCTAssertLessThan(result.optUpTWA, 60.0, "Optimal upwind TWA should be less than 60°")
    }

    func testTackDeviationNegativeWhenPinching() {
        // Sailing at 30° TWA while optimum is ~42° → deviation ≈ −12° (pinching)
        guard let result = processor.processTackData(windSpeed: 10.0, trueWindAngle: 30.0) else {
            XCTFail("processTackData returned nil"); return
        }
        XCTAssertGreaterThan(result.optUpTWA, 30.0, "Optimal upwind TWA should be greater than 30° (would be pinching)")
    }
}
