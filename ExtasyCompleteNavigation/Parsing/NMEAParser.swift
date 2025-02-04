//
//  NMEAReader.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 29.08.23.
//
//
//  General sentence format -> $ttsss,d1,d2,....<CR><LF>
//
//  Talkers ID:
//  $II -> Integrated Instrumentation
//  $GP - Global Positionin System (GPS)
//
//  All data with different identifiers and sentence headers is located in the
// "Resources" folder and it is called NMEASentencesExtasy
//
//
//

import CoreFoundation
import SwiftUI
import MapKit
import Observation
import CocoaAsyncSocket


@Observable
class NMEAParser:NSObject, GCDAsyncUdpSocketDelegate, GCDAsyncSocketDelegate {
    
    // MARK: - Raw String (Used in Advanced Settings)
    var latestRawData: [String] = []
    
    //MARK: - Variables that come from II - Integrated Instruments
    
    //HydroData Variables (speed log, depth, sea water temperature, etc.)
    @ObservationIgnored let hydroProcessor = HydroProcessor()
    var hydroData: HydroData?
    
    //CompassData Variables (magnetic heading)
    @ObservationIgnored let compassProcessor = CompassProcessor()
    var compassData: CompassData?
    
    // Wind Data Variables (AWF, AWW, TWF, TWA)
    @ObservationIgnored let windProcessor = WindProcessor()
    var windData: WindData?
    
    //MARK: - Variables that come from GP - external GPS
    
    @ObservationIgnored let gpsProcessor = GPSProcessor()
    var gpsData: GPSData?
    
    //MARK: - Mark Setup Variables & VMG
    
    // VMG - Calculated Values
    
    @ObservationIgnored var vmgProcessor = VMGProcessor()
    var vmgData: VMGData?
    
    @ObservationIgnored var waypointProcessor = WaypointProcessor()
    var waypointData: WaypointData?
    
    //UserSettingsValues
    
    //Watchdog variables
    private var lastWindUpdateTime: Date?
    private var dataTimeout: TimeInterval = 30 // Timeout in seconds
    
    // Data Logger
    let dataLogger = DataLogger()
    private var logTimer: Timer?
    
    //MARK: - Watchod Logic and Mechanism
    /**
     By calling it inside the init method, you ensure that the monitoring process starts as soon as the NMEAParser instance is created.
     This avoids relying on other parts of the code to remember to explicitly call this function after initialization.
     */
    override init() {
        
        super.init()
        // Assign the initialized local variable to self.vmgData
        startDataWatchdog()
        startPeriodicLogging()
    }
    
