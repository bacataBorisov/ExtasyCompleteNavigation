import XCTest
@testable import ExtasyCompleteNavigation

final class KalmanFilterTests: XCTestCase {

    func testInitialization() {
        // Arrange
        let initialValue = 10.0
        let kalmanFilter = KalmanFilter(initialValue: initialValue, processNoise: 0.1, measurementNoise: 0.1)

        // Assert
        XCTAssertEqual(kalmanFilter.update(measurement: initialValue), initialValue, accuracy: 1e-5, "Initial value should be equal to the measurement.")
    }

    func testSmoothTransition() {
        // Arrange
        let kalmanFilter = KalmanFilter(initialValue: 0.0, processNoise: 0.1, measurementNoise: 0.1)
        let measurements = [10.0, 10.1, 10.3, 10.2, 10.4]
        var smoothedValues: [Double] = []

        // Act
        for measurement in measurements {
            smoothedValues.append(kalmanFilter.update(measurement: measurement))
        }

        // Assert
        XCTAssertTrue(smoothedValues.last! > 10.3 && smoothedValues.last! < 10.4, "Filter should smooth values gradually.")
    }

    func testHandlingNoisyMeasurements() {
        // Arrange
        let kalmanFilter = KalmanFilter(initialValue: 10.0, processNoise: 0.01, measurementNoise: 0.5)
        let noisyMeasurements = [10.0, 9.5, 10.5, 9.8, 10.2]
        var smoothedValues: [Double] = []

        // Act
        for measurement in noisyMeasurements {
            smoothedValues.append(kalmanFilter.update(measurement: measurement))
        }

        // Assert
        XCTAssertEqual(smoothedValues.last!, 10.1, accuracy: 0.2, "Filter should smooth out noisy measurements.")
    }

    func testRapidChanges() {
        // Arrange
        let kalmanFilter = KalmanFilter(initialValue: 10.0, processNoise: 0.1, measurementNoise: 0.1)
        let rapidChanges = [10.0, 50.0, 10.0, 50.0, 10.0]
        var smoothedValues: [Double] = []

        // Act
        for measurement in rapidChanges {
            smoothedValues.append(kalmanFilter.update(measurement: measurement))
        }

        // Assert
        XCTAssertTrue(smoothedValues.last! < 50.0, "Filter should mitigate rapid changes.")
    }

    func testStaticMeasurements() {
        // Arrange
        let kalmanFilter = KalmanFilter(initialValue: 10.0, processNoise: 0.1, measurementNoise: 0.1)
        let constantMeasurements = [10.0, 10.0, 10.0, 10.0, 10.0]
        let smoothedValues = constantMeasurements.map { kalmanFilter.update(measurement: $0) }

        // Assert
        XCTAssertTrue(smoothedValues.allSatisfy { abs($0 - 10.0) < 1e-5 }, "Filter should converge to the constant measurement.")
    }

    func testExtremeMeasurements() {
        // Arrange
        let kalmanFilter = KalmanFilter(initialValue: 10.0, processNoise: 0.1, measurementNoise: 0.1)
        let extremeMeasurements = [10.0, 1000.0, 10.0]
        var smoothedValues: [Double] = []

        // Act
        for measurement in extremeMeasurements {
            smoothedValues.append(kalmanFilter.update(measurement: measurement))
        }

        // Assert
        XCTAssertLessThan(smoothedValues[1], 1000.0, "Filter should dampen the impact of extreme values.")
    }

    func testTuningParameters() {
        // Arrange
        let kalmanFilter = KalmanFilter(initialValue: 10.0, processNoise: 0.5, measurementNoise: 0.1)
        let measurements = [10.0, 20.0, 30.0, 40.0, 50.0]
        var smoothedValues: [Double] = []

        // Act
        for measurement in measurements {
            smoothedValues.append(kalmanFilter.update(measurement: measurement))
        }

        // Assert
        XCTAssertTrue(smoothedValues.last! < 50.0 && smoothedValues.last! > 40.0, "Higher process noise should allow faster adaptation.")
    }

    // MARK: - Damping level mapping

    func testDampingLevel0IsMinimumR() {
        let params = KalmanFilter.params(forDampingLevel: 0)
        // R = 10^(0 * 7/11 − 3) = 10^(−3) = 0.001
        XCTAssertEqual(params.measurementNoise, 0.001, accuracy: 1e-9)
        XCTAssertEqual(params.processNoise, 1.0,  accuracy: 1e-9)
    }

    func testDampingLevel11IsMaximumR() {
        let params = KalmanFilter.params(forDampingLevel: 11)
        // R = 10^(11 * 7/11 − 3) = 10^(7 − 3) = 10^4 = 10000
        XCTAssertEqual(params.measurementNoise, 10_000.0, accuracy: 1e-6)
        XCTAssertEqual(params.processNoise, 1.0, accuracy: 1e-9)
    }

    func testDampingLevelClampsBelowZero() {
        let paramsNeg = KalmanFilter.params(forDampingLevel: -5)
        let paramsZero = KalmanFilter.params(forDampingLevel: 0)
        XCTAssertEqual(paramsNeg.measurementNoise, paramsZero.measurementNoise, accuracy: 1e-9)
    }

    func testDampingLevelClampsAbove11() {
        let paramsHigh = KalmanFilter.params(forDampingLevel: 99)
        let params11   = KalmanFilter.params(forDampingLevel: 11)
        XCTAssertEqual(paramsHigh.measurementNoise, params11.measurementNoise, accuracy: 1e-6)
    }

    func testDampingLevelIsMonotonicallyIncreasing() {
        var previous = KalmanFilter.params(forDampingLevel: 0).measurementNoise
        for level in 1...11 {
            let current = KalmanFilter.params(forDampingLevel: level).measurementNoise
            XCTAssertGreaterThan(current, previous,
                                 "R must increase monotonically — failed at level \(level)")
            previous = current
        }
    }

    func testDampingLevelSpansExpectedRange() {
        let min = KalmanFilter.params(forDampingLevel: 0).measurementNoise
        let max = KalmanFilter.params(forDampingLevel: 11).measurementNoise
        // Should span from 0.001 to 10000 (7 decades)
        XCTAssertEqual(min, 1e-3,  accuracy: 1e-9)
        XCTAssertEqual(max, 1e4,   accuracy: 1.0)
    }

    // MARK: - updateNoise

    func testUpdateNoiseAffectsFilterResponseWithoutReset() {
        let filter = KalmanFilter(initialValue: 0.0, processNoise: 1.0, measurementNoise: 1.0)

        // Converge to 100.0
        for _ in 0..<50 { _ = filter.update(measurement: 100.0) }

        // Switch to very high R (heavy smoothing) — step to 200.0 should lag a lot
        let (q, r) = KalmanFilter.params(forDampingLevel: 11)
        filter.updateNoise(processNoise: q, measurementNoise: r)
        var highDampingResult = 0.0
        for _ in 0..<10 { highDampingResult = filter.update(measurement: 200.0) }

        // Switch to very low R (raw response) — step back to 100.0 should react quickly
        let (q2, r2) = KalmanFilter.params(forDampingLevel: 0)
        filter.updateNoise(processNoise: q2, measurementNoise: r2)
        var lowDampingResult = 0.0
        for _ in 0..<10 { lowDampingResult = filter.update(measurement: 0.0) }

        XCTAssertLessThan(highDampingResult, 105.0,
                          "With max damping, filter should barely move from 100 after 10 steps toward 200")
        XCTAssertLessThan(lowDampingResult, 1.0,
                          "With zero damping, filter should quickly converge to 0")
    }
}
