class HydroProcessor {
    
    // Internal HydroData instance (not exposed)
    private var hydroData = HydroData()
    
    // Kalman filters for smoothing data
    private var depthFilter: KalmanFilter?
    private var temperatureFilter: KalmanFilter?
    private var speedLogFilter: KalmanFilter?
    
    // Initialize the HydroProcessor with optional initial values for Kalman filters
    init() {
        // Fine tune if needed during the real tests
        depthFilter = KalmanFilter(initialValue: 0.0, processNoise: 1e-5, measurementNoise: 1e-1)
        temperatureFilter = KalmanFilter(initialValue: 0.0, processNoise: 1e-5, measurementNoise: 1e-1)
        speedLogFilter = KalmanFilter(initialValue: 0.0, processNoise: 1e-5, measurementNoise: 1e-1)
    }
    
    // Process depth-related data and return updated HydroData
    func processDepth(_ splitStr: [String]) -> HydroData? {
        guard splitStr.count >= 3, let depthValue = Double(splitStr[2]) else {
            print("Invalid Depth Data!")
            return nil
        }
        // Store raw depth
        hydroData.rawDepth = depthValue
        
        // Apply Kalman filtering to smooth the depth value
        if let filteredDepth = depthFilter?.update(measurement: depthValue) {
            hydroData.depth = filteredDepth
        } else {
            hydroData.depth = depthValue // Fallback to raw value if filtering fails
        }
        
        return hydroData
    }
    
    // Process sea water temperature and return updated HydroData
    func processSeaTemperature(_ splitStr: [String]) -> HydroData? {
        guard splitStr.count >= 3, let temperature = Double(splitStr[2]) else {
            print("Invalid Sea Water Temperature Data!")
            return nil
        }
        
        // Store raw sea water temperature
        hydroData.rawSeaWaterTemperature = temperature
        
        // Apply Kalman filtering to smooth the temperature value
        if let filteredTemperature = temperatureFilter?.update(measurement: temperature) {
            hydroData.seaWaterTemperature = filteredTemperature
        } else {
            hydroData.seaWaterTemperature = temperature // Fallback to raw value if filtering fails
        }
        
        return hydroData
    }
    
    // Process speed through water and return updated HydroData
    func processSpeedLog(_ splitStr: [String]) -> HydroData? {
        guard splitStr.count >= 7, let speedLog = Double(splitStr[6]) else {
            print("Invalid Speed Log Data!")
            return nil
        }
        
        // Store raw boat speed (before filtering)
        hydroData.rawBoatSpeedLag = speedLog
        
        let calibrationCoefficient = hydroData.speedLogCalibrationCoeff ?? 1.0
        let calibratedSpeed = speedLog * calibrationCoefficient
        
        // Apply Kalman filtering to smooth the speed log value
        if let filteredSpeed = speedLogFilter?.update(measurement: calibratedSpeed) {
            hydroData.boatSpeedLag = filteredSpeed
        } else {
            hydroData.boatSpeedLag = calibratedSpeed // Fallback to raw value if filtering fails
        }
        
        return hydroData
    }
    
    // Process total distance through water and return updated HydroData
    func processDistanceTravelled(_ splitStr: [String]) -> HydroData? {
        guard splitStr.count >= 5,
              let totalDistance = Double(splitStr[2]),
              let distanceSinceReset = Double(splitStr[4]) else {
            print("Invalid Distance Data!")
            return nil
        }
        hydroData.totalDistance = totalDistance
        hydroData.distSinceReset = distanceSinceReset
        return hydroData
    }
    
    // Reset hydro data and return the reset state
    func resetHydroData() -> HydroData {
        hydroData.reset()
        return hydroData
    }
    
    // Function to update the speedLog calibration coefficient
    func updateCalibrationCoeff(value: Double) {
        guard value > 0 else {
            debugLog("Invalid calibration coefficient. The value must be greater than 0.")
            return
        }
        
        // Update the calibration coefficient
        hydroData.speedLogCalibrationCoeff = value
        debugLog("Calibration coefficient updated to \(value)")
    }
}
