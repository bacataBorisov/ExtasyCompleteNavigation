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
import WatchConnectivity


// MARK: - Sensor Freshness Tracking

enum SensorStatus: String {
    case active
    case stale
    case unavailable
}

struct DataStatus {
    var wind: SensorStatus = .unavailable
    var gps: SensorStatus = .unavailable
    var hydro: SensorStatus = .unavailable
    var compass: SensorStatus = .unavailable
    
    var overallHealthy: Bool {
        [wind, gps, hydro, compass].allSatisfy { $0 == .active }
    }
    
    var anyActive: Bool {
        [wind, gps, hydro, compass].contains { $0 == .active }
    }
    
    func sensorStatus(forValueID id: Int) -> SensorStatus {
        switch id {
        case 0, 2, 3: return hydro
        case 1: return compass
        case 4, 5, 6, 7, 8, 9: return wind
        case 10, 11: return gps
        default: return .unavailable
        }
    }
}

@Observable
class NMEAParser:NSObject, GCDAsyncUdpSocketDelegate, GCDAsyncSocketDelegate {
    
    
    // MARK: - Raw String (Used in Advanced Settings)
    var latestRawData: [String] = []
    
    // MARK: - Sensor Data Status
    var dataStatus = DataStatus()
    
    //MARK: - Variables that come from II - Integrated Instruments
    
    @ObservationIgnored let hydroProcessor = HydroProcessor()
    var hydroData: HydroData?
    
    @ObservationIgnored let compassProcessor = CompassProcessor()
    var compassData: CompassData?
    
    @ObservationIgnored let windProcessor = WindProcessor()
    var windData: WindData?
    
    //MARK: - Variables that come from GP - external GPS
    
    @ObservationIgnored let gpsProcessor = GPSProcessor()
    var gpsData: GPSData?
    
    //MARK: - Mark Setup Variables & VMG
    
    @ObservationIgnored var vmgProcessor = VMGProcessor()
    var vmgData: VMGData?
    
    @ObservationIgnored var waypointProcessor = WaypointProcessor()
    var waypointData: WaypointData?
    
    // Staleness threshold — data older than this is considered stale
    private let dataTimeout: TimeInterval = 30
    
    // Data Logger
    let dataLogger = DataLogger()
    private var logTimer: Timer?
    
    private var periodicUpdateTimer: Timer?

    // Temporary caches — protected by dataLock for cross-thread access
    private var cachedHydroData: HydroData?
    private var cachedWindData: WindData?
    private var cachedGPSData: GPSData?
    private var cachedCompassData: CompassData?
    private var cachedVMGData: VMGData?
    private var cachedWaypointData: WaypointData?
    private let dataLock = NSLock()

    //MARK: - Timer function for UI Updates and Watch Session which is delibaretly offset from the 1 sec NMEA received singal
    
    /// MARK: - MainActor & Task
    ///
    /// `@MainActor` ensures that any method or property marked with it is always executed on the main thread,
    /// which is critical when working with UI elements or state that affects the UI.
    /// It replaces the need to manually wrap code in `DispatchQueue.main.async`.
    ///
    /// Example:
    ///     @MainActor
    ///     func updateUI() { ... } // Always runs on the main thread
    ///
    /// When calling an `@MainActor` method from a background context (like a Timer or async task),
    /// you should use `Task { await ... }` to safely hop to the main thread:
    ///
    ///     Task {
    ///         await self?.updateUI()
    ///     }
    ///
    /// This pattern provides safe, readable, and efficient thread management for UI-related operations.
    ///
    @MainActor
    private func performPeriodicUpdate() {
        dataLock.lock()
        let hydro = cachedHydroData
        let wind = cachedWindData
        let gps = cachedGPSData
        let compass = cachedCompassData
        let vmg = cachedVMGData
        let waypoint = cachedWaypointData
        dataLock.unlock()
        
        if let h = hydro { hydroData = h }
        if let w = wind { windData = w }
        if let g = gps { gpsData = g }
        if let c = compass { compassData = c }
        if let v = vmg { vmgData = v }
        if let wp = waypoint { waypointData = wp }

        //arra of tuples to loop through when sending
        
        let metricsToUpdate: [(String, Double?, RoundingPrecision)] = [
            //core data to watch
            ("depth", hydroData?.depth, .tenths),
            ("heading", compassData?.normalizedHeading, .whole),
            ("speed", hydroData?.boatSpeedLag, .hundredths),
            ("sog", gpsData?.speedOverGround, .hundredths),
            
            //wind data to wathc
            ("tws", windData?.trueWindForce, .tenths),
            ("twa", windData?.trueWindAngle, .whole),
            ("twd", windData?.trueWindDirection, .whole),
            ("aws", windData?.apparentWindForce, .tenths),
            ("awa", windData?.apparentWindAngle, .whole),
            ("awd", windData?.apparentWindDirection, .whole),
            
        ]

        for (key, value, precision) in metricsToUpdate {
            DataCoordinator.shared.update(metric: key, value: value, precision: precision)
        }

        DataCoordinator.shared.sendIfChanged()
    }
    
