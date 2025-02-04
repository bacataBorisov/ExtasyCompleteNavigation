//
//  CompassData 2.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 19.11.24.
//


struct CompassData {
    
    // Raw Data Fields
    var rawMagneticHeading: Double?
    var rawNormalizedHeading: Double?
    // Filtered Data Fields
    var magneticHeading: Double?       // Magnetic Heading (HDG)
    var normalizedHeading: Double?    // Heading normalized to [0, 360) - used for display
    
    // Utility to reset compass data 
    mutating func reset() {
        
        rawMagneticHeading = nil
        rawNormalizedHeading = nil
        magneticHeading = nil
        normalizedHeading = nil
    }
}
