import SwiftUI
import Observation

enum MarineDistanceUnit: Int, CaseIterable {
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

    /// Sensor smoothing levels (0 = raw, 11 = maximum damping)
    var windDamping: Int {
        didSet { UserDefaults.standard.set(windDamping, forKey: UserDefaultsKeys.windDamping) }
    }
    var speedDamping: Int {
        didSet { UserDefaults.standard.set(speedDamping, forKey: UserDefaultsKeys.speedDamping) }
    }
    var headingDamping: Int {
        didSet { UserDefaults.standard.set(headingDamping, forKey: UserDefaultsKeys.headingDamping) }
    }
    var hydroDamping: Int {
        didSet { UserDefaults.standard.set(hydroDamping, forKey: UserDefaultsKeys.hydroDamping) }
    }

    /// Preset index: 0 = 0.5s (racing), 1 = 1.0s (standard), 2 = 2.0s (cruising).
    var uiRefreshIntervalPreset: Int {
        didSet {
            let clamped = Self.clampPreset(uiRefreshIntervalPreset)
            if clamped != uiRefreshIntervalPreset {
                uiRefreshIntervalPreset = clamped
                return
            }
            UserDefaults.standard.set(uiRefreshIntervalPreset, forKey: UserDefaultsKeys.uiRefreshIntervalPreset)
        }
    }

    /// Effective UI / Watch refresh interval in seconds.
    var uiRefreshIntervalSeconds: Double {
        Self.seconds(forPreset: uiRefreshIntervalPreset)
    }

    private static func clampPreset(_ raw: Int) -> Int {
        min(max(raw, 0), 2)
    }

    static func seconds(forPreset preset: Int) -> Double {
        switch clampPreset(preset) {
        case 0: return 0.5
        case 2: return 2.0
        default: return 1.0
        }
    }

    var selectedDistanceUnit: MarineDistanceUnit {
        MarineDistanceUnit(rawValue: distanceUnit) ?? .nauticalMiles
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
        self.windDamping = UserDefaults.standard.object(forKey: UserDefaultsKeys.windDamping) as? Int ?? 0
        self.speedDamping = UserDefaults.standard.object(forKey: UserDefaultsKeys.speedDamping) as? Int ?? 0
        self.headingDamping = UserDefaults.standard.object(forKey: UserDefaultsKeys.headingDamping) as? Int ?? 0
        self.hydroDamping = UserDefaults.standard.object(forKey: UserDefaultsKeys.hydroDamping) as? Int ?? 0
        if let preset = UserDefaults.standard.object(forKey: UserDefaultsKeys.uiRefreshIntervalPreset) as? Int {
            self.uiRefreshIntervalPreset = Self.clampPreset(preset)
        } else if let legacy = UserDefaults.standard.object(forKey: "uiRefreshIntervalSeconds") as? Double,
                  [0.5, 1.0, 2.0].contains(legacy) {
            self.uiRefreshIntervalPreset = legacy == 0.5 ? 0 : (legacy == 2.0 ? 2 : 1)
            UserDefaults.standard.set(uiRefreshIntervalPreset, forKey: UserDefaultsKeys.uiRefreshIntervalPreset)
        } else {
            self.uiRefreshIntervalPreset = 1
        }
    }
}
