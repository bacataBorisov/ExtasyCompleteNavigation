import SwiftUI
import Observation

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
    
    // Property for calibration coefficient - speed log
    var calibrationCoefficient: Double {
        didSet {
            UserDefaults.standard.set(calibrationCoefficient, forKey: UserDefaultsKeys.calibrationCoefficient)
        }
    }

    init() {
        // Load initial values from UserDefaults
        self.metricWind = UserDefaults.standard.bool(forKey: UserDefaultsKeys.metricWind)
        self.tackTolerance = UserDefaults.standard.double(forKey: UserDefaultsKeys.tackTolerance)
        self.isWindModeActive = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isWindModeActive)
        self.calibrationCoefficient = UserDefaults.standard.double(forKey: UserDefaultsKeys.calibrationCoefficient)
    }
}