    // Start logging every 5 seconds
    func startPeriodicLogging() {
        logTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.logData()
        }
    }
    
    // MARK: - Centralized Logging Method
    private func logData() {
        guard let gps = gpsData else {
            debugLog("GPS data is not available. Skipping log entry.")
            return
        }
        // Always log raw data
        dataLogger.logRawData(
            gpsData: gps,
            hydroData: hydroData ?? HydroData(),
            compassData: compassData ?? CompassData(),
            windData: windData ?? WindData()
        )
        // Always log general data, even if no waypoint is selected
        dataLogger.logFilteredDataWaypointNotSelected(
            gpsData: gps,
            hydroData: hydroData ?? HydroData(),
            compassData: compassData ?? CompassData(),
            windData: windData ?? WindData(),
            vmgData: vmgData ?? VMGData()
        )

        // If a waypoint is selected, additionally log waypoint-specific data
        if gps.isTargetSelected, let waypoint = waypointData {
            dataLogger.logWaypointData(
                gpsData: gps,
                hydroData: hydroData ?? HydroData(),
                compassData: compassData ?? CompassData(),
                windData: windData ?? WindData(),
                vmgData: vmgData ?? VMGData(),
                waypointData: waypoint
            )
        }
    }
    
    func startDataWatchdog() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkForStaleData()
        }
    }
    
    func checkForStaleData() {
        guard let lastUpdate = windData?.lastUpdated else { return }
        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
        if timeSinceLastUpdate > dataTimeout {
            print("Wind data timeout! No update in the last \(dataTimeout) seconds.")
            //TODO: - Complete this section
            // Optionally trigger a UI update or error state
            //...
            //...
            //...
            //Display something or indicate warning sign in case there is no data
        }
    }
    
    //MARK: - NMEA String Processing
    
    func processRawString(rawData: String){
            
        DispatchQueue.main.async {
            self.latestRawData.append(rawData)

        }
        
        //Check first sign of the string
        guard rawData.first == "$" else {
            print("Invalid NMEA String Format")
            return
        }
        
        //Drop the dollar sign here, and then start processing the raw data
        let strippedData = String(rawData.dropFirst())
        
        //debugLog(rawData)
        //MARK: - 1) Step of NMEA protocol - Calculate and Validate the Checksum
        guard UtilsNMEA.validateChecksum(strippedData) else {
            print("Invalid Checksum!")
            return
        }
        //MARK: - 2) Step of NMEA protocol - Check that All Received Chars are Valid
        guard UtilsNMEA.validateChar(strippedData) else {
            print("Invalid Characters in NMEA String!")
            return
        }
        //MARK: - 3) Split the string
        //split the String and return it in an array of elements that will be our values
        let splitStr = UtilsNMEA.splitNMEAString(strippedData)
        guard splitStr.count > 2 else {
            print("Insufficient Components in the SplitStr!")
            return
        }
        //print(splitStr)
        
        //MARK: - 3) Step of NMEA Protocol - Identify & Validate Talker ID - splitStr[0]
        
        let talkerID = String(splitStr[0].prefix(2))
        
        guard UtilsNMEA.validateTalkerID(talkerID) else {
            print("Unknown talker ID: \(talkerID)")
            return
        }
        
        //MARK: - 4) Step of NMEA Protocol - Identify & Validate Sentence Format - splitStr[1]
        
        let sentenceFormat = splitStr[1]
        
        guard UtilsNMEA.validateSentenceFormat(sentenceFormat) else {
            print("Unknown sentence format: \(sentenceFormat)")
            return
        }
        
        
        //MARK: - 5) Parse Data Based on Sentence Format
        parseSentence(sentenceFormat, splitStr)

    }//END OF PROCESS RAW STRING
    
    //MARK: - Functions
    
    private func parseSentence(_ format: String, _ splitStr: [String]) {
        
        // Temporary variable to store updated data
        var updatedHydroData: HydroData?
        var updatedWindData: WindData?
        var updatedGPSData: GPSData?
        var updatedCompassData: CompassData?
        var updatedVMGData: VMGData?
        var updatedWaypointData: WaypointData?
        
        switch format {
            
            //MARK: - Depth
        case "DPT":
            updatedHydroData = hydroProcessor.processDepth(splitStr)
            
            
        case "HDG":
            //MARK: - Magnetic Heading with Corrected Variation
            updatedCompassData = compassProcessor.processCompassSentence(splitStr)
            
            //MARK: - Water Temperature
        case "MTW":
            //for the moment we don't have temperature sensor. I am not sure where exactly has been installed - probably in the speed log? Looks like our is not connected because we get an empty string when it has been returned. If we get a new speed log with temperature sensor we can use it. For the moment it will be skipped or just get "--"
            updatedHydroData = hydroProcessor.processSeaTemperature(splitStr)
            
            //MARK: - Wind Sensor Data
        case "MWV":
            
            updatedWindData = windProcessor.processWindSentence(splitStr, compassData: compassData, hydroData: hydroData)
            
            //MARK: - Boat Speed & Distance Travelled from Lag
        case "VHW":
            
            updatedHydroData = hydroProcessor.processSpeedLog(splitStr)
            
            //Distance travelled through water in nautical miles
        case "VLW":
            
            updatedHydroData = hydroProcessor.processDistanceTravelled(splitStr)
            
            //MARK: - GPS Sentences
            
            /*   For the moment I rely on one source of GPS - it is external one, since the one integrated with B&N 'II'
             does not work.
             In case we fix it I need to fix the code and decide how to proceed - choose one at a time or average for both for better accuracy.
             To be decided later on
             */
            
            //Geohraphic Position - Latitude / Longtitude
        case "GLL":
            //once we fix our GPS, this can be used for determing out coordinates
            fallthrough
        case "GGA":
            fallthrough
            //print(splitStr)
            //GSA - GPS DOP and active satellites - only for information in terminal
        case "GSA":
            fallthrough
            //print(splitStr)
            //GSV - Satellite in view - Only for Information in terminal
        case "GSV":
            fallthrough
            //print(splitStr)
            //RMC - Recommended Minimum Navigation
        case "RMC":
            
            updatedGPSData = gpsProcessor.processRMC(splitStr)
            
            //Recommended Minimum Navigation Information
        case "RMB":
            //it will probably be active when autopilot is active. It can be used only for information. I can't send any data to the autopilot
            //that gives you information about positioned waypoints. It can be used instead of calculations
            //it has to be tested what is better - iOS system calculations or this information - to be compared once the GPS has been repaired.
            fallthrough
            //VTG - Track Made Good and Ground Speed - it is active when the autopilot is active
            //this one might not exist at all??? - check when on the boat
        case "VTG":
            //this can be used only for informatio. I can't send any data to the autopilot
            fallthrough
        default:
            break
        }
        
        //MARK: - Update VMG Data
        // **Call processVMGData after relevant updates**
        updatedVMGData =  vmgProcessor.processVMGData(
            gpsData: gpsData,
            hydroData: hydroData,
            windData: windData
        )
        
        //process only when there is a valid marker coordinate
        if let _ = updatedGPSData?.waypointLocation {
            
            updatedWaypointData = waypointProcessor.processWaypointData(
                vmgData: vmgData,
                gpsData: gpsData,
                windData: windData
            )
        }
        
        // Updates MUST happen on the Main Thread
        DispatchQueue.main.async { [self] in
            
            // Ensure the variable is used only if updated
            if let hydro = updatedHydroData { hydroData = hydro }
            if let wind = updatedWindData { windData = wind;lastWindUpdateTime = updatedWindData?.lastUpdated }
            if let gps = updatedGPSData { gpsData = gps }
            if let compass = updatedCompassData { compassData = compass }
            if let vmg = updatedVMGData { vmgData = vmg }
            if let waypoint = updatedWaypointData { waypointData = waypoint }
            
        }

    }//END OF PARSE SENTENCE
    
    //TODO: - Fix this because it is insane - it is just for the test
    // it has to be removed, I should parse the normalized angles straight or add this to WindData structure
    //Function to normalize values for display
    func displayValue(a: Int) -> Double? {
        
        switch a {
        case 0:
            return hydroData?.depth
        case 1:
            return compassData?.normalizedHeading
        case 2:
            return hydroData?.seaWaterTemperature
        case 3:
            return hydroData?.boatSpeedLag
        case 4:
            return windData?.apparentWindAngle
        case 5:
            return windData?.apparentWindDirection
        case 6:
            if AppSettings.metricWind {
                return (windData?.apparentWindForce ?? 0) * toMetersPerSecond
            } else {
                return windData?.apparentWindForce
            }
        case 7:
            return windData?.trueWindAngle
        case 8:
            return windData?.trueWindDirection
        case 9:
            if AppSettings.metricWind {
                return (windData?.trueWindForce ?? 0) * toMetersPerSecond
            } else {
                return windData?.trueWindForce
            }
        case 10:
            return gpsData?.courseOverGround
        case 11:
            return gpsData?.speedOverGround
        default:
            return nil
        }
    }//END OF displayValue function
}






