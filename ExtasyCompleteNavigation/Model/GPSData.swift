//
//  GPSData.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 21.11.24.
//

import CoreLocation

struct GPSData {
    
    var isGPSDataValid: Bool = false
    
    // Raw data fields
    var rawLatitude: Double?
    var rawLongitude: Double?
    var rawCourseOverGround: Double?
    var rawSpeedOverGround: Double?
    
    // Filtered Data Fields
    var latitude: Double?
    var longitude: Double?
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
    var waypointName: String?
    var waypointLocation: CLLocationCoordinate2D? // Waypoint coordinates
    var isTargetSelected: Bool = false

    mutating func reset() {
        
        isGPSDataValid = false
        rawLatitude = nil
        rawLongitude = nil
        rawCourseOverGround = nil
        rawSpeedOverGround = nil
        latitude = nil
        longitude = nil
        waypointLocation = nil
        waypointName = nil
        courseOverGround = nil
        speedOverGround = nil
        speedOverGroundKmh = nil
        utcTime = nil
        gpsDate = nil
        isTargetSelected = false
    }
}
