//
//  CompassProcessor.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 19.11.24.
//


import Foundation

class CompassProcessor {
    
    private var magneticArray = [Double]()
    private(set) var currentHeading: Double?
    
    
    // Process magnetic heading from NMEA sentence
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
        compassData.magneticHeading = correctedHeading(heading: rawHeading, variation: variation, direction: direction)
        
        // Smooth and normalize heading
        compassData.smoothedHeading = smoothAngle(compassData.magneticHeading ?? 0, &magneticArray)
        compassData.normalizedHeading = normalizeAngle(compassData.smoothedHeading ?? 0)
//        compassData.normalizedHeading = normalizeAngle(compassData.magneticHeading ?? 0)

        
        //print("The smoothed angle #2 is: \(String(describing: compassData.smoothedHeading))")
        //print("The normalized angle is: \(String(describing: compassData.normalizedHeading))")

        
        return compassData
    }
    
    // Corrects the heading based on magnetic variation
    private func correctedHeading(heading: Double, variation: Double, direction: String) -> Double {
        (direction == "E") ? (heading + variation) : (heading - variation)
    }
    
    // Smooths heading data to avoid abrupt changes due to wrap-around
    private func smoothAngle(_ newAngle: Double, _ angleArray: inout [Double]) -> Double {
        // Add the new angle to the history
        angleArray.append(newAngle)
        if angleArray.count > 2 { angleArray.removeFirst() }
        
        // If there is only one angle, return it
        guard angleArray.count == 2 else { return newAngle }
        
        let oldAngle = angleArray[0]
        let targetAngle = angleArray[1]
        
        // Calculate the shortest difference between angles
        let delta = (targetAngle - oldAngle).truncatingRemainder(dividingBy: 360)
        let shortestDiff = delta > 180 ? delta - 360 : (delta < -180 ? delta + 360 : delta)
        
        // Add the shortest difference to the old angle
        let smoothedAngle = oldAngle + shortestDiff
        
        // Update the first angle to the smoothed angle for the next iteration
        angleArray[0] = smoothedAngle
        //print("The smoothed angle is: \(smoothedAngle)")
        print("Compass Array count is: \(angleArray.count)")

        return smoothedAngle
    }
    
    // Normalizes an angle to [0, 360)
    private func normalizeAngle(_ angle: Double) -> Double {
        var normalized = angle.truncatingRemainder(dividingBy: 360)
        if normalized < 0 { normalized += 360 }
        return normalized
    }
}
