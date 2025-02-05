//
//  WaypointData.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 25.12.24.
//

import Foundation
import CoreLocation

struct WaypointData {
    
    // MARK: - Coordinates & Navigation Details
    var boatLocation: CLLocationCoordinate2D?         // Current boat location
    var waypointCoordinate: CLLocationCoordinate2D?   // Target waypoint coordinates
    
    // MARK: - Distance & Bearing Calculations
    var distanceToMark: Double?                      // Distance from boat to waypoint (in meters)
    var trueMarkBearing: Double?                     // True bearing from boat to waypoint
    
    // MARK: - Time & ETA Calculations
    var tripDurationToWaypoint: Double?              // Estimated trip duration to the waypoint
    var etaToWaypoint: Date?                         // Estimated Time of Arrival (ETA) at the waypoint
    
    var tackDistance: Double?                        // Distance to tack intersection
    var tackDuration: Double?                        // Estimated time on the current tack
    
    var distanceOnOppositeTack: Double?              // Distance on the opposite tack
    var tripDurationOnOppositeTack: Double?          // Estimated time on the opposite tack
    var etaToNextTack: Date?                         // ETA to the next tack
    
    // MARK: - Tack State & Relative Bearings
    var currentTackState: String?                    // Current tack direction ("Port" or "Starboard")
    var currentTackRelativeBearing: Double?          // Relative bearing to waypoint on the current tack
    
    var oppositeTackState: String?                   // Opposite tack direction
    var oppositeTackRelativeBearing: Double?         // Relative bearing on the opposite tack
    
    // MARK: - Velocity Made on Course (VMC) Calculations
    var currentTackVMC: Double?                      // VMC to waypoint on the current tack
    var currentTackVMCDisplay: Double?               // Display value for current tack VMC
    var currentTackVMCPerformance: Double?           // VMC performance on the current tack
    
    var oppositeTackVMC: Double?                     // VMC to waypoint on the opposite tack
    var oppositeTackVMCDisplay: Double?              // Display value for opposite tack VMC
    var oppositeTackVMCPerformance: Double?          // VMC performance on the opposite tack
    
    var polarVMC: Double?                            // Theoretical maximum VMC from polar diagrams
    var maxTackPolarVMC: Double?                     // Maximum polar VMC between both tacks
    
    var isVMCNegative: Bool = false                  // Indicates if VMC is negative (moving away from waypoint)
    
    // MARK: - Laylines & Intersections
    var starboardLayline: Layline?                   // Starboard layline from boat to waypoint
    var portsideLayline: Layline?                    // Portside layline from boat to waypoint
    
    var extendedStarboardLayline: Layline?           // Extended starboard layline beyond waypoint
    var extendedPortsideLayline: Layline?            // Extended portside layline beyond waypoint
    
    var starboardIntersection: (intersection: CLLocationCoordinate2D, distanceBoat: Double, distanceWaypoint: Double)?
    var portsideIntersection: (intersection: CLLocationCoordinate2D, distanceBoat: Double, distanceWaypoint: Double)?
    
    // MARK: - Reset Function
    /// Resets all waypoint-related data to its default state
    mutating func reset() {
        waypointCoordinate = nil
        distanceToMark = nil
        
        tripDurationToWaypoint = nil
        etaToWaypoint = nil
        tackDistance = nil
        tackDuration = nil
        distanceOnOppositeTack = nil
        tripDurationOnOppositeTack = nil
        etaToNextTack = nil
        
        trueMarkBearing = nil
        currentTackState = nil
        currentTackRelativeBearing = nil
        
        oppositeTackState = nil
        oppositeTackRelativeBearing = nil
        
        currentTackVMC = nil
        currentTackVMCDisplay = nil
        currentTackVMCPerformance = nil
        
        oppositeTackVMC = nil
        oppositeTackVMCDisplay = nil
        oppositeTackVMCPerformance = nil
        
        polarVMC = nil
        maxTackPolarVMC = nil
        isVMCNegative = false
        
        starboardLayline = nil
        portsideLayline = nil
        extendedStarboardLayline = nil
        extendedPortsideLayline = nil
        starboardIntersection = nil
        portsideIntersection = nil
        
        debugLog("Waypoint data has been reset.")
    }
}
