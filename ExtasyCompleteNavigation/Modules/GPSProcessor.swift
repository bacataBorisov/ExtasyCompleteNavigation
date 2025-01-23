import CoreLocation

class GPSProcessor {
    // Serial queue for thread safety
    private let serialQueue = DispatchQueue(label: "com.extasy.waypointProcessor")
    
    var gpsData = GPSData() // Internal GPSData instance

    // Kalman filters for noisy parameters
    private var kalmanFilterLatitude = KalmanFilter(initialValue: 0.0, processNoise: 1e-4, measurementNoise: 1e-2)
    private var kalmanFilterLongitude = KalmanFilter(initialValue: 0.0, processNoise: 1e-4, measurementNoise: 1e-2)
    private var kalmanFilterSOG = KalmanFilter(initialValue: 0.0)
    private var kalmanFilterCOG = KalmanFilter(initialValue: 0.0)
    
    // MARK: - Public Methods
    func updateMarker(to coordinate: CLLocationCoordinate2D, _ name: String) {
        serialQueue.async { [self] in
            gpsData.markerName = name
            gpsData.markerCoordinate = coordinate
            gpsData.isTargetSelected = true
            
            debugLog("Marker updated to \(name), coordinates: \(coordinate.latitude), \(coordinate.longitude), [\(gpsData.isTargetSelected)]")
        }
    }
    
    func disableMarker() {
        serialQueue.async { [self] in
            gpsData.isTargetSelected = false
            gpsData.markerName = nil
            gpsData.markerCoordinate = nil
        }
    }
    
    func processGLL(_ splitStr: [String]) -> GPSData {
        guard splitStr.count >= 6 else {
            print("Invalid GLL Sentence!")
            gpsData.isGPSDataValid = false
            return gpsData
        }

        gpsData.isGPSDataValid = true
        // Apply Kalman filter to latitude and longitude
        let rawLatitude = toCLLDegreesLat(value: splitStr[2], direction: splitStr[3])
        let rawLongitude = toCLLDegreesLon(value: splitStr[4], direction: splitStr[5])
        
//        if let rawLat = rawLatitude {
//            gpsData.latitude = kalmanFilterLatitude.update(measurement: rawLat)
//        }
//        if let rawLon = rawLongitude {
//            gpsData.longitude = kalmanFilterLongitude.update(measurement: rawLon)
//        }
        gpsData.latitude = rawLatitude
        gpsData.longitude = rawLongitude
        
        return gpsData
    }

    func processRMC(_ splitStr: [String]) -> GPSData {
        guard splitStr.count >= 11, splitStr[3] == "A" else {
            print("Invalid RMC Sentence!")
            gpsData.isGPSDataValid = false
            return gpsData
        }
        
        gpsData.isGPSDataValid = true
        gpsData.utcTime = splitStr[2]
        
        // Apply Kalman filter to latitude and longitude
        let rawLatitude = toCLLDegreesLat(value: splitStr[4], direction: splitStr[5])
        let rawLongitude = toCLLDegreesLon(value: splitStr[6], direction: splitStr[7])
        
//        if let rawLat = rawLatitude {
//            gpsData.latitude = kalmanFilterLatitude.update(measurement: rawLat)
//        }
//        if let rawLon = rawLongitude {
//            gpsData.longitude = kalmanFilterLongitude.update(measurement: rawLon)
//        }

        gpsData.latitude = rawLatitude
        gpsData.longitude = rawLongitude
        
        // Apply Kalman filter to COG and SOG
        if let rawCOG = Double(splitStr[9]) {
            gpsData.courseOverGround = kalmanFilterCOG.update(measurement: rawCOG)
        }
        if let rawSOG = Double(splitStr[8]) {
            gpsData.speedOverGround = kalmanFilterSOG.update(measurement: rawSOG)
            gpsData.speedOverGroundKmh = gpsData.speedOverGround! * 1.852 // Convert knots to km/h
        }
        
        gpsData.gpsDate = splitStr[10]
        return gpsData
    }

    func processGGA(_ splitStr: [String]) -> GPSData {
        guard splitStr.count >= 7 else {
            print("Invalid GGA Sentence!")
            gpsData.isGPSDataValid = false

            return gpsData
        }
        gpsData.isGPSDataValid = true

        // Apply Kalman filter to latitude and longitude
        let rawLatitude = toCLLDegreesLat(value: splitStr[2], direction: splitStr[3])
        let rawLongitude = toCLLDegreesLon(value: splitStr[4], direction: splitStr[5])
        
        if let rawLat = rawLatitude {
            gpsData.latitude = kalmanFilterLatitude.update(measurement: rawLat)
        }
        if let rawLon = rawLongitude {
            gpsData.longitude = kalmanFilterLongitude.update(measurement: rawLon)
        }
        
        return gpsData
    }

    @discardableResult
    func resetGPSData() -> GPSData {
        gpsData.reset()
        print("GPS data has been reset.")
        return gpsData
    }

    // MARK: - Coordinates Conversion
    func toDecimalDegrees(value: String, direction: String) -> Double? {
        guard value.count >= 4 else { return nil } // Ensure the value has at least 4 characters for `ddmm.mmmm`.
        
        let splitIndex = (direction == "N" || direction == "S") ? 2 : 3
        guard let degrees = Double(value.prefix(splitIndex)),
              let minutes = Double(value.suffix(value.count - splitIndex)) else {
            return nil
        }
        
        let decimalDegrees = degrees + (minutes / 60)
        return (direction == "N" || direction == "E") ? decimalDegrees : -decimalDegrees
    }
    
    func toCLLDegreesLat(value: String, direction: String) -> Double? {
        return toDecimalDegrees(value: value, direction: direction)
    }

    func toCLLDegreesLon(value: String, direction: String) -> Double? {
        return toDecimalDegrees(value: value, direction: direction)
    }
}