    private func startPeriodicDataUpdate() {
        periodicUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.037, repeats: true) { [weak self] _ in
            Task {
                await self?.performPeriodicUpdate()
            }
        }
    }

    // MARK: - Sensor Smoothing (Kalman damping)

    /// AWA, TWA, AWS, TWS
    func updateWindDamping(level: Int) {
        windProcessor.updateDamping(level: level)
    }

    /// SOG, COG (GPS-derived speed and course)
    func updateSpeedDamping(level: Int) {
        gpsProcessor.updateDamping(level: level)
    }

    /// HDG (compass heading)
    func updateHeadingDamping(level: Int) {
        compassProcessor.updateDamping(level: level)
    }

    /// DPT, SWT, BSPD (depth, sea temp, boat speed log)
    func updateHydroDamping(level: Int) {
        hydroProcessor.updateDamping(level: level)
    }

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
        // start UI update timer
        startPeriodicDataUpdate()
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
            Task { @MainActor in
                self?.checkForStaleData()
            }
        }
    }
    
    @MainActor
    func checkForStaleData() {
        let now = Date()
        dataStatus.wind = sensorStatus(for: windData?.lastUpdated, now: now)
        dataStatus.gps = sensorStatus(for: gpsData?.lastUpdated, now: now)
        dataStatus.hydro = sensorStatus(for: hydroData?.lastUpdated, now: now)
        dataStatus.compass = sensorStatus(for: compassData?.lastUpdated, now: now)
    }
    
    private func sensorStatus(for lastUpdated: Date?, now: Date) -> SensorStatus {
        guard let lastUpdated else { return .unavailable }
        return now.timeIntervalSince(lastUpdated) > dataTimeout ? .stale : .active
    }
    
    //MARK: - NMEA String Processing
    
    func processRawString(rawData: String){
        
        DispatchQueue.main.async {
            self.latestRawData.append(rawData)
            
        }
        
        //Check first sign of the string
        guard rawData.first == "$" else {
            Log.parsing.warning("Invalid NMEA String Format")
            return
        }
        
        //Drop the dollar sign here, and then start processing the raw data
        let strippedData = String(rawData.dropFirst())
        
        //debugLog(rawData)
        //MARK: - 1) Step of NMEA protocol - Calculate and Validate the Checksum
        guard UtilsNMEA.validateChecksum(strippedData) else {
            Log.parsing.warning("Invalid Checksum!")
            return
        }
        //MARK: - 2) Step of NMEA protocol - Check that All Received Chars are Valid
        guard UtilsNMEA.validateChar(strippedData) else {
            Log.parsing.warning("Invalid Characters in NMEA String!")
            return
        }
        //MARK: - 3) Split the string
        //split the String and return it in an array of elements that will be our values
        let splitStr = UtilsNMEA.splitNMEAString(strippedData)
        guard splitStr.count > 2 else {
            Log.parsing.warning("Insufficient Components in the SplitStr!")
            return
        }
        //print(splitStr)
        
        //MARK: - 3) Step of NMEA Protocol - Identify & Validate Talker ID - splitStr[0]
        
        let talkerID = String(splitStr[0].prefix(2))
        
        guard UtilsNMEA.validateTalkerID(talkerID) else {
            Log.parsing.debug("Unknown talker ID: \(talkerID)")
            return
        }
        
        //MARK: - 4) Step of NMEA Protocol - Identify & Validate Sentence Format - splitStr[1]
        
        let sentenceFormat = splitStr[1]
        
        guard UtilsNMEA.validateSentenceFormat(sentenceFormat) else {
            Log.parsing.debug("Unknown sentence format: \(sentenceFormat)")
            return
        }
        
        
        //MARK: - 5) Parse Data Based on Sentence Format
        parseSentence(sentenceFormat, splitStr)

    }//END OF PROCESS RAW STRING

    //MARK: - Functions
    
    private func parseSentence(_ format: String, _ splitStr: [String]) {
        
        // Snapshot current cached data under lock for use as processor input
        dataLock.lock()
        let currentHydro = cachedHydroData
        let currentCompass = cachedCompassData
        let currentGPS = cachedGPSData
        let currentWind = cachedWindData
        let currentVMG = cachedVMGData
        dataLock.unlock()
        
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
            updatedHydroData = hydroProcessor.processSeaTemperature(splitStr)
            
            //MARK: - Wind Sensor Data
        case "MWV":
            updatedWindData = windProcessor.processWindSentence(
                splitStr,
                compassData: updatedCompassData ?? currentCompass,
                hydroData: updatedHydroData ?? currentHydro
            )
            
            //MARK: - Boat Speed & Distance Travelled from Lag
        case "VHW":
            updatedHydroData = hydroProcessor.processSpeedLog(splitStr)
            
        case "VLW":
            updatedHydroData = hydroProcessor.processDistanceTravelled(splitStr)
            
            //MARK: - GPS Sentences
        case "GLL":
            fallthrough
        case "GGA":
            fallthrough
        case "GSA":
            fallthrough
        case "GSV":
            fallthrough
        case "RMC":
            updatedGPSData = gpsProcessor.processRMC(splitStr)
            
        case "RMB":
            fallthrough
        case "VTG":
            fallthrough
        default:
            break
        }
        
        //MARK: - Update VMG Data
        let latestGPS = updatedGPSData ?? currentGPS
        let latestHydro = updatedHydroData ?? currentHydro
        let latestWind = updatedWindData ?? currentWind
        
        updatedVMGData = vmgProcessor.processVMGData(
            gpsData: latestGPS,
            hydroData: latestHydro,
            windData: latestWind
        )
        
        if updatedGPSData?.waypointLocation != nil {
            updatedWaypointData = waypointProcessor.processWaypointData(
                vmgData: updatedVMGData ?? currentVMG,
                gpsData: latestGPS,
                windData: latestWind
            )
        }
        
        // Buffer results under lock for the periodic UI update
        dataLock.lock()
        if let h = updatedHydroData { cachedHydroData = h }
        if let w = updatedWindData { cachedWindData = w }
        if let g = updatedGPSData { cachedGPSData = g }
        if let c = updatedCompassData { cachedCompassData = c }
        if let v = updatedVMGData { cachedVMGData = v }
        if let wp = updatedWaypointData { cachedWaypointData = wp }
        dataLock.unlock()

    }//END OF PARSE SENTENCE
    
    // MARK: - Waypoint Selection
    
    func selectWaypoint(at location: CLLocationCoordinate2D, name: String) {
        waypointProcessor.resetWaypointCalculations()
        gpsProcessor.updateMarker(to: location, name)
        
        dataLock.lock()
        if cachedGPSData == nil { cachedGPSData = GPSData() }
        cachedGPSData?.waypointLocation = location
        cachedGPSData?.waypointName = name
        cachedGPSData?.isTargetSelected = true
        dataLock.unlock()
        
        if gpsData == nil { gpsData = GPSData() }
        gpsData?.waypointLocation = location
        gpsData?.waypointName = name
        gpsData?.isTargetSelected = true
    }
    
    func deselectWaypoint() {
        waypointProcessor.resetWaypointCalculations()
        gpsProcessor.disableMarker()
        
        dataLock.lock()
        cachedGPSData?.waypointLocation = nil
        cachedGPSData?.waypointName = nil
        cachedGPSData?.isTargetSelected = false
        cachedWaypointData = nil
        dataLock.unlock()
        
        gpsData?.waypointLocation = nil
        gpsData?.waypointName = nil
        gpsData?.isTargetSelected = false
        waypointData = nil
    }
    
    // MARK: - Display Value Normalization (TODO: Refactor Later)
    func displayValue(a: Int) -> Double? {
        switch a {
        case 0: return hydroData?.depth
        case 1: return compassData?.normalizedHeading
        case 2: return hydroData?.seaWaterTemperature
        case 3: return hydroData?.boatSpeedLag
        case 4: return windData?.apparentWindAngle
        case 5: return windData?.apparentWindDirection
        case 6: return AppSettings.metricWind ? (windData?.apparentWindForce ?? 0) * toMetersPerSecond : windData?.apparentWindForce
        case 7: return windData?.trueWindAngle
        case 8: return windData?.trueWindDirection
        case 9: return AppSettings.metricWind ? (windData?.trueWindForce ?? 0) * toMetersPerSecond : windData?.trueWindForce
        case 10: return gpsData?.courseOverGround
        case 11: return gpsData?.speedOverGround
        default: return nil
        }
    }
}






