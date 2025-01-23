//
//  HydroData.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 21.11.24.
//

struct HydroData {
    
    //Sea Water Temperature
    var seaWaterTemperature: Double?
    //Boat Speed Through Water
    var boatSpeedLag: Double?
    var speedLogCalibrationCoeff: Double?
    //Boat Distance Through Water
    var totalDistance: Double?
    var distSinceReset: Double?
    //Depth
    var depth: Double?
    var depthTriggerAlarm: Bool = false
    
    //Utility to reset hydro data
    mutating func reset() {
        
        seaWaterTemperature = nil
        boatSpeedLag = nil
        speedLogCalibrationCoeff = nil
        totalDistance = nil
        distSinceReset = nil
        depth = nil
        depthTriggerAlarm = false
        
    }
}
