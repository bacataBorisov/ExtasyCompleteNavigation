//  DataLogger.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 2025-02-01.

import Foundation
import CoreLocation

// MARK: - Data Logger Class

class DataLogger {
    private let filteredDataWaypointNotSelectedPath: URL
    private let rawDataPath: URL
    private let timestamp: String
    private var waypointFilePaths: [String: URL] = [:]  // To keep track of waypoint-specific files

    init() {
        // Generate timestamp BEFORE initializing file paths
        let formatter = DateFormatter()
        formatter.dateFormat = "d-MMM-yyyy_HH-mm-ss"  // Example: 2-Feb-2025_14-15-00
        self.timestamp = formatter.string(from: Date())
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Define file path for general data logging
        self.filteredDataWaypointNotSelectedPath = documentsDirectory.appendingPathComponent("\(timestamp)_general_filtered_data.csv")
        self.rawDataPath = documentsDirectory.appendingPathComponent("\(timestamp)_raw_data.csv")

        
        // Create CSV headers if the general file doesn't exist
        createCSVFileIfNeeded(at: filteredDataWaypointNotSelectedPath, headers: generalHeaders())
        createCSVFileIfNeeded(at: rawDataPath, headers: rawDataHeaders())

    }
    
    // MARK: - Raw Data Logging
    func logRawData(gpsData: GPSData, hydroData: HydroData, compassData: CompassData, windData: WindData) {
        let timestamp = ISO8601DateFormatter().string(from: Date())

        let rawDataString = "\(timestamp)," +
            "\(formatValue(gpsData.rawLatitude, precision: 6))," +  // Latitude with 6 decimal places
            "\(formatValue(gpsData.rawLongitude, precision: 6))," + // Longitude with 6 decimal places
            "\(formatValue(gpsData.rawCourseOverGround, precision: 2))," + // COG with 2 decimal places
            "\(formatValue(gpsData.rawSpeedOverGround, precision: 2))," +  // SOG with 2 decimal places
            "\(formatValue(hydroData.rawDepth, precision: 2))," +          // Depth with 1 decimal place
            "\(formatValue(hydroData.rawSeaWaterTemperature, precision: 2))," + // Temperature with 1 decimal place
            "\(formatValue(hydroData.rawBoatSpeedLag, precision: 2))," +        // Speed log with 2 decimal places
            "\(formatValue(compassData.rawMagneticHeading, precision: 1))," +   // Heading with 1 decimal place
            "\(formatValue(compassData.rawNormalizedHeading, precision: 1))," + // Normalized heading with 1 decimal place
            "\(formatValue(windData.rawApparentWindAngle, precision: 2))," +    // AWA with 1 decimal place
            "\(formatValue(windData.rawApparentWindForce, precision: 2))," +    // AWS with 2 decimal places
            "\(formatValue(windData.rawApparentWindDirection, precision: 2))," + // AWD with 1 decimal place
            "\(formatValue(windData.rawTrueWindAngle, precision: 2))," +        // TWA with 1 decimal place
            "\(formatValue(windData.rawTrueWindForce, precision: 2))," +        // TWS with 2 decimal places
            "\(formatValue(windData.rawTrueWindDirection, precision: 1))"       // TWD with 1 decimal place

        appendToCSV(at: rawDataPath, data: rawDataString)
    }
    
    // MARK: - General Data Logging (Always Active)
    func logFilteredDataWaypointNotSelected(gpsData: GPSData, hydroData: HydroData, compassData: CompassData, windData: WindData, vmgData: VMGData) {
        logData(
            to: filteredDataWaypointNotSelectedPath,
            gpsData: gpsData,
            hydroData: hydroData,
            compassData: compassData,
            windData: windData,
            vmgData: vmgData,
            waypointData: nil
        )
    }

    // MARK: - Waypoint-Specific Data Logging
    func logWaypointData(gpsData: GPSData, hydroData: HydroData, compassData: CompassData, windData: WindData, vmgData: VMGData, waypointData: WaypointData) {
        guard let waypointName = gpsData.waypointName?.replacingOccurrences(of: " ", with: "_") else {
            debugLog("Waypoint name is missing, skipping waypoint data logging.")
            return
        }

        // Check if the file for this waypoint already exists, else create it
        let waypointFilePath: URL
        if let existingPath = waypointFilePaths[waypointName] {
            waypointFilePath = existingPath
        } else {
            waypointFilePath = createWaypointFilePath(waypointName: waypointName)
            createCSVFileIfNeeded(at: waypointFilePath, headers: waypointHeaders())
            waypointFilePaths[waypointName] = waypointFilePath
        }

        // Log the data to the waypoint-specific file
        logData(
            to: waypointFilePath,
            gpsData: gpsData,
            hydroData: hydroData,
            compassData: compassData,
            windData: windData,
            vmgData: vmgData,
            waypointData: waypointData
        )
    }
    
