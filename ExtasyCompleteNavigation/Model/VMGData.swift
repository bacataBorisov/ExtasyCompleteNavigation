//
//  VMGData.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 21.11.24.
//

import Foundation
import CoreLocation

struct VMGData {
    // MARK: - Waypoint & Distance Variables
    var markerCoordinate: CLLocationCoordinate2D? // Waypoint coordinates
    var distanceToMark: Double? // Distance to the waypoint in meters
    var estTimeOfArrival: Double? // Estimated Time of Arrival to the waypoint
    var markBearing: Double? // Absolute bearing to the waypoint
    var relativeMarkBearing: Double = 0 // Relative bearing to the waypoint
    var relativeMarkBearingArray: [Double] = [] // History of relative bearings for smoothing
    var trueMarkBearing: Double = 0 // True bearing to the waypoint
    
    // MARK: - VMG Values
    var polarSpeed: Double? // Speed derived from polar diagram
    var polarVMG: Double? // Velocity Made Good for optimal angles
    var waypointVMC: Double? // Velocity Made on Course to a specific waypoint
    
    // Tack Calculations
    var distanceToNextTack: Double? // Distance to the next tack in meters
    var etaToNextTack: Double? // Estimated time to next tack in seconds
    var distanceToTheLongTack: Double? // Distance to the longer tack in meters
    
    // MARK: - Utility
    mutating func reset() {
        markerCoordinate = nil
        distanceToMark = nil
        estTimeOfArrival = nil
        markBearing = nil
        relativeMarkBearing = 0
        relativeMarkBearingArray = []
        trueMarkBearing = 0
        polarSpeed = nil
        polarVMG = nil
        waypointVMC = nil
        distanceToNextTack = nil
        etaToNextTack = nil
        distanceToTheLongTack = nil
    }
}
