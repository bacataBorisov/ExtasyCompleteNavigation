//
//  MathUtilities.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 25.11.24.
//
//  MARK: Block for Precise Rounding of a Value
//  Specify the decimal place to round to using an enum

import Foundation


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

//VMG to a waypoint formula - VMG=speed x COSINE(course-bearing to mark), SOG, COG to be used
public func vmg(speed: Double, target_angle: Double, boat_angle: Double) -> Double {
    
    print("PRINTING FROM VMG")

    print("COG: [\(boat_angle)], SOG: [\(speed)], BTW: [\(target_angle)]")
    
    //check what is higher so we can always get positive value
    var courseOffset = target_angle - boat_angle
    
    if courseOffset < 0 {
        courseOffset = courseOffset * (-1)
        
        if courseOffset >= 180 {
            courseOffset = 360 - courseOffset
        }
    }
    
    
    let courseOffsetInRadians = toRadians(courseOffset)
    print("Course Offset: [\(courseOffset)]")
    let rt = speed * cos(courseOffsetInRadians)
    print("VMG: [\(rt)]")
    return rt
}