    // MARK: - Generalized Logging Method
    private func logData(to filePath: URL, gpsData: GPSData, hydroData: HydroData, compassData: CompassData, windData: WindData, vmgData: VMGData, waypointData: WaypointData?) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        // Collect base data values
        var dataString = "\(timestamp)," +
            "\(gpsData.isGPSDataValid)," +
            "\(formatValue(gpsData.latitude, precision: 6))," +                    // Latitude with 6 decimal places
            "\(formatValue(gpsData.longitude, precision: 6))," +                   // Longitude with 6 decimal places
            "\(formatValue(gpsData.courseOverGround, precision: 1))," +            // COG with 1 decimal place
            "\(formatValue(gpsData.speedOverGround, precision: 2))," +             // SOG with 2 decimal places
            "\(formatValue(gpsData.speedOverGroundKmh, precision: 2))," +          // SOG km/h with 2 decimal places
            "\(gpsData.utcTime ?? "N/A")," +
            "\(gpsData.gpsDate ?? "N/A")," +
            "\(formatValue(hydroData.boatSpeedLag, precision: 2))," +              // Boat speed lag with 2 decimal places
            "\(formatValue(hydroData.seaWaterTemperature, precision: 2))," +       // Sea water temperature with 1 decimal place
            "\(formatValue(hydroData.totalDistance, precision: 2))," +             // Total distance with 2 decimal places
            "\(formatValue(hydroData.distSinceReset, precision: 2))," +            // Distance since reset with 2 decimal places
            "\(formatValue(hydroData.depth, precision: 1))," +                     // Depth with 1 decimal place
            "\(formatValue(compassData.normalizedHeading, precision: 1))," +       // Normalized heading with 1 decimal place
            "\(formatValue(windData.apparentWindAngle, precision: 1))," +          // Apparent wind angle with 1 decimal place
            "\(formatValue(windData.apparentWindForce, precision: 2))," +          // Apparent wind force with 2 decimal places
            "\(formatValue(windData.apparentWindDirection, precision: 2))," +      // Apparent wind direction with 1 decimal place
            "\(formatValue(windData.trueWindAngle, precision: 2))," +              // True wind angle with 1 decimal place
            "\(formatValue(windData.trueWindForce, precision: 2))," +              // True wind force with 2 decimal places
            "\(formatValue(windData.trueWindDirection, precision: 2))," +          // True wind direction with 1 decimal place
            "\(formatValue(vmgData.polarSpeed, precision: 2))," +                  // Polar speed with 2 decimal places
            "\(formatValue(vmgData.polarVMG, precision: 2))," +                    // Polar VMG with 2 decimal places
            "\(formatValue(vmgData.vmgOverGround, precision: 2))," +               // VMG over ground with 2 decimal places
            "\(formatValue(vmgData.vmgOverGroundPerformance, precision: 2))," +    // VMG over ground performance with 2 decimal places
            "\(formatValue(vmgData.vmgThroughWater, precision: 2))," +             // VMG through water with 2 decimal places
            "\(formatValue(vmgData.vmgThroughWaterPerformance, precision: 2))," +  // VMG through water performance with 2 decimal places
            "\(formatValue(vmgData.speedPerformanceThroughWater, precision: 2))," +// Speed performance through water with 2 decimal places
            "\(formatValue(vmgData.speedPerformanceOverGround, precision: 2))," +  // Speed performance over ground with 2 decimal places
            "\(formatValue(vmgData.optimalUpTWA, precision: 1))," +                // Optimal upwind TWA with 1 decimal place
            "\(formatValue(vmgData.optimalDnTWA, precision: 1))," +                // Optimal downwind TWA with 1 decimal place
            "\(formatValue(vmgData.maxUpVMG, precision: 2))," +                    // Max upwind VMG with 2 decimal places
            "\(formatValue(vmgData.maxDnVMG, precision: 2))," +                    // Max downwind VMG with 2 decimal places
            "\(vmgData.sailingState ?? "N/A")," +                                  // Sailing state as string
            "\(formatValue(vmgData.sailingStateLimit, precision: 1))"              // Sailing state limit with 1 decimal place
        
