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
    
    
    //MARK: - Variables that come from II - Integrated Instruments
    
    //HydroData Variables (speed log, depth, sea water temperature, etc.)
    let hydroProcessor = HydroProcessor()
    var hydroData: HydroData?
    
    //CompassData Variables
    let compassProcessor = CompassProcessor()
    var compassData: CompassData?
    
    // Wind Data Variables
    let windProcessor = WindProcessor()
    var windData: WindData?
    
    //MARK: - Variables that come from GP - external GPS
    
    let gpsProcessor = GPSProcessor()
    var gpsData: GPSData?
    
    //MARK: - Mark Setup Variables & VMG
    
    //MARK: - Ignore Observation here - VMGViewModel will take care of publishing vmgData properties
    @ObservationIgnored
    let vmgProcessor = VMGProcessor()
    
    // Expose VMG data directly
    @ObservationIgnored
    var vmgData: VMGData {
        vmgProcessor.vmgData
    }
    
    // Expose the relativeMarkBearing property from vmgData
    var relativeMarkBearing: Double {
        get { vmgProcessor.vmgData.relativeMarkBearing }
        set { vmgProcessor.vmgData.relativeMarkBearing = newValue }
    }
    
    var isVMGSelected: Bool = false {
        didSet {
            print("isVMGSelected updated to \(isVMGSelected)")
        }
    }
    //Boolean values
    
    var isMetricSelected: Bool = false
    
    //Watchdog variables
    private var lastWindUpdateTime: Date?
    private var dataTimeout: TimeInterval = 30 // Timeout in seconds
    
    
    //MARK: - Watchod Logic and Mechanism
    /**
     By calling it inside the init method, you ensure that the monitoring process starts as soon as the NMEAParser instance is created.
     This avoids relying on other parts of the code to remember to explicitly call this function after initialization.
     */
    override init() {
        super.init()
        startDataWatchdog()
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
        
        //Check first sign of the string
        guard rawData.first == "$" else {
            print("Invalid NMEA String Format")
            return
        }
        
        //Drop the dollar sign here, and then start processing the raw data
        let strippedData = String(rawData.dropFirst())
        
        print(rawData)
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
        
        
        //MARK: - Update VMG Data
        // **Call processVMGData after relevant updates**
        if isVMGSelected {
            vmgProcessor.processVMGData(
                gpsData: gpsData,
                markerCoordinate: vmgData.markerCoordinate,
                windData: windData,
                isVMGSelected: isVMGSelected
            )
        }
        
    }//END OF PROCESS RAW STRING
    
    //MARK: - Functions
    
    private func parseSentence(_ format: String, _ splitStr: [String]) {
        
        switch format {
            
            //MARK: - Depth
        case "DPT":
            hydroProcessor.processDepth(splitStr)
            hydroData = hydroProcessor.hydroData
            
        case "HDG":
            //MARK: - Magnetic Heading with Corrected Variation
            compassData = compassProcessor.processCompassSentence(splitStr)
            
            //MARK: - Water Temperature
        case "MTW":
            //for the moment we don't have temperature sensor. I am not sure where exactly has been installed - probably in the speed log? Looks like our is not connected because we get an empty string when it has been returned. If we get a new speed log with temperature sensor we can use it. For the moment it will be skipped or just get "--"
            hydroProcessor.processSeaTemperature(splitStr)
            hydroData = hydroProcessor.hydroData
            
            //MARK: - Wind Sensor Data
        case "MWV":
            
            // Process the wind sentence using the WindProcessor
            if let updatedWindData = windProcessor.processWindSentence(splitStr) {
                // Update the current wind data
                self.windData = updatedWindData
                
                // Record the time of the last valid wind data update
                lastWindUpdateTime = updatedWindData.lastUpdated
            } else {
                // Handle invalid or missing wind data if necessary
                print("Invalid or incomplete MWV sentence.")
            }
            
            //MARK: - Boat Speed & Distance Travelled from Lag
        case "VHW":
            
            hydroProcessor.processSpeedLog(splitStr)
            hydroData = hydroProcessor.hydroData
            
            //Distance travelled through water in nautical miles
        case "VLW":
            
            hydroProcessor.processDistanceTravelled(splitStr)
            hydroData = hydroProcessor.hydroData
            
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
            
            gpsProcessor.processRMC(splitStr)
            gpsData = gpsProcessor.gpsData
            
            
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
    }//END OF PARSE SENTENCE
    
    //MARK: - Helper Functions to Trigger VMG Calculations
    // Synchronize VMGProcessor updates with the NMEAParser's `vmgData`
    // Example of triggering VMG updates
//    func processVMGData() {
//        vmgProcessor.processVMGData(
//            gpsData: gpsData,
//            markerCoordinate: vmgData?.markerCoordinate, // Use the NMEAParser's vmgData
//            windData: windData,
//            isVMGSelected: isVMGSelected
//        )
//        updateVMGData() // Sync updated data to the `NMEAParser` level
//    }
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
            if isMetricSelected {
                if let unwrappedAWF = windData?.apparentWindForce {
                    return unwrappedAWF*toMetersPerSecond
                }
            } else {
                return windData?.apparentWindForce
            }
        case 7:
            return windData?.trueWindAngle
        case 8:
            return windData?.trueWindDirection
        case 9:
            if isMetricSelected {
                if let unwrappedTWF = windData?.trueWindForce {
                    return unwrappedTWF*toMetersPerSecond
                }
            } else {
                return windData?.trueWindForce
            }
        case 10:
            return gpsData?.courseOverGround
        case 11:
            return gpsData?.speedOverGround
        case 12:
            return vmgData.polarSpeed
        case 13:
            return vmgData.waypointVMC
        case 14:
            return vmgData.polarVMG
        case 15:
            return vmgData.trueMarkBearing
        case 16:
            return vmgData.distanceToMark
        case 17:
            if let unwrappedDistance = vmgData.distanceToMark, let speed = gpsData?.speedOverGround {
                
                return unwrappedDistance / speed
            }
        case 18:
            if let unwrappedTackDistance = vmgData.distanceToNextTack, let speed = gpsData?.speedOverGround {
                
                return unwrappedTackDistance / speed
            }
            
        case 19:
            return vmgData.relativeMarkBearing
        default:
            return nil
        }
        return nil
    }//END OF displayValue function
}






