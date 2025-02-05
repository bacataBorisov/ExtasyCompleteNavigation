//
//  CompassData.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 19.11.24.
//

struct CompassData {
    
    // MARK: - Raw Data Fields (Used for Raw Data Logging)
    var rawMagneticHeading: Double? = nil     // Unfiltered magnetic heading from sensor
    var rawNormalizedHeading: Double? = nil   // Unfiltered normalized heading from sensor
    
    // MARK: - Filtered Data Fields
    var magneticHeading: Double? = nil        // Magnetic Heading (HDG)
    var normalizedHeading: Double? = nil      // Heading normalized to [0, 360) for display purposes
    
    // MARK: - Utility Methods
    
    /// Resets all compass data fields to their default state
    mutating func reset() {
        rawMagneticHeading = nil
        rawNormalizedHeading = nil
        magneticHeading = nil
        normalizedHeading = nil
        
        debugLog("Compass data has been reset.")
    }
}
