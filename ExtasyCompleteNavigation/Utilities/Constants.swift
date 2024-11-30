//
//  Constants.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 18.11.24.
//

public enum RoundingPrecision {
    
    case ones
    case tenths
    case hundredths
}

//coeff. for converting to nautical miles
public let toNauticalMiles = 0.000539956803
public let toNauticalCables = 0.0053961007775
public let toBoatLengths = 0.083333333333
public let toMetersPerSecond = 0.514444444

enum DistanceUnit {
    case nauticalMiles
    case nauticalCables
    case meters
    case boatLength
}


