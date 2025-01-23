//
//  GPSData.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 21.11.24.
//

import CoreLocation

struct GPSData {
    
    var isGPSDataValid: Bool = false
    var latitude: Double?
    var longitude: Double?
    
    // Computed property for CLLocationCoordinate2D
    var boatLocation: CLLocationCoordinate2D? {
        guard let latitude = latitude, let longitude = longitude else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    var courseOverGround: Double? // COG
    var speedOverGround: Double? // SOG in knots
    var speedOverGroundKmh: Double? // SOG in km/h
    var utcTime: String?
    var gpsDate: String?
    var markerName: String?
    var markerCoordinate: CLLocationCoordinate2D? // Waypoint coordinates
    var isTargetSelected: Bool = false

    mutating func reset() {
        
        isGPSDataValid = false
        latitude = nil
        longitude = nil
        markerCoordinate = nil
        markerName = nil
        courseOverGround = nil
        speedOverGround = nil
        speedOverGroundKmh = nil
        utcTime = nil
        gpsDate = nil
        isTargetSelected = false
    }
}
