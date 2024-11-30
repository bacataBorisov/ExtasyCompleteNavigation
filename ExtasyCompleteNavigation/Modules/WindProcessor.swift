//
//  WindProcessor.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 18.11.24.
//
import Foundation

class WindProcessor {
    
    private var appWindArray = [Double]() //used to calculate smoothed AWA
    private var trueWindArray = [Double]() //used to calculate smoothed TWA
    
    //separate instance to keep the last known valid data
    private var lastKnownWindData: WindData = WindData()
    
    // Kalman Filters for smoothing wind force - individually
    // could also be done in groups - to be decided
    // consider filtering the angles too - to be decided after real tests
    private var kalmanFilterAppWind = KalmanFilter(initialValue: 0)
    private var kalmanFilterTrueWind = KalmanFilter(initialValue: 0)
    
    //validate and process the "MWV "string for wind data
    func processWindSentence(_ splitStr: [String]) -> WindData? {
        guard splitStr.count >= 7, splitStr[6] == "A" else {
            print("Invalid MWV Sentence!")
            return lastKnownWindData
        }
        //get the last known wind data
        var windData = lastKnownWindData
        
        //process AWA
        if splitStr[3] == "R" {
            
            let rawAppWindForce = Double(splitStr[4]) ?? 0
            windData.apparentWindForce = kalmanFilterAppWind.update(measurement: rawAppWindForce)
            
            if let rawAWA = Double(splitStr[2]) {
                //smoothing the angle to avoid wraprounds
                windData.apparentWindAngle = smoothAngle(rawAWA, &appWindArray)
                
                //print("Printing from WindProcessor - AWA ... \n")
                //print(windData.apparentWindAngle ?? 999)
                if let unwrappedAWA = windData.apparentWindAngle,
                   let unwrappedAWF = windData.apparentWindForce {
                    //TODO: - update with real value when compassData & Process is ready, for now use 0 just to test if the value for the wind angle will be real
                    windData.apparentWindDirection = calculateWindDirection(unwrappedAWF, unwrappedAWA, 0)
                }
            }
        } else if splitStr[3] == "T" { // True wind
            
            let rawTrueWindForce = Double(splitStr[4]) ?? 0
            windData.trueWindForce = kalmanFilterTrueWind.update(measurement: rawTrueWindForce)
            
            if let rawTWA = Double(splitStr[2]) {
                // Smooth true wind angle calculation
                windData.trueWindAngle = smoothAngle(rawTWA, &trueWindArray)
                if let unwrappedTWA = windData.trueWindAngle, let unwrappedTWF = windData.trueWindForce {
                    windData.trueWindDirection = calculateWindDirection(unwrappedTWF, unwrappedTWA, 0)
                }
            }
        }
        
        windData.lastUpdated = Date() //record Timestamp for the watchdog
        lastKnownWindData = windData //store the lastknow valid data
        return windData
    }
    
    // Smooths the angle data to avoid abrupt changes due to 360-degree wrapping.
    private func smoothAngle(_ newAngle: Double, _ angleArray: inout [Double]) -> Double {
        
        //array helps us overcome the 360 wrapround problem
        angleArray.append(newAngle)
        if angleArray.count > 2 { angleArray.removeFirst() }
        
        guard angleArray.count == 2 else { return newAngle }
        
        //assign the angles
        let sourceAngle = angleArray[0]
        let targetAngle = angleArray[1]
        
        //get the three different distances
        let differences = [
            targetAngle - sourceAngle,
            targetAngle - sourceAngle + 360,
            targetAngle - sourceAngle - 360
        ]
        //get the lowest value by absolute
        let shortestDiff = differences.min(by: { abs($0) < abs($1) }) ?? 0
        
        let smoothedAngle = sourceAngle + shortestDiff
        angleArray[0] = smoothedAngle // Update with smoothed angle
        
        //MARK: - make sure that the angle has to be normalized - I am not really sure about it
        return normalizeAngle(smoothedAngle)
    }
    
    // Calculates wind direction based on force, angle and boat's heading.
    private func calculateWindDirection(_ awf: Double,_ awa: Double,_ hdg: Double) -> Double {
        
        //if there is no wind, do not calculate direction
        guard awf > 0.001 else {
            return 0
        }
        
        //prepare angles and calculate wind direction
        let direction = normalizeAngle(awa) + normalizeAngle(hdg)
        return normalizeAngle(direction)
        
    }

    // Normalizes an angle to [0, 360).
    private func normalizeAngle(_ angle: Double) -> Double {
        var normalized = angle.truncatingRemainder(dividingBy: 360)
        if normalized < 0 { normalized += 360 }
        return normalized
    }
}
