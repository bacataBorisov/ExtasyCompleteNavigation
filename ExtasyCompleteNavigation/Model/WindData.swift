//
//  WindData.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 18.11.24.
//
import Foundation

struct WindData {
    var apparentWindAngle: Double?      // Apparent Wind Angle (AWA)
    var apparentWindForce: Double?     // Apparent Wind Speed (AWS)
    var apparentWindDirection: Double? // Apparent Wind Direction (AWD)
    
    var trueWindAngle: Double?         // True Wind Angle (TWA)
    var trueWindForce: Double?         // True Wind Speed (TWS)
    var trueWindDirection: Double?     // True Wind Direction (TWD)
    
    var lastUpdated: Date?
    
    // Utility for resetting the data (optional)
    //If your application needs to reset the wind data after processing or to prepare for new data input, the reset() function ensures all properties are cleared efficiently.
    mutating func reset() {
        apparentWindAngle = nil
        apparentWindForce = nil
        apparentWindDirection = nil
        trueWindAngle = nil
        trueWindForce = nil
        trueWindDirection = nil
        lastUpdated = nil
    }
}

