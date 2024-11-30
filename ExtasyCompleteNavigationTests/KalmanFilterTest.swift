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
}
