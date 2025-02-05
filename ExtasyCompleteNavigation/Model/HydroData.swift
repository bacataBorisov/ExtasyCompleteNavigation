//
//  HydroData.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 21.11.24.
//

struct HydroData {
    
    // MARK: - Raw Data Fields (Used for Raw Data Logging)
    var rawDepth: Double? = nil
    var rawSeaWaterTemperature: Double? = nil
    var rawBoatSpeedLag: Double? = nil
    
    // MARK: - Processed Data Fields
    
    // Sea Water Temperature
    var seaWaterTemperature: Double? = nil
    
    // Boat Speed Through Water
    var boatSpeedLag: Double? = nil
    var speedLogCalibrationCoeff: Double? = nil
    
    // Boat Distance Through Water
    var totalDistance: Double? = nil
    var distSinceReset: Double? = nil
    
    // Depth Information
    var depth: Double? = nil
    var depthTriggerAlarm: Bool = false
    
    // MARK: - Utility Methods
    
    /// Resets all hydro data fields to their default state
    mutating func reset() {
        rawDepth = nil
        rawSeaWaterTemperature = nil
        rawBoatSpeedLag = nil
        
        seaWaterTemperature = nil
        boatSpeedLag = nil
        speedLogCalibrationCoeff = nil
        
        totalDistance = nil
        distSinceReset = nil
        
        depth = nil
        depthTriggerAlarm = false
        
        debugLog("Hydro data has been reset.")
    }
}
