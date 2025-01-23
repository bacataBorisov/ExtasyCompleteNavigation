//
//  WaypointData.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 25.12.24.
//

import Foundation
import CoreLocation

struct WaypointData {
    
    // MARK: - Coordinates & Name
    
    var boatLocation: CLLocationCoordinate2D? // Boat's current location
    var waypointCoordinate: CLLocationCoordinate2D? // Target waypoint coordinates

    // MARK: - Distance Calculations
    var distanceToMark: Double? // Distance from the boat to the waypoint (in meters)
    
    // MARK: - Time Calculations
    var tripDurationToWaypoint: Double? // Estimated Time of Arrival to the waypoint
    var etaToWaypoint: Date?
    
    var tackDistance: Double? // distance to the current tack intersection
    var tackDuration: Double? // estimated time spent on this tack
    var distanceOnOppositeTack: Double?
    var tripDurationOnOppositeTack: Double?
    var etaToNextTack: Date? // ETA to the next tack

    // MARK: - Bearings
    var trueMarkBearing: Double? // True bearing to the waypoint
    var currentTackState: String?
    var currentTackRelativeBearing: Double? // Relative bearing to the waypoint
    var oppositeTackState: String?
    var oppositeTackRelativeBearing: Double? // Relative bearing on the opposite tack

    // MARK: - Tack Calculations
    var currentTackVMC: Double? // VMC to the waypoint
    var currentTackVMCDisplay: Double?
    var oppositeTackVMC: Double?
    var oppositeTackVMCDisplay: Double?
    var currentTackVMCPerformance: Double?
    var oppositeTackVMCPerformance: Double?

    // MARK: - Max Polar VMC
    
    var polarVMC: Double? // max theoretical VMC to the waypoint
    var maxTackPolarVMC: Double? //hold the max between both tacks

    // MARK: - Velocity Made on Course (VMC)

    var isVMCNegative: Bool = false
    
    // MARK: - Laylines
    
    var starboardLayline: Layline?           // Starboard layline from boat to waypoint
    var portsideLayline: Layline?            // Portside layline from boat to waypoint
    var extendedStarboardLayline: Layline?  // Starboard layline extended beyond waypoint
    var extendedPortsideLayline: Layline?   // Portside layline extended beyond waypoint
    var starboardIntersection: (intersection: CLLocationCoordinate2D, distanceBoat: Double, distanceWaypoint: Double)? // point of intersection
    var portsideIntersection: (intersection: CLLocationCoordinate2D, distanceBoat: Double, distanceWaypoint: Double)? // point of intersection


    // MARK: - Reset Function
    mutating func reset() {
        // Coordinates
        //boatLocation = nil
        waypointCoordinate = nil
        
        // Distance
        distanceToMark = nil
        
        // Time Calculations
        tripDurationToWaypoint = nil
        etaToWaypoint = nil
        tackDistance = nil
        tackDuration = nil
        distanceOnOppositeTack = nil
        tripDurationOnOppositeTack = nil
        etaToNextTack = nil
        
        // Bearings
        trueMarkBearing = nil
        currentTackState = nil
        currentTackRelativeBearing = nil
        
        // Opposite Tack Calculations
        oppositeTackState = nil
        oppositeTackRelativeBearing = nil // Relative bearing on the opposite tack
        oppositeTackVMC = nil
        oppositeTackVMCDisplay = nil
        
        // VMC
        currentTackVMC = nil
        currentTackVMCDisplay = nil
        polarVMC = nil
        currentTackVMCPerformance = nil
        oppositeTackVMCPerformance = nil
        maxTackPolarVMC = nil
        
        // Laylines
        // MARK: - Laylines
        starboardLayline = nil
        portsideLayline = nil
        extendedStarboardLayline = nil
        extendedPortsideLayline = nil
        starboardIntersection = nil
        portsideIntersection = nil
        
    }
}


