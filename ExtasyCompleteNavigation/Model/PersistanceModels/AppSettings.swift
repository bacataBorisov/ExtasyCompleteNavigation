//
//  AppSettings.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 30.12.24.
//

import Foundation

// MARK: - Use Property Wrapper "@UserDefault" in Utilities when adding New Settings

struct AppSettings {
    @UserDefault(key: UserDefaultsKeys.metricWind, defaultValue: false)
    static var metricWind: Bool

    @UserDefault(key: UserDefaultsKeys.tackTolerance, defaultValue: 15.0)
    static var tackTolerance: Double

    @UserDefault(key: UserDefaultsKeys.isWindModeActive, defaultValue: false)
    static var isWindModeActive: Bool
    
    @UserDefault(key: UserDefaultsKeys.calibrationCoefficient, defaultValue: 1)
    static var calibrationCoefficient: Double
}


// MARK: - Default Settings

struct DefaultSettings {
    static func initializeDefaults() {
        if UserDefaults.standard.value(forKey: UserDefaultsKeys.metricWind) == nil {
            UserDefaults.standard.set(false, forKey: UserDefaultsKeys.metricWind)
        }
        // Reset tolerance if it is missing or was set below the new minimum of 5°.
        let saved = UserDefaults.standard.double(forKey: UserDefaultsKeys.tackTolerance)
        if saved < 5.0 {
            UserDefaults.standard.set(15.0, forKey: UserDefaultsKeys.tackTolerance)
        }
        if UserDefaults.standard.value(forKey: UserDefaultsKeys.isWindModeActive) == nil {
            UserDefaults.standard.set(false, forKey: UserDefaultsKeys.isWindModeActive)
        }
        if UserDefaults.standard.value(forKey: UserDefaultsKeys.calibrationCoefficient) == nil {
            UserDefaults.standard.set(1.0, forKey: UserDefaultsKeys.calibrationCoefficient)
        }
        if UserDefaults.standard.value(forKey: UserDefaultsKeys.uiRefreshIntervalPreset) == nil {
            UserDefaults.standard.set(1, forKey: UserDefaultsKeys.uiRefreshIntervalPreset)
        }
    }
}
