import Foundation

class CompassProcessor {
    
    // Kalman filter for smoothing the normalized heading
    private var normalizedHeadingFilter: KalmanFilter?
    
    // Initialize the CompassProcessor with an optimized Kalman filter
    init() {
        // Increase process noise for faster response and slightly decrease measurement noise
        normalizedHeadingFilter = KalmanFilter(initialValue: 0.0, processNoise: 1e-4, measurementNoise: 5e-2)
    }
    
    // Processes the magnetic heading from an NMEA sentence
    func processCompassSentence(_ splitStr: [String]) -> CompassData? {
        guard splitStr.count >= 7,
              let rawHeading = Double(splitStr[2]),
              let variation = Double(splitStr[5]) else {
            print("Invalid HDG Sentence!")
            return nil
        }
        
        var compassData = CompassData()
        
        // Apply variation correction
        let direction = splitStr[6]
        let correctedHeading = correctedHeading(heading: rawHeading, variation: variation, direction: direction)
        
        // Update the raw value
        compassData.rawMagneticHeading = correctedHeading
        
        // Normalize the corrected heading
        let normalized = normalizeAngle(correctedHeading)
        
        // Update the raw normalized heading
        compassData.rawNormalizedHeading = normalized
        
        // Apply Kalman filtering to the normalized heading
        if let filteredNormalizedHeading = normalizedHeadingFilter?.update(measurement: normalized) {
            compassData.normalizedHeading = filteredNormalizedHeading
        } else {
            compassData.normalizedHeading = normalized // Fallback to raw value if filtering fails
        }
        
        return compassData
    }
    
    // Corrects the heading based on magnetic variation
    private func correctedHeading(heading: Double, variation: Double, direction: String) -> Double {
        return (direction == "E") ? (heading + variation) : (heading - variation)
    }
}
