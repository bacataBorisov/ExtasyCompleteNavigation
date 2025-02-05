//
//  GPSData.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 21.11.24.
//

import CoreLocation

struct GPSData {
    
    // MARK: - Validation State
    var isGPSDataValid: Bool = false
    var isTargetSelected: Bool = false

    // MARK: - Raw Data Fields (Used for Raw Data Logging)
    var rawLatitude: Double? = nil
    var rawLongitude: Double? = nil
    var rawCourseOverGround: Double? = nil
    var rawSpeedOverGround: Double? = nil
    
    // MARK: - Filtered Data Fields
    var latitude: Double? = nil
    var longitude: Double? = nil
    var courseOverGround: Double? = nil  // COG
    var speedOverGround: Double? = nil   // SOG in knots
    var speedOverGroundKmh: Double? = nil // SOG in km/h
    var utcTime: String? = nil
    var gpsDate: String? = nil

    // MARK: - Waypoint Data
    var waypointName: String? = nil
    var waypointLocation: CLLocationCoordinate2D? = nil

    // MARK: - Computed Property for Boat Location
    var boatLocation: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    // MARK: - Reset Method
    mutating func reset() {
        isGPSDataValid = false
        isTargetSelected = false

        rawLatitude = nil
        rawLongitude = nil
        rawCourseOverGround = nil
        rawSpeedOverGround = nil

        latitude = nil
        longitude = nil
        courseOverGround = nil
        speedOverGround = nil
        speedOverGroundKmh = nil
        utcTime = nil
        gpsDate = nil

        waypointName = nil
        waypointLocation = nil

        debugLog("GPS data has been reset.")
    }
}
