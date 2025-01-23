//
//  MathUtilities.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 25.11.24.
//
//  MARK: Block for Precise Rounding of a Value
//  Specify the decimal place to round to using an enum

import Foundation
import CoreLocation


// Round to the specific decimal place
public func preciseRound(_ value: Double, precision: RoundingPrecision = .ones) -> Double {
    switch precision {
    case .ones:
        return round(value)
    case .tenths:
        return round(value * 10) / 10.0
    case .hundredths:
        return round(value * 100) / 100.0
    }
}


public func toRadians(_ degrees: Double) -> Double {
    return degrees * (Double.pi / 180.0)
}
public func toDegrees(_ radians: Double) -> Double {
    return radians * (180.0 / Double.pi)
}
public func normalizeAngle(_ angle: Double) -> Double {
    var normalized = angle.truncatingRemainder(dividingBy: 360)
    if normalized < 0 { normalized += 360 }
    return normalized
}

public func normalizeAngleTo180(_ angle: Double) -> Double {
    
    var normalized = angle.truncatingRemainder(dividingBy: 360)
    if normalized > 180 {
        normalized -= 360
    } else if normalized < -180 {
        normalized += 360
    }
    return normalized
}

func normalizeAngleTo90(_ angle: Double) -> Double {
    var normalized = angle.truncatingRemainder(dividingBy: 360)
    if normalized > 90 {
        normalized -= 180
    } else if normalized < -90 {
        normalized += 180
    }
    return normalized
}

// Calculate Distance between two points with given coordinates
public func calculateDistance(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
    let locationA = CLLocation(latitude: start.latitude, longitude: start.longitude)
    let locationB = CLLocation(latitude: end.latitude, longitude: end.longitude)
    return locationA.distance(from: locationB)
}

// Calculate bearing between two points using haversine formula

public func calculateBearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
    let lat1 = toRadians(start.latitude)
    let lon1 = toRadians(start.longitude)
    let lat2 = toRadians(end.latitude)
    let lon2 = toRadians(end.longitude)
    
    let deltaLon = lon2 - lon1

    let y = sin(deltaLon) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
    
    let initialBearing = atan2(y, x)
    return normalizeAngle(toDegrees(initialBearing)) // Convert to degrees and normalize
}

//VMG to a waypoint formula - VMG=speed x COSINE(course-bearing to mark), SOG, COG to be used
public func vmg(speed: Double, target_angle: Double, boat_angle: Double) -> Double {
    
    //print("PRINTING FROM VMG")

    //print("COG: [\(boat_angle)], SOG: [\(speed)], BTW: [\(target_angle)]")
    
    //check what is higher so we can always get positive value
    var courseOffset = target_angle - boat_angle
    
    if courseOffset < 0 {
        courseOffset = courseOffset * (-1)
        
        if courseOffset >= 180 {
            courseOffset = 360 - courseOffset
        }
    }
    
    
    let courseOffsetInRadians = toRadians(courseOffset)
    //print("Course Offset: [\(courseOffset)]")
    let rt = speed * cos(courseOffsetInRadians)
    //print("VMG: [\(rt)]")
    return rt
}
