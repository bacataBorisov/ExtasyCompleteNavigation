import Foundation

class WindProcessor {
    private var lastKnownWindData: WindData = WindData()

    private var kalmanFilterAppWindForce = KalmanFilter(initialValue: 0.0)
    private var kalmanFilterTrueWindForce = KalmanFilter(initialValue: 0.0, processNoise: 1e-3, measurementNoise: 1e-2)
    private var kalmanFilterAppWindAngle = KalmanFilter(initialValue: 0.0)
    private var kalmanFilterTrueWindAngle = KalmanFilter(initialValue: 0.0, processNoise: 1e-3, measurementNoise: 1e-2)

    func processWindSentence(_ splitStr: [String], compassData: CompassData?, hydroData: HydroData?) -> WindData? {
        guard splitStr.count >= 7, splitStr[6] == "A" else {
            print("Invalid MWV Sentence!")
            return lastKnownWindData
        }

        var windData = lastKnownWindData
        let heading = compassData?.normalizedHeading ?? 0
        let speedThroughWater = hydroData?.boatSpeedLag ?? 0

        if splitStr[3] == "R" {
            windData = processApparentWind(splitStr, windData: windData, heading: heading, stw: speedThroughWater)
        } else if splitStr[3] == "T" {
            windData = processTrueWind(splitStr, windData: windData, heading: heading, stw: speedThroughWater)
        }

        windData.lastUpdated = Date()
        lastKnownWindData = windData
        return windData
    }

    // Process apparent wind data and calculate true wind
    private func processApparentWind(_ splitStr: [String], windData: WindData, heading: Double, stw: Double) -> WindData {
        var updatedWindData = windData

        if let rawAppWindForce = Double(splitStr[4]) {
            updatedWindData.rawApparentWindForce = rawAppWindForce
            updatedWindData.apparentWindForce = kalmanFilterAppWindForce.update(measurement: rawAppWindForce)
        }

        if let rawAWA = Double(splitStr[2]) {
            let normalizedRawAWA = normalizeAngle(rawAWA)
            updatedWindData.rawApparentWindAngle = normalizedRawAWA

            if let rawForce = updatedWindData.rawApparentWindForce {
                updatedWindData.rawApparentWindDirection = calculateWindDirection(rawForce, normalizedRawAWA, heading)
            }

            updatedWindData.apparentWindAngle = kalmanFilterAppWindAngle.update(measurement: normalizedRawAWA)

            if let awa = updatedWindData.apparentWindAngle, let awf = updatedWindData.apparentWindForce {
                updatedWindData.apparentWindDirection = calculateWindDirection(awf, awa, heading)
            }
        }

        // Calculate True Wind from Apparent Wind
        updatedWindData = calculateTrueWind(updatedWindData, awa: updatedWindData.apparentWindAngle, awf: updatedWindData.apparentWindForce, stw: stw, heading: heading)

        return updatedWindData
    }

    // Process true wind data and calculate apparent wind
    private func processTrueWind(_ splitStr: [String], windData: WindData, heading: Double, stw: Double) -> WindData {
        var updatedWindData = windData

        if let rawTrueWindForce = Double(splitStr[4]) {
            updatedWindData.rawTrueWindForce = rawTrueWindForce
            updatedWindData.trueWindForce = kalmanFilterTrueWindForce.update(measurement: rawTrueWindForce)
        }

        if let rawTWA = Double(splitStr[2]) {
            let normalizedRawTWA = normalizeAngle(rawTWA)
            updatedWindData.rawTrueWindAngle = normalizedRawTWA

            if let rawForce = updatedWindData.rawTrueWindForce {
                updatedWindData.rawTrueWindDirection = calculateWindDirection(rawForce, normalizedRawTWA, heading)
            }

            updatedWindData.trueWindAngle = kalmanFilterTrueWindAngle.update(measurement: normalizedRawTWA)

            if let twa = updatedWindData.trueWindAngle, let twf = updatedWindData.trueWindForce {
                updatedWindData.trueWindDirection = calculateWindDirection(twf, twa, heading)
            }
        }

        // Calculate Apparent Wind from True Wind
        updatedWindData = calculateApparentWind(updatedWindData, twa: updatedWindData.trueWindAngle, twf: updatedWindData.trueWindForce, stw: stw, heading: heading)

        return updatedWindData
    }

    // Calculate True Wind from Apparent Wind
    private func calculateTrueWind(_ windData: WindData, awa: Double?, awf: Double?, stw: Double, heading: Double) -> WindData {
        var updatedWindData = windData

        guard let awa = awa, let awf = awf else { return updatedWindData }

        // Calculate raw true wind speed
        let rawTrueWindSpeed = sqrt(pow(awf, 2) + pow(stw, 2) - 2 * awf * stw * cos(toRadians(awa)))
        updatedWindData.rawTrueWindForce = rawTrueWindSpeed
        updatedWindData.trueWindForce = kalmanFilterTrueWindForce.update(measurement: rawTrueWindSpeed)

        // Calculate raw true wind angle
        let rawTrueWindAngle = atan2(awf * sin(toRadians(awa)), stw - awf * cos(toRadians(awa)))
        let normalizedRawTWA = normalizeAngle(toDegrees(rawTrueWindAngle))
        updatedWindData.rawTrueWindAngle = normalizedRawTWA
        updatedWindData.trueWindAngle = kalmanFilterTrueWindAngle.update(measurement: normalizedRawTWA)

        // Calculate raw true wind direction
        updatedWindData.rawTrueWindDirection = calculateWindDirection(rawTrueWindSpeed, normalizedRawTWA, heading)

        // Calculate filtered true wind direction
        if let twa = updatedWindData.trueWindAngle {
            updatedWindData.trueWindDirection = calculateWindDirection(updatedWindData.trueWindForce, twa, heading)
        }

        return updatedWindData
    }

    // Calculate Apparent Wind from True Wind
    private func calculateApparentWind(_ windData: WindData, twa: Double?, twf: Double?, stw: Double, heading: Double) -> WindData {
        var updatedWindData = windData

        guard let twa = twa, let twf = twf else { return updatedWindData }

        // Calculate raw apparent wind speed
        let rawApparentSpeed = sqrt(pow(twf, 2) + pow(stw, 2) + 2 * twf * stw * cos(toRadians(twa)))
        updatedWindData.rawApparentWindForce = rawApparentSpeed
        updatedWindData.apparentWindForce = kalmanFilterAppWindForce.update(measurement: rawApparentSpeed)

        // Calculate raw apparent wind angle
        let rawApparentAngle = atan2(twf * sin(toRadians(twa)), stw + twf * cos(toRadians(twa)))
        let normalizedRawAWA = normalizeAngle(toDegrees(rawApparentAngle))
        updatedWindData.rawApparentWindAngle = normalizedRawAWA
        updatedWindData.apparentWindAngle = kalmanFilterAppWindAngle.update(measurement: normalizedRawAWA)

        // Calculate raw apparent wind direction
        updatedWindData.rawApparentWindDirection = calculateWindDirection(rawApparentSpeed, normalizedRawAWA, heading)

        // Calculate filtered apparent wind direction
        if let awa = updatedWindData.apparentWindAngle {
            updatedWindData.apparentWindDirection = calculateWindDirection(updatedWindData.apparentWindForce, awa, heading)
        }

        return updatedWindData
    }

    // MARK: - Helper Functions

    private func calculateWindDirection(_ force: Double?, _ angle: Double, _ heading: Double) -> Double {
        guard let force = force, force > 0.001 else { return 0 }
        return normalizeAngle(angle + heading)
    }
}
