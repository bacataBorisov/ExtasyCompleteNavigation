//
//  VMGData.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 21.11.24.
//

import Foundation
import CoreLocation

struct VMGData {
    
    // MARK: - Polar Diagram & VMG Values
    var polarSpeed: Double?                    // Speed derived from polar diagram
    var polarVMG: Double?                      // Velocity Made Good for optimal angles
    
    var vmgOverGround: Double?                 // VMG using Speed Over Ground (SOG)
    var vmgOverGroundPerformance: Double?      // VMG performance ratio using SOG
    
    var vmgThroughWater: Double?               // VMG using Speed Through Water (log)
    var vmgThroughWaterPerformance: Double?    // VMG performance ratio using log speed
    
    var speedPerformanceThroughWater: Double?  // Speed performance using log
    var speedPerformanceOverGround: Double?    // Speed performance using SOG
    
    // MARK: - Optimal Tack Table Values
    var optimalUpTWA: Double?                  // Optimal True Wind Angle (TWA) upwind
    var optimalDnTWA: Double?                  // Optimal TWA downwind
    var maxUpVMG: Double?                      // Maximum VMG upwind
    var maxDnVMG: Double?                      // Maximum VMG downwind
    
    // MARK: - Tack Properties
    var sailingState: String?                  // Current sailing state: "Upwind" or "Downwind"
    var sailingStateLimit: Double?             // TWA limit for the current sailing state
    
    // MARK: - Laylines (Waypoint Targets)
    var starboardLayline: CLLocationCoordinate2D?  // Starboard tack layline coordinate
    var portsideLayline: CLLocationCoordinate2D?   // Portside tack layline coordinate
    
    // MARK: - Utility Methods
    
    /// Resets all VMG-related data fields to their default state
    mutating func reset() {
        polarSpeed = nil
        polarVMG = nil
        vmgOverGround = nil
        vmgOverGroundPerformance = nil
        vmgThroughWater = nil
        vmgThroughWaterPerformance = nil
        speedPerformanceThroughWater = nil
        speedPerformanceOverGround = nil
        optimalUpTWA = nil
        optimalDnTWA = nil
        maxUpVMG = nil
        maxDnVMG = nil
        sailingState = nil
        sailingStateLimit = nil
        starboardLayline = nil
        portsideLayline = nil
        
        debugLog("VMG data has been reset.")
    }
}
