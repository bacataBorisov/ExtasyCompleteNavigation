import Foundation
import CoreLocation

class GPSProcessor {
    private let serialQueue = DispatchQueue(label: "com.extasy.gpsProcessor")
    var gpsData = GPSData()
    //NOTE: - Kalman coeff. set to mimic as close as possible to the input values. Adjustment to be made in a later stage
    private var kalmanFilterLatitude = KalmanFilter(initialValue: 0.0, processNoise: 1.0, measurementNoise: 1e-9)
    private var kalmanFilterLongitude = KalmanFilter(initialValue: 0.0, processNoise: 1.0, measurementNoise: 1e-9)
    private var kalmanFilterSOG = KalmanFilter(initialValue: 0.0, processNoise: 1.0, measurementNoise: 1e-9)
    private var kalmanFilterCOG = KalmanFilter(initialValue: 0.0, processNoise: 1.0, measurementNoise: 1e-9)
    
    // MARK: - Public Methods
    func updateMarker(to coordinate: CLLocationCoordinate2D, _ name: String) {
        serialQueue.async { [self] in
            gpsData.waypointName = name
            gpsData.waypointLocation = coordinate
            gpsData.isTargetSelected = true
            
            debugLog("Marker updated to \(name), coordinates: \(coordinate.latitude), \(coordinate.longitude), [\(gpsData.isTargetSelected)]")
        }
    }
    
    func disableMarker() {
        serialQueue.async { [self] in
            gpsData.isTargetSelected = false
            gpsData.waypointName = nil
            gpsData.waypointLocation = nil
        }
    }
    
    // MARK: - Process GLL
    func processGLL(_ splitStr: [String]) -> GPSData {
        guard splitStr.count >= 6 else {
            debugLog("Invalid GLL Sentence!")
            gpsData.isGPSDataValid = false
            return gpsData
        }

        gpsData.isGPSDataValid = true

        let rawLatitude = toCLLDegreesLat(value: splitStr[2], direction: splitStr[3])
        let rawLongitude = toCLLDegreesLon(value: splitStr[4], direction: splitStr[5])

        // Store raw data
        gpsData.rawLatitude = rawLatitude
        gpsData.rawLongitude = rawLongitude

        // Apply filters to get smooth data
        if let rawLat = rawLatitude {
            gpsData.latitude = kalmanFilterLatitude.update(measurement: rawLat)
        }
        if let rawLon = rawLongitude {
            gpsData.longitude = kalmanFilterLongitude.update(measurement: rawLon)
        }

        return gpsData
    }

    // MARK: - Process RMC
    func processRMC(_ splitStr: [String]) -> GPSData {
        guard splitStr.count >= 11, splitStr[3] == "A" else {
            debugLog("Invalid RMC Sentence!")
            gpsData.isGPSDataValid = false
            return gpsData
        }

        gpsData.isGPSDataValid = true
        gpsData.utcTime = splitStr[2]

        let rawLatitude = toCLLDegreesLat(value: splitStr[4], direction: splitStr[5])
        let rawLongitude = toCLLDegreesLon(value: splitStr[6], direction: splitStr[7])
        let rawCOG = Double(splitStr[9])
        let rawSOG = Double(splitStr[8])

        // Store raw values
        gpsData.rawLatitude = rawLatitude
        gpsData.rawLongitude = rawLongitude
        gpsData.rawCourseOverGround = rawCOG
        gpsData.rawSpeedOverGround = rawSOG

        // Apply filters to smooth values
        if let rawLat = rawLatitude {
            gpsData.latitude = kalmanFilterLatitude.update(measurement: rawLat)
        }
        if let rawLon = rawLongitude {
            gpsData.longitude = kalmanFilterLongitude.update(measurement: rawLon)
        }
        if let cog = rawCOG {
            gpsData.courseOverGround = kalmanFilterCOG.update(measurement: cog)
        }
        if let sog = rawSOG {
            gpsData.speedOverGround = kalmanFilterSOG.update(measurement: sog)
            gpsData.speedOverGroundKmh = sog * 1.852
        }

        gpsData.gpsDate = splitStr[10]
        return gpsData
    }

    // MARK: - Process GGA
    func processGGA(_ splitStr: [String]) -> GPSData {
        guard splitStr.count >= 7 else {
            debugLog("Invalid GGA Sentence!")
            gpsData.isGPSDataValid = false
            return gpsData
        }

        gpsData.isGPSDataValid = true

        let rawLatitude = toCLLDegreesLat(value: splitStr[2], direction: splitStr[3])
        let rawLongitude = toCLLDegreesLon(value: splitStr[4], direction: splitStr[5])

        // Store raw data
        gpsData.rawLatitude = rawLatitude
        gpsData.rawLongitude = rawLongitude

        // Apply filters
        if let rawLat = rawLatitude {
            gpsData.latitude = kalmanFilterLatitude.update(measurement: rawLat)
        }
        if let rawLon = rawLongitude {
            gpsData.longitude = kalmanFilterLongitude.update(measurement: rawLon)
        }

        return gpsData
    }

    // MARK: - Reset
    @discardableResult
    func resetGPSData() -> GPSData {
        gpsData.reset()
        debugLog("GPS data has been reset.")
        return gpsData
    }

    // MARK: - Coordinates Conversion
    func toDecimalDegrees(value: String, direction: String) -> Double? {
        guard value.count >= 4 else { return nil }
        
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
