//
//  HydroProcessor.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 21.11.24.
//

import Foundation

class HydroProcessor {
    
    private(set) var hydroData = HydroData()
    
    // Process depth-related data
    func processDepth(_ splitStr: [String]) {
        guard splitStr.count >= 3, let depthValue = Double(splitStr[2]) else {
            print("Invalid Depth Data!")
            return
        }
        hydroData.depth = depthValue
    }
    
    // Process sea water temperature
    func processSeaTemperature(_ splitStr: [String]) {
        guard splitStr.count >= 3, let temperature = Double(splitStr[2]) else {
            print("Invalid Sea Water Temperature Data!")
            return
        }
        hydroData.seaWaterTemperature = temperature
    }
    
    // Process speed through water
    func processSpeedLog(_ splitStr: [String]) {
        guard splitStr.count >= 7, let speedLog = Double(splitStr[6]) else {
            print("Invalid Speed Log Data!")
            return
        }
        hydroData.boatSpeedLag = speedLog
    }
    
    // Process total distance through water
    func processDistanceTravelled(_ splitStr: [String]) {
        guard splitStr.count >= 5,
              let totalDistance = Double(splitStr[2]),
              let distanceSinceReset = Double(splitStr[4]) else {
            print("Invalid Distance Data!")
            return
        }
        hydroData.totalDistance = totalDistance
        hydroData.distSinceReset = distanceSinceReset
    }
    
    // Reset hydro data
    func resetHydroData() {
        hydroData.reset()
    }
}
