import Foundation

class WindProcessor {
    private var lastKnownWindData: WindData = WindData()

    
    //NOTE: - Kalman coeff. set to mimic as close as possible to the input values. Adjustment to be made in a later stage
    private var kalmanFilterAppWindForce = KalmanFilter(initialValue: 0.0, processNoise: 1.0, measurementNoise: 1e-9)
    private var kalmanFilterTrueWindForce = KalmanFilter(initialValue: 0.0, processNoise: 1.0, measurementNoise: 1e-9)
    private var kalmanFilterAppWindAngle = KalmanFilter(initialValue: 0.0, processNoise: 1.0, measurementNoise: 1e-9)
    private var kalmanFilterTrueWindAngle = KalmanFilter(initialValue: 0.0, processNoise: 1.0, measurementNoise: 1e-9)
    // Vector Kalman filter for TWD.
    // Instead of filtering the angle scalar, we filter the two Cartesian components of
    // the wind velocity vector in the earth frame:
    //   East  = TWS × sin(TWD)
    //   North = TWS × cos(TWD)
    // Filtering these independent linear signals then reconstructing the angle with
    // atan2(East, North) gives three key benefits over a scalar angle filter:
    //   1. No 0°/360° wrap-around problem — the components are continuous.
    //   2. Correct vector averaging — mean of 355° and 5° becomes 0°, not 180°.
    //   3. Seeding from the first measurement gives instant cold-start (no drift from 0°).
    // Q=0.5, R=1.0 (knots²) → K_ss≈0.5 → genuine 10° wind shift converges in ~5 updates.
    private var kalmanWindEast  = KalmanFilter(initialValue: 0.0, processNoise: 0.5, measurementNoise: 1.0)
    private var kalmanWindNorth = KalmanFilter(initialValue: 0.0, processNoise: 0.5, measurementNoise: 1.0)
    private var twdVectorSeeded = false

    func updateDamping(level: Int) {
        let p = KalmanFilter.params(forDampingLevel: level)
        kalmanFilterAppWindForce.updateNoise(processNoise: p.processNoise, measurementNoise: p.measurementNoise)
        kalmanFilterTrueWindForce.updateNoise(processNoise: p.processNoise, measurementNoise: p.measurementNoise)
        kalmanFilterAppWindAngle.updateNoise(processNoise: p.processNoise, measurementNoise: p.measurementNoise)
        kalmanFilterTrueWindAngle.updateNoise(processNoise: p.processNoise, measurementNoise: p.measurementNoise)
    }

    func processWindSentence(_ splitStr: [String], compassData: CompassData?, hydroData: HydroData?) -> WindData? {
        guard splitStr.count >= 7, splitStr[6] == "A" else {
            Log.parsing.warning("Invalid MWV Sentence!")
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
//        updatedWindData = calculateTrueWind(updatedWindData, awa: updatedWindData.apparentWindAngle, awf: updatedWindData.apparentWindForce, stw: stw, heading: heading)

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

            // Vector Kalman filter for TWD.
            // Decompose raw TWD into (East, North) components, filter each independently,
            // then reconstruct direction with atan2 — no wrap-around possible.
            // TWS is used for the vector magnitude so the filter is weighted by wind strength;
            // falls back to unit-vector (TWS=1) if force is not yet available.
            if let rawTWD = updatedWindData.rawTrueWindDirection {
                let tws = updatedWindData.rawTrueWindForce ?? 1.0
                let rawTWD_rad = toRadians(rawTWD)
                let rawEast  = tws * sin(rawTWD_rad)
                let rawNorth = tws * cos(rawTWD_rad)

                if !twdVectorSeeded {
                    kalmanWindEast.seed(to: rawEast)
                    kalmanWindNorth.seed(to: rawNorth)
                    twdVectorSeeded = true
                }

                let fEast  = kalmanWindEast.update(measurement: rawEast)
                let fNorth = kalmanWindNorth.update(measurement: rawNorth)

                // atan2(East, North) = geographic bearing measured clockwise from North
                updatedWindData.trueWindDirection = normalizeAngle(toDegrees(atan2(fEast, fNorth)))
            }
        }

        // Calculate Apparent Wind from True Wind
//        updatedWindData = calculateApparentWind(updatedWindData, twa: updatedWindData.trueWindAngle, twf: updatedWindData.trueWindForce, stw: stw, heading: heading)

        return updatedWindData
    }


    // MARK: - Helper Functions

    private func calculateWindDirection(_ force: Double?, _ angle: Double, _ heading: Double) -> Double {
        guard let force = force, force > 0.001 else { return 0 }
        return normalizeAngle(angle + heading)
    }
    
    /*
     
     MARK: - For the moment I will not use these calculations, just process the alternating R and T from the sensor
     
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
     
     */
}
