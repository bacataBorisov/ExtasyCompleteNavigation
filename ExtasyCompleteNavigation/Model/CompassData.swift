//
//  CompassData 2.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 19.11.24.
//


struct CompassData {
    var magneticHeading: Double?       // Magnetic Heading (HDG)
    var normalizedHeading: Double?    // Heading normalized to [0, 360) - used for display
    var correctedHeading: Double?   // Corrected heading (accounting for variation)
    var smoothedHeading: Double?
    
    // Utility to reset compass data 
    mutating func reset() {
        magneticHeading = nil
        normalizedHeading = nil
        correctedHeading = nil
        smoothedHeading = nil
    }
}
