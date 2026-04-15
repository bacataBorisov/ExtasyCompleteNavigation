//
//  UserDefaultsKeys.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 30.12.24.
//

struct UserDefaultsKeys {
    static let metricWind = "metricWind"
    static let tackTolerance = "tackTolerance"
    static let isWindModeActive = "isWindModeActive"
    static let calibrationCoefficient = "calibrationCoefficient"
    static let depthAlarmEnabled = "depthAlarmEnabled"
    static let depthAlarmThreshold = "depthAlarmThreshold"
    static let boatName = "boatName"
    static let distanceUnit = "distanceUnit"
    static let windDamping = "windDamping"
    static let speedDamping = "speedDamping"
    static let headingDamping = "headingDamping"
    static let hydroDamping = "hydroDamping"
    /// 0 = 0.5s, 1 = 1.0s, 2 = 2.0s — `NMEAParser` periodic UI / Watch update interval.
    static let uiRefreshIntervalPreset = "uiRefreshIntervalPreset"
}
