import Foundation

class WindProcessor {
    // Separate instance to keep the last known valid data
    private var lastKnownWindData: WindData = WindData()
    
    // Kalman Filters for smoothing wind data
    private var kalmanFilterAppWindForce = KalmanFilter(initialValue: 0.0)
    //slightly adjusted for less filtering - need more tests
    private var kalmanFilterTrueWindForce = KalmanFilter(initialValue: 0.0, processNoise: 1e-3, measurementNoise: 1e-2)
    private var kalmanFilterAppWindAngle = KalmanFilter(initialValue: 0.0)
    //slightly adjusted for less filtering - need more tests
    private var kalmanFilterTrueWindAngle = KalmanFilter(initialValue: 0.0, processNoise: 1e-3, measurementNoise: 1e-2)
    
    // Process wind data (general function)
    func processWindSentence(_ splitStr: [String], compassData: CompassData?, hydroData: HydroData?) -> WindData? {
        guard splitStr.count >= 7, splitStr[6] == "A" else {
            print("Invalid MWV Sentence!")
            return lastKnownWindData
        }
        
        // Get the last known wind data
        var windData = lastKnownWindData
        let heading = compassData?.normalizedHeading ?? 0
        let speedThroughWater = hydroData?.boatSpeedLag ?? 0
        
        // Process Apparent Wind (AW) or True Wind (TW) based on identifier
        if splitStr[3] == "R" {
            windData = processApparentWind(splitStr, windData: windData, heading: heading)
        } else if splitStr[3] == "T" {
            windData = processTrueWind(splitStr, windData: windData, heading: heading)
        }
        
        // If true wind is available, calculate apparent wind based on true wind data
        if let twa = windData.trueWindAngle, let twf = windData.trueWindForce {
            windData = calculateApparentWind(windData, twa: twa, twf: twf, stw: speedThroughWater, heading: heading)
        }
        
        windData.lastUpdated = Date() // Update watchdog timer
        lastKnownWindData = windData // Store the last known valid data
        return windData
    }
    
    // Process apparent wind data
    private func processApparentWind(_ splitStr: [String], windData: WindData, heading: Double) -> WindData {
        var updatedWindData = windData
        
        // Apply Kalman filter to apparent wind force
        if let rawAppWindForce = Double(splitStr[4]) {
            updatedWindData.apparentWindForce = kalmanFilterAppWindForce.update(measurement: rawAppWindForce)
        }
        
        // Apply Kalman filter to apparent wind angle
        if let rawAWA = Double(splitStr[2]) {
            updatedWindData.apparentWindAngle = kalmanFilterAppWindAngle.update(measurement: normalizeAngle(rawAWA))
            if let unwrappedAWA = updatedWindData.apparentWindAngle,
               let unwrappedAWF = updatedWindData.apparentWindForce {
                updatedWindData.apparentWindDirection = calculateWindDirection(unwrappedAWF, unwrappedAWA, heading)
            }
        }
        
        return updatedWindData
    }
    
    // Process true wind data
    private func processTrueWind(_ splitStr: [String], windData: WindData, heading: Double) -> WindData {
        var updatedWindData = windData
        
        // Apply Kalman filter to true wind force
        if let rawTrueWindForce = Double(splitStr[4]) {
            updatedWindData.trueWindForce = kalmanFilterTrueWindForce.update(measurement: rawTrueWindForce)
        }
        
        // Apply Kalman filter to true wind angle
        if let rawTWA = Double(splitStr[2]) {
            updatedWindData.trueWindAngle = kalmanFilterTrueWindAngle.update(measurement: normalizeAngle(rawTWA))
            if let unwrappedTWA = updatedWindData.trueWindAngle, let unwrappedTWF = updatedWindData.trueWindForce {
                updatedWindData.trueWindDirection = calculateWindDirection(unwrappedTWF, unwrappedTWA, heading)
            }
        }
        
        return updatedWindData
    }
    
    // Calculate Apparent Wind from True Wind
    private func calculateApparentWind(_ windData: WindData, twa: Double, twf: Double, stw: Double, heading: Double) -> WindData {
        var updatedWindData = windData
        
        // Calculate Apparent Wind Speed
        let apparentSpeed = sqrt(pow(twf, 2) + pow(stw, 2) + 2 * twf * stw * cos(deg2rad(twa)))
        updatedWindData.apparentWindForce = apparentSpeed
        
        // Calculate Apparent Wind Angle
        let apparentAngle = atan2(twf * sin(deg2rad(twa)), stw + twf * cos(deg2rad(twa)))
        updatedWindData.apparentWindAngle = normalizeAngle(rad2deg(apparentAngle))
        
        // Calculate Apparent Wind Direction
        if let awa = updatedWindData.apparentWindAngle {
            updatedWindData.apparentWindDirection = calculateWindDirection(apparentSpeed, awa, heading)
        }
        
        return updatedWindData
    }
    
    // MARK: - Helper Functions
    
    private func calculateWindDirection(_ force: Double, _ angle: Double, _ heading: Double) -> Double {
        guard force > 0.001 else { return 0 }
        return normalizeAngle(angle + heading)
    }
    
    private func normalizeAngle(_ angle: Double) -> Double {
        var normalized = angle.truncatingRemainder(dividingBy: 360)
        if normalized < 0 { normalized += 360 }
        return normalized
    }
    
    private func deg2rad(_ degrees: Double) -> Double {
        return degrees * .pi / 180
    }
    
    private func rad2deg(_ radians: Double) -> Double {
        return radians * 180 / .pi
    }
}
