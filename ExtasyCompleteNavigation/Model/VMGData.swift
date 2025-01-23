//
//  VMGData.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 21.11.24.
//

import Foundation
import CoreLocation

struct VMGData {
    

    // MARK: - VMG Values
    var polarSpeed: Double? // Speed derived from polar diagram
    var polarVMG: Double? // Velocity Made Good for optimal angles
    
    var vmgOverGround: Double? //current VMG using SOG
    var vmgOverGroundPerformance: Double? // Performance Ratio

    var vmgThroughWater: Double? // currentVMG using speed log
    var vmgThroughWaterPerformance: Double? // currentVMG using speed log
    
    var speedPerformanceThroughWater: Double? // this will be performance using speed log
    var speedPerformanceOverGround: Double? // speed performance using SOG
    
    // MARK: - Values from the Optimal Tack Table
    
    var optimalUpTWA: Double? // optimal attack angle upwind
    var optimalDnTWA: Double? // optimal attack angle downwind
    var maxUpVMG: Double?     // max speed upWind
    var maxDnVMG: Double?     // max speed downWind
    
    // MARK: - Tack Properties
    var sailingState: String? // "Upwind" or "Downwind"
    var sailingStateLimit: Double?
    
    // MARK: - Laylines
    var starboardLayline: CLLocationCoordinate2D?
    var portsideLayline: CLLocationCoordinate2D?

    
    // MARK: - Utility
    mutating func reset() {

        polarSpeed = nil
        polarVMG = nil
        vmgOverGround = nil
        vmgOverGroundPerformance = nil
        vmgThroughWaterPerformance = nil
        vmgThroughWater = nil
        speedPerformanceThroughWater = nil
        speedPerformanceOverGround = nil
        optimalDnTWA = nil
        optimalUpTWA = nil
        maxDnVMG = nil
        maxUpVMG = nil
        sailingState = nil
        sailingStateLimit = nil
        starboardLayline = nil
        portsideLayline = nil
    }
}
