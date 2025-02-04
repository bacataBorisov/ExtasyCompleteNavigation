//
//  HydroData.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 21.11.24.
//

struct HydroData {
    
    // Raw data fields
    var rawDepth: Double?
    var rawSeaWaterTemperature: Double?
    var rawBoatSpeedLag: Double?
    
    // Filtered Data Fields
    // Sea Water Temperature
    var seaWaterTemperature: Double?
    // Boat Speed Through Water
    var boatSpeedLag: Double?
    var speedLogCalibrationCoeff: Double?
    // Boat Distance Through Water
    var totalDistance: Double?
    var distSinceReset: Double?
    // Depth
    var depth: Double?
    var depthTriggerAlarm: Bool = false
    
    // Utility to reset hydro data
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
        
    }
}