        // Append waypoint data if available
        if let waypoint = waypointData {
            dataString += "," +
                "\(formatValue(waypoint.distanceToMark, precision: 2))," +               // Distance to mark with 2 decimal places
                "\(formatValue(waypoint.tripDurationToWaypoint, precision: 0))," +       // Trip duration as whole seconds
                "\(formatDate(waypoint.etaToWaypoint))," +                               // ETA in ISO8601 format
                "\(formatValue(waypoint.tackDistance, precision: 2))," +                 // Tack distance with 2 decimal places
                "\(formatValue(waypoint.tackDuration, precision: 0))," +                 // Tack duration as whole seconds
                "\(formatValue(waypoint.distanceOnOppositeTack, precision: 2))," +       // Distance on opposite tack with 2 decimal places
                "\(formatValue(waypoint.tripDurationOnOppositeTack, precision: 0))," +   // Trip duration on opposite tack as whole seconds
                "\(formatValue(waypoint.trueMarkBearing, precision: 1))," +              // True mark bearing with 1 decimal place
                "\(waypoint.currentTackState ?? "N/A")," +                               // Current tack state as string
                "\(formatValue(waypoint.currentTackRelativeBearing, precision: 1))," +   // Current tack relative bearing with 1 decimal place
                "\(waypoint.oppositeTackState ?? "N/A")," +                              // Opposite tack state as string
                "\(formatValue(waypoint.oppositeTackRelativeBearing, precision: 1))," +  // Opposite tack relative bearing with 1 decimal place
                "\(formatValue(waypoint.currentTackVMC, precision: 2))," +               // Current tack VMC with 2 decimal places
                "\(formatValue(waypoint.currentTackVMCDisplay, precision: 2))," +        // Current tack VMC display with 2 decimal places
                "\(formatValue(waypoint.oppositeTackVMC, precision: 2))," +              // Opposite tack VMC with 2 decimal places
                "\(formatValue(waypoint.oppositeTackVMCDisplay, precision: 2))," +       // Opposite tack VMC display with 2 decimal places
                "\(formatValue(waypoint.currentTackVMCPerformance, precision: 2))," +    // Current tack VMC performance with 2 decimal places
                "\(formatValue(waypoint.oppositeTackVMCPerformance, precision: 2))," +   // Opposite tack VMC performance with 2 decimal places
                "\(formatValue(waypoint.polarVMC, precision: 2))," +                     // Polar VMC with 2 decimal places
                "\(formatValue(waypoint.maxTackPolarVMC, precision: 2))," +              // Max tack polar VMC with 2 decimal places
                "\(waypoint.isVMCNegative)"                                             // VMC negative as a boolean
        }
        
        // Append data to CSV
        appendToCSV(at: filePath, data: dataString)
    }
    
    // MARK: - Helper Methods for CSV Handling
    
    private func createCSVFileIfNeeded(at url: URL, headers: String) {
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try "\(headers)\n".write(to: url, atomically: true, encoding: .utf8)
                debugLog("Created CSV file at \(url.path)")
            } catch {
                debugLog("Failed to create CSV file at \(url.path): \(error)")
            }
        }
    }

    private func appendToCSV(at url: URL, data: String) {
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                let fileHandle = try FileHandle(forWritingTo: url)
                fileHandle.seekToEndOfFile()
                if let dataToAppend = "\(data)\n".data(using: .utf8) {
                    fileHandle.write(dataToAppend)
                }
                fileHandle.closeFile() // Ensure the file is closed after writing
            } else {
                try "\(data)\n".write(to: url, atomically: true, encoding: .utf8)
            }
        } catch {
            debugLog("Failed to write to CSV file at \(url.path): \(error)")
        }
    }

    // MARK: - Helper to Create Waypoint File Paths
    private func createWaypointFilePath(waypointName: String) -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let waypointFileName = "\(timestamp)_\(waypointName)_data.csv"
        return documentsDirectory.appendingPathComponent(waypointFileName)
    }

    // MARK: - CSV Headers
    private func rawDataHeaders() -> String {
        return "timestamp,latitude,longitude,COG,SOG,Depth,SeaWaterTemperature,BoatSpeedLag,MagneticHeading,NormalizedHeading,AWA,AWF,AWD,TWA,TWF,TWD"
    }
    private func generalHeaders() -> String {
        return "timestamp,isGPSDataValid,latitude,longitude,COG,SOG_knots,SOG_kmh,utcTime,gpsDate,boatSpeedLag,seaWaterTemperature,totalDistance,distSinceReset,depth,normalizedHeading,AWA,AWS,AWD,TWA,TWS,TWD,polarSpeed,polarVMG,vmgOverGround,vmgOverGroundPerformance,vmgThroughWater,vmgThroughWaterPerformance,speedPerformanceThroughWater,speedPerformanceOverGround,optimalUpTWA,optimalDnTWA,maxUpVMG,maxDnVMG,sailingState,sailingStateLimit"
    }

    private func waypointHeaders() -> String {
        return generalHeaders() + ",distanceToMark,tripDurationToWaypoint,etaToWaypoint,tackDistance,tackDuration,distanceOnOppositeTack,tripDurationOnOppositeTack,trueMarkBearing,currentTackState,currentTackRelativeBearing,oppositeTackState,oppositeTackRelativeBearing,currentTackVMC,currentTackVMCDisplay,oppositeTackVMC,oppositeTackVMCDisplay,currentTackVMCPerformance,oppositeTackVMCPerformance,polarVMC,maxTackPolarVMC,isVMCNegative"
    }
    
    // Helper to format date & value for CSV
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        return ISO8601DateFormatter().string(from: date)
    }
    
    private func formatValue(_ value: Double?, precision: Int) -> String {
        guard let value = value else { return "0.0" }
        return String(format: "%.\(precision)f", value)
    }
}
