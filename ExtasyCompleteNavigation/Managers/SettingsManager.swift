import SwiftUI
import Observation

enum DistanceUnit: Int, CaseIterable {
    case nauticalMiles = 0
    case cables = 1
    case meters = 2
    
    var abbreviation: String {
        switch self {
        case .nauticalMiles: return "NM"
        case .cables: return "cb"
        case .meters: return "m"
        }
    }
    
    var label: String {
        switch self {
        case .nauticalMiles: return "Nautical Miles"
        case .cables: return "Cables"
        case .meters: return "Meters"
        }
    }
    
    func convert(meters: Double) -> Double {
        switch self {
        case .nauticalMiles: return meters / 1852.0
        case .cables: return meters / 185.2
        case .meters: return meters
        }
    }
    
    func format(meters: Double) -> String {
        let value = convert(meters: meters)
        switch self {
        case .nauticalMiles: return String(format: "%.1f", value)
        case .cables: return String(format: "%.0f", value)
        case .meters: return String(format: "%.0f", value)
        }
    }
}

@Observable
class SettingsManager {
    var metricWind: Bool {
        didSet {
            UserDefaults.standard.set(metricWind, forKey: UserDefaultsKeys.metricWind)
        }
    }

    var tackTolerance: Double {
        didSet {
            UserDefaults.standard.set(tackTolerance, forKey: UserDefaultsKeys.tackTolerance)
        }
    }
    var isWindModeActive: Bool {
        didSet {
            UserDefaults.standard.set(isWindModeActive, forKey: UserDefaultsKeys.isWindModeActive)
        }
    }
    
    var calibrationCoefficient: Double {
        didSet {
            UserDefaults.standard.set(calibrationCoefficient, forKey: UserDefaultsKeys.calibrationCoefficient)
        }
    }
    
    var depthAlarmEnabled: Bool {
        didSet {
            UserDefaults.standard.set(depthAlarmEnabled, forKey: UserDefaultsKeys.depthAlarmEnabled)
        }
    }
    
    var depthAlarmThreshold: Double {
        didSet {
            UserDefaults.standard.set(depthAlarmThreshold, forKey: UserDefaultsKeys.depthAlarmThreshold)
        }
    }
    
    var boatName: String {
        didSet {
            UserDefaults.standard.set(boatName, forKey: UserDefaultsKeys.boatName)
        }
    }
    
    /// 0 = NM, 1 = cables, 2 = meters
    var distanceUnit: Int {
        didSet {
            UserDefaults.standard.set(distanceUnit, forKey: UserDefaultsKeys.distanceUnit)
        }
    }

    var selectedDistanceUnit: DistanceUnit {
        DistanceUnit(rawValue: distanceUnit) ?? .nauticalMiles
    }
    
    func formatDistance(meters: Double) -> String {
        selectedDistanceUnit.format(meters: meters)
    }
    
    func formatDistanceFromNM(_ nm: Double) -> String {
        selectedDistanceUnit.format(meters: nm * 1852.0)
    }
    
    var distanceAbbreviation: String {
        selectedDistanceUnit.abbreviation
    }

    init() {
        self.metricWind = UserDefaults.standard.bool(forKey: UserDefaultsKeys.metricWind)
        self.tackTolerance = UserDefaults.standard.double(forKey: UserDefaultsKeys.tackTolerance)
        self.isWindModeActive = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isWindModeActive)
        self.calibrationCoefficient = UserDefaults.standard.double(forKey: UserDefaultsKeys.calibrationCoefficient)
        self.depthAlarmEnabled = UserDefaults.standard.object(forKey: UserDefaultsKeys.depthAlarmEnabled) as? Bool ?? true
        self.depthAlarmThreshold = UserDefaults.standard.object(forKey: UserDefaultsKeys.depthAlarmThreshold) as? Double ?? 3.0
        self.boatName = UserDefaults.standard.string(forKey: UserDefaultsKeys.boatName) ?? "Extasy"
        self.distanceUnit = UserDefaults.standard.object(forKey: UserDefaultsKeys.distanceUnit) as? Int ?? 0
    }
}
