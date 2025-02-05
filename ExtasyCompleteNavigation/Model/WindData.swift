//
//  WindData.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 18.11.24.
//

import Foundation

struct WindData {
    
    // MARK: - Raw Data Fields (Used for Raw Data Logging)
    var rawApparentWindAngle: Double? = nil    // Raw Apparent Wind Angle (AWA)
    var rawApparentWindForce: Double? = nil    // Raw Apparent Wind Speed (AWS)
    var rawApparentWindDirection: Double? = nil // Raw Apparent Wind Direction (AWD)
    
    var rawTrueWindAngle: Double? = nil        // Raw True Wind Angle (TWA)
    var rawTrueWindForce: Double? = nil        // Raw True Wind Speed (TWS)
    var rawTrueWindDirection: Double? = nil    // Raw True Wind Direction (TWD)
    
    // MARK: - Filtered Data Fields
    var apparentWindAngle: Double? = nil       // Filtered Apparent Wind Angle (AWA)
    var apparentWindForce: Double? = nil       // Filtered Apparent Wind Speed (AWS)
    var apparentWindDirection: Double? = nil   // Filtered Apparent Wind Direction (AWD)
    
    var trueWindAngle: Double? = nil           // Filtered True Wind Angle (TWA)
    var trueWindForce: Double? = nil           // Filtered True Wind Speed (TWS)
    var trueWindDirection: Double? = nil       // Filtered True Wind Direction (TWD)
    
    var lastUpdated: Date? = nil               // Timestamp of the last wind data update
    
    // MARK: - Utility Methods
    
    /// Resets all wind data fields to their default state
    mutating func reset() {
        rawApparentWindAngle = nil
        rawApparentWindForce = nil
        rawApparentWindDirection = nil
        
        rawTrueWindAngle = nil
        rawTrueWindForce = nil
        rawTrueWindDirection = nil
        
        apparentWindAngle = nil
        apparentWindForce = nil
        apparentWindDirection = nil
        
        trueWindAngle = nil
        trueWindForce = nil
        trueWindDirection = nil
        
        lastUpdated = nil
        
        debugLog("Wind data has been reset.")
    }
}
