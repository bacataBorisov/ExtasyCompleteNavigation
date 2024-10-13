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
class NMEAReader: NSObject, GCDAsyncUdpSocketDelegate, GCDAsyncSocketDelegate {
    
    //MARK: - Handles the Socket Connection
    private var socket: GCDAsyncUdpSocket!
    var error : NSError?
    
    override init() {
        super.init()
        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: .global())
    }
    
    func start()  {
        do {
            try socket.bind(toPort: 4950)
            print("Connection established ...")
            try socket.beginReceiving()
        } catch  {
            print(error)
            socket.close()
        }
    }
    
    func stop() {
        socket.close()
    }
    
    //Calling the processNMEA here
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        
        DispatchQueue.main.async {
            
            if let receivedString = String(data: data, encoding: .utf8) {
                self.processRawString(rawData: receivedString)
            }
        }
    }
    
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        print("Connection Closed")
    }
    
    
    
    //MARK: - Handles the NMEA String Processing
    
    
    //MARK: - Variables that come from II - Integrated Instruments
    
    //Depth
    var depth: Double?
    var depthTriggerAlarm: Bool = false
    
    //Magnetic Compass
    var magneticArray = [Double()]
    var magneticHeading: Double?
    var magneticVariation: Double?
    var hdgForDisplayAndCalculation: Double?
    
    
    
    //Sea Water Temperature
    var seaWaterTemperature: Double?
    //Boat Speed Through Water
    var boatSpeedLag: Double?
    //Boat Distance Through Water
    var totalDistance: Double?
    var distSinceReset: Double?
    
    // Wind Data
    var trueWindArray = [Double]()
    var appWindArray = [Double]()
    
    var appWindAngle: Double?
    var awaForDisplayAndCalculation: Double?
    var appWindDirection: Double?
    var appWindForce: Double?
    
    var trueWindAngle: Double?
    var twaForDisplayAndCalculation: Double?
    var trueWindDirection: Double?
    var trueWindForce: Double?
    
    
    //MARK: - Variables that come from GP - external GPS
    
    //Boat's current coordinates
    var lat: Double?
    var lon: Double?
    
    var boatLocation: CLLocationCoordinate2D?
    var courseOverGround: Double?
    var speedOverGround: Double?
    var speedOverGroundKmh: Double?
    //these have to be displayed in settings
    var utcTime: String?
    var gpsDate: String?
    
    //MARK: - Mark Setup Variables
    var markerCoordinate: CLLocationCoordinate2D?
    
    var distance: Double?
    var estTimeOfArrival: Double?
    var markBearing: Double?
    var relativeMarkBearing = Double()
    var relativeMarkBearingArray = [Double]()
    var trueMarkBearing = Double()
    
    //VMG values
    //create instance and keep reference to VMGCalculator Class
    let calculateVMG = VMGCalculator()
    var polarSpeed: Double?
    var polarVMG: Double?
    var waypointVMC: Double?
    var distanceToNextTack: Double?
    var etaToNextTack: Double?
    var distanceToTheLongTack: Double?
    
    //Boolean values
    
    var isVMGSelected: Bool = false
    var isMetricSelected: Bool = false
    
    func processRawString(rawData: String){
        
        //Drop the dollar sign here, and then start processing the raw data
        let rawDataDropped = rawData.dropFirst(1)
        
        //MARK: - 1) Step of NMEA protocol - Calculate and Validate the Checksum
        let checksum: Bool = calcChecksum(String(rawDataDropped))
        
        if checksum {
            
            //MARK: - 2) Step of NMEA protocol - Check that All Received Chars are Valid
            let charValidated: Bool = validateChar(rawData)
            
            if charValidated {
                //split the String and return it in an array of elements that will be our values
                let splitStr: [String] = splitNMEAString(str: String(rawDataDropped))
                //print(splitStr)
                
                //MARK: - 3) Step of NMEA Protocol - Identify & Validate Talker ID - splitStr[0]
                
                let talkerID: Bool = validateTalkerID(splitStr[0])
                
                if talkerID {
                    //print without the trailing \n - just use empty string as terminator
                    //print("\(splitStr[0])->", terminator: "")
                    //print raw string after the talkerID
                    //print(rawData)
                    
                    //MARK: - 4) Step of NMEA Protocol - Identify & Validate Sentence Format - splitStr[1]
                    
                    let sentenceFormat: Bool = validateSentenceFormat(splitStr[1])
                    if sentenceFormat {
                        switch splitStr[1] {
                            
                            //MARK: - Depth
                        case "DPT":
                            //print(splitStr)
                            depth = Double(splitStr[2])
                            
                        case "HDG":
                            //MARK: - Magnetic Heading with Corrected Variation
                            
                            magneticHeading = Double(splitStr[2])
                            magneticVariation = Double(splitStr[5])
                            
                            if  let unwrappedHeading = magneticHeading,
                                let unwrappedVariation = magneticVariation {
                                
                                magneticHeading = correctedHeading(heading: unwrappedHeading, variation: unwrappedVariation, direction: splitStr[6])
                                
                                //Calculating shortest difference for the compass
                                
                                if let unwrappedHDG = magneticHeading {
                                    magneticArray.append(unwrappedHDG)
                                    
                                    if magneticArray.count > 1 {
                                        
                                        //prepare the two angles
                                        let sourceAngle = magneticArray[0]
                                        let targetAngle = magneticArray[1]
                                        
                                        //get all three different distances
                                        let alpha = targetAngle - sourceAngle
                                        let beta = targetAngle - sourceAngle + 360
                                        let gamma = targetAngle - sourceAngle - 360
                                        //get the lowest value by absolute
                                        var A = min(abs(alpha), abs(beta), abs(gamma))
                                        //get the proper sign - plus or minus
                                        switch A {
                                        case abs(alpha):
                                            A = alpha
                                        case abs(beta):
                                            A = beta
                                        default:
                                            A = gamma
                                        }
                                        
                                        let newAngle = sourceAngle + A
                                        //print("heading - new: \(newAngle)")
                                        //add it to the source angle
                                        magneticHeading = newAngle
                                        //copy the source angle and prepare it for the next computation
                                        magneticArray[0] = sourceAngle + A
                                        //remove the last element of the array
                                        magneticArray.remove(at: 1)
                                        
                                        //function to normalize the angle for display and other calculations
                                        hdgForDisplayAndCalculation = normaliseAngle(unwrappedHDG)
                                    }
                                }
                                
                            }

                            //MARK: - Water Temperature
                        case "MTW":
                            //for the moment we don't have temperature sensor. I am not sure where exactly has been installed - probably in the speed log? Looks like our is not connected because we get an empty string when it has been returned. If we get a new speed log with temperature sensor we can use it. For the moment it will be skipped or just get "--"
                            
                            self.seaWaterTemperature = Double(splitStr[2])
                            
                            //MARK: - Wind Sensor Data
                        case "MWV":
                            //check if the string is valid
                            if splitStr[6] == "A" {
                                //print(splitStr)
                                
                                //string is for AWD & AWS
                                //MARK: - Wind Calculations
                                if splitStr[3] == "R" {
                                    
                                    self.appWindForce = Double(splitStr[4])
                                    
                                    appWindArray.append(Double(splitStr[2]) ?? 0)
                                    
                                    if appWindArray.count > 1 {
                                        
                                        //prepare the two angles
                                        let sourceAngle = appWindArray[0]
                                        let targetAngle = appWindArray[1]
                                        
                                        //get all three different distances
                                        let alpha = targetAngle - sourceAngle
                                        let beta = targetAngle - sourceAngle + 360
                                        let gamma = targetAngle - sourceAngle - 360
                                        //get the lowest value by absolute
                                        var A = min(abs(alpha), abs(beta), abs(gamma))
                                        //get the proper sign - plus or minus
                                        switch A {
                                        case abs(alpha):
                                            A = alpha
                                        case abs(beta):
                                            A = beta
                                        default:
                                            A = gamma
                                        }
                                        
                                        //print(windArray)
                                        //print("shortest diff is: \(A)")
                                        
                                        let newAngle = sourceAngle + A
                                        //add it to the source angle
                                        appWindAngle = newAngle
                                        //copy the source angle and prepare it for the next computation
                                        appWindArray[0] = sourceAngle + A
                                        //remove the last element of the array
                                        appWindArray.remove(at: 1)
                                        
                                        
                                        //function to normalize the angle for display and other calculations
                                        if let unwrappedAWA = appWindAngle {
                                            
                                            awaForDisplayAndCalculation = normaliseAngle(unwrappedAWA)
                                            
                                            if let calculationAWA = awaForDisplayAndCalculation,
                                               let unwrappedAWF = appWindForce,
                                               let unwrappedHDG = hdgForDisplayAndCalculation {
                                                
                                                //calculate AWD
                                                appWindDirection = windDirCalc(unwrappedAWF, calculationAWA, unwrappedHDG)
                                            }
                                            
                                        } else {
                                            awaForDisplayAndCalculation = nil
                                        }
                                    }
                                } else {
                                    
                                    
                                    //MARK: - Calculated True Wind using only AWA, AWS, HDG & BSPD
                                    /*It can be used in case there is no data from the anemometer for the True Wind Direction*/
                                    
                                    //self.trueWindForce = trueWindForceConvert(windAngle: appWindAngle, appWindForce: appWindForce, heading: courseOverGround, boatSpeed: speedOverGround)
                                    //
                                    //self.trueWindAngle = trueWindAngleConvert(appWindAngle: self.appWindAngle, trueWindForce: trueWindForce, appWindForce: appWindForce, courseOverGround: courseOverGround, boatSpeedSOG: speedOverGround)
                                    
                                    //print("AWA is: \(appWindAngle)")
                                    //print("TWA BEFORE APPENDING IN THE ARRAY: \(self.trueWindAngle)")
                                    
                                    //MARK: - True Wind Take Directly from the Sensor - every second wind string is TW data - Angle and Force
                                    self.trueWindForce = Double(splitStr[4])
                                    //relative to the bow
                                    self.trueWindAngle = Double(splitStr[2])
                                    //array helps us to overcome the 360 wrapping problem
                                    trueWindArray.append(Double(splitStr[2]) ?? 0)
                                    
                                    if trueWindArray.count > 1 {
                                        
                                        //prepare the two angles
                                        let sourceAngle = trueWindArray[0]
                                        let targetAngle = trueWindArray[1]
                                        
                                        //get all three different distances
                                        let alpha = targetAngle - sourceAngle
                                        let beta = targetAngle - sourceAngle + 360
                                        let gamma = targetAngle - sourceAngle - 360
                                        //get the lowest value by absolute
                                        var A = min(abs(alpha), abs(beta), abs(gamma))
                                        //get the proper sign - plus or minus
                                        switch A {
                                        case abs(alpha):
                                            A = alpha
                                        case abs(beta):
                                            A = beta
                                        default:
                                            A = gamma
                                        }
                                        
                                        //print(windArray)
                                        //print("shortest diff is: \(A)")
                                        
                                        let newAngle = sourceAngle + A
                                        //add it to the source angle
                                        trueWindAngle = newAngle
                                        //copy the source angle and prepare it for the next computation
                                        trueWindArray[0] = sourceAngle + A
                                        //remove the last element of the array
                                        trueWindArray.remove(at: 1)
                                        
                                        //function to normalize the angle for display and other calculations
                                        if let unwrappedTWA = trueWindAngle {
                                            twaForDisplayAndCalculation = normaliseAngle(unwrappedTWA)
                                            
                                            if let calculationTWA = twaForDisplayAndCalculation,
                                               let unwrappedTWF = trueWindForce,
                                               let unwrappedHDG = hdgForDisplayAndCalculation {
                                                
                                                //calculate AWD
                                                trueWindDirection = windDirCalc(unwrappedTWF, calculationTWA, unwrappedHDG)
                                                
                                                //Calculate speed and VMG directly upwind or downwind as per the polar diagram
                                                
                                                polarSpeed = calculateVMG.evaluate_diagram(windForce: unwrappedTWF, windAngle: unwrappedTWA)
                                                //print("polarSpeed is: \(String(describing: polarSpeed))")
                                                if let unwrappedPolarSpeed = polarSpeed {
                                                    polarVMG = unwrappedPolarSpeed * cos(toRadians(unwrappedTWA))
                                                    
                                                }
                                            }
                                        }
                                        
                                    } else {
                                        awaForDisplayAndCalculation = nil
                                    }
                                    
                                }
                                
                            } else {
                                //string is not valid
                                fallthrough
                            }

                            //MARK: - Boat Speed & Distance Travelled from Lag
                        case "VHW":
                            
                            self.boatSpeedLag = Double(splitStr[6])
                            
                            //Distance travelled through water in nautical miles
                        case "VLW":
                            self.totalDistance = Double(splitStr[2])
                            self.distSinceReset = Double(splitStr[4])
                            
                            //MARK: - GPS Sentences
                            /* This will not make difference between different GPS sentences. I am not sure yet, how to handle that.
                             Does it make any difference? Probably. I need to find a way do distinguish a way of differentiating between differetn GPSs - maybe in the later upgrades */
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
                            //print only the string that contains the following value
                            
                            //print(splitStr)
                            //check if the string is valid
                            if splitStr[3] == "A"{
                                
                                //Time - UTC - hhmmss - to be written user friendly
                                self.utcTime = splitStr[2]
                                
                                //coordinates converted to CLLDegrees
                                lat = toCLLDegreesLat(value: splitStr[4], direction: splitStr[5])
                                lon = toCLLDegreesLon(value: splitStr[6], direction: splitStr[7])
                                
                                if let unwrappedLat = lat, let unwrappedLon = lon {
                                    boatLocation = CLLocationCoordinate2D(latitude: unwrappedLat, longitude: unwrappedLon)
                                }
                                
                                //MARK: - Date - format ddmmyy - write it user friendly
                                
                                gpsDate = splitStr[10]
                                
                                //COG - Course Over Ground
                                courseOverGround = Double(splitStr[9])
                                
                                //SOG - Speed Over Ground in knots
                                speedOverGround = Double(splitStr[8])
                                
                                //MARK: - Waypoint VMG Calculation Data
                                //Calculating bearing to the waypoint
                                if isVMGSelected {
                                    
                                    if let unwrappedMarkerCoordinate = markerCoordinate {
                                        //calculate bearing to the mark
                                        //markBearing = calculateBearingToLocation(unwrappedMarkerCoordinate)
                                        
                                        
                                        if let unwrappedLat = boatLocation?.latitude,
                                           let unwrappedLon = boatLocation?.longitude,
                                           let unwrappedBoatLocation = boatLocation {
                                            let locationA = CLLocation(latitude: unwrappedLat, longitude: unwrappedLon)
                                            let locationB = CLLocation(latitude: unwrappedMarkerCoordinate.latitude, longitude: unwrappedMarkerCoordinate.longitude)
                                            
                                            //calculate distance to the mark - in meters
                                            distance = locationA.distance(from: locationB)
                                            
                                            trueMarkBearing = calcOffset(unwrappedBoatLocation, unwrappedMarkerCoordinate).1
                                            print("BEARING TO THE MARK IS: \(String(describing: trueMarkBearing))")
                                            
                                            
                                        }
                                        if  let unwrappedDistance = distance,
                                            //let unwrappedMarkBearing = trueMarkBearing,
                                            let unwrappedCOG = courseOverGround {
                                            
                                            //calculate distance to the next tack
                                            relativeMarkBearing = trueMarkBearing - unwrappedCOG
                                            
                                            if relativeMarkBearing < 0 {
                                                relativeMarkBearing = relativeMarkBearing * (-1)
                                                
                                                if relativeMarkBearing >= 180 {
                                                    relativeMarkBearing = 360 - relativeMarkBearing
                                                }
                                            }
                                            
                                            
                                            //used for the UltimateDisplay rotation
                                            relativeMarkBearing = normaliseAngle(relativeMarkBearing)
                                            
                                            relativeMarkBearingArray.append(relativeMarkBearing)
                                            
                                            if relativeMarkBearingArray.count > 1 {
                                                
                                                //prepare the two angles
                                                let sourceAngle = relativeMarkBearingArray[0]
                                                let targetAngle = relativeMarkBearingArray[1]
                                                
                                                //get all three different distances
                                                let alpha = targetAngle - sourceAngle
                                                let beta = targetAngle - sourceAngle + 360
                                                let gamma = targetAngle - sourceAngle - 360
                                                //get the lowest value by absolute
                                                var A = min(abs(alpha), abs(beta), abs(gamma))
                                                //get the proper sign - plus or minus
                                                switch A {
                                                case abs(alpha):
                                                    A = alpha
                                                case abs(beta):
                                                    A = beta
                                                default:
                                                    A = gamma
                                                }
                                                
                                                //print(windArray)
                                                //print("shortest diff is: \(A)")
                                                
                                                let newAngle = sourceAngle + A
                                                //add it to the source angle
                                                relativeMarkBearing = newAngle
                                                //copy the source angle and prepare it for the next computation
                                                relativeMarkBearingArray[0] = sourceAngle + A
                                                //remove the last element of the array
                                                relativeMarkBearingArray.remove(at: 1)
                                            }
                                            
                                            
                                            //used for display in the VMG View
                                            trueMarkBearing = normaliseAngle(trueMarkBearing)
                                            
                                            
                                            //Calculations for the next Tack
                                            relativeMarkBearing = normaliseAngle(relativeMarkBearing)
                                            
                                            distanceToNextTack = cos(toRadians(relativeMarkBearing)) * unwrappedDistance
                                            distanceToTheLongTack = cos(toRadians(90 - relativeMarkBearing)) * unwrappedDistance
                                            
                                        }
                                    }
                                    if //let unwrappedMarkBearing = markBearing,
                                        var unwrappedCOG = courseOverGround,
                                        let unwrappedSOG = speedOverGround {
                                        
                                        unwrappedCOG = normaliseAngle(unwrappedCOG)
                                        //calculate VMG to a Waypoint - This needs to be discussed with Ivan and get the talk for the vectors
                                        waypointVMC = vmg(speed: unwrappedSOG, target_angle: trueMarkBearing, boat_angle: unwrappedCOG)
                                    }
                                    
                                    
                                } else {
                                    //set them to nil, so once the target is cancelled I don't get them in the display cells
                                    distance = nil
                                    markBearing = nil
                                    waypointVMC = nil
                                    markerCoordinate = nil
                                }
                                
                            } else {
                                fallthrough
                            }
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
                    } else {
                        print("Invalid sentence format: [\(splitStr[1])]")
                    }
                    
                } else {
                    //unknown talkerID, print it
                    print("Uknown NMEA talkerID: [\(splitStr[0])]")
                }
            } else {
                print("Error: Invalid Character! in string -> \(rawData)")
            }
            
        } else {
            //if checksum compatison fails return back
            //print(checksum)
            print("Checksum failed!")
        }
    }
    
    //MARK: - Functions
    
    //MARK: - Unwrapping Function
    func unwrap(_ string: String?) -> String {
        
        if string != "" {
            return string!
        } else {
            return "--"
        }
    }
    
    //MARK: - NMEA Calculating Checksum Function
    func calcChecksum(_ str: String) -> Bool {
        
        var checksumReversed: String = ""
        //reverse the string the get the checksum
        var checksum = String(str.reversed())
        
        //get the chars until the asterisk
        for i in checksum {
            if i != "*"{
                checksumReversed.append(i)
            } else {
                //reverse it back to normal state
                checksum = String(checksumReversed.reversed())
            }
        }
        
        //remove the /n - new line at the end of the string
        checksum = checksum.components(separatedBy: .newlines).joined()
        // strip the string to get the chars between $ and *
        var strippedStr: String = ""
        var potentialSum = 0
        
        for i in str {
            if i != "*" {
                strippedStr.append(i)
            } else {
                break
            }
        }
        //convert the string to a byte array for every single char
        let byteString: [UInt16] = Array(strippedStr.utf16)
        //type of checksum used in NMEA is XOR
        //loop through the byte array and apply bitwise ^ XOR checksum
        
        for i in byteString {
            potentialSum = potentialSum ^ Int(i)
        }
        //convert to hex with 0 always in front
        //let potentialSumHex = String(potentialSum, radix: 16).uppercased()
        let potentialSumHex = String(format:"%02X", potentialSum)
        
        //compare & return result
        //print(potentialSumHex)
        return (checksum == potentialSumHex ? true : false)
    }
    //MARK: - Validate Received String Chars
    func validateChar(_ str: String) -> Bool {
        
        for char in str {
            let charDecimal = char.asciiValue
            if let charDecimalSafe = charDecimal {
                if charDecimalSafe < 32 && charDecimalSafe > 127 {
                    return false
                }
            } else {
                return false
            }
        }
        return true
    }
    //MARK: - Validate TalkerID Function
    func validateTalkerID(_ str: String) -> Bool {
        
        //all talker IDs taken from the official NMEA 0183 protocol v. 3.01
        let allTalkerID: [String] = [
            "AG", "AP", "AI",
            "CD", "CR", "CS", "CT", "CV", "CX",
            "DE", "DF",
            "EC", "EI", "EP", "ER",
            "GL", "GN", "GP",
            "HC", "HE", "HN",
            "II", "IN",
            "LC",
            "P",
            "RA",
            "SD", "SN", "SS",
            "TI",
            "VD", "VM", "VW", "VR",
            "YX",
            "ZA", "ZC", "ZQ", "ZV", "WI"
        ]
        
        let result = allTalkerID.contains(str)
        return result
    }
    
    //MARK: - Validate Sentence Format
    func validateSentenceFormat(_ str: String) -> Bool {
        
        //all sentence formats taken from the official NMEA 0183 protocol v. 3.01 - p. 23
        let allSentenceFormat = [
            "AAM", "ABK", "ACA", "ACK", "AIR", "ALM", "ALR", "APB",
            "BEC", "BOD", "BWC", "BWR", "BWW",
            "CUR",
            "DBT", "DCN", "DPT", "DSC", "DSE", "DSI", "DSR", "DTM",
            "FSI",
            "GBS", "GGA", "GLC", "GLL", "GMP", "GNS", "GRS", "GSA", "GST", "GSV",
            "HDG", "HDT", "HMR", "HMS", "HSC", "HTC", "HTD", "LCD", "LRF", "LRI", "LR1", "LR2", "LR3",
            "MLA", "MSK", "MSS", "MTW", "MWD", "MWV",
            "OSD",
            "RMA", "RMB", "RMC", "ROT", "RPM", "RSA", "RSD", "RTE",
            "SFI", "SSD", "STN",
            "TLB", "TLL", "TTM", "TUT", "TXT",
            "VBW", "VDR", "VHW", "VLW", "VPW", "VSD", "VTG",
            "WCV", "WNC", "WPL",
            "XDR", "XTE", "XTR",
            "ZDA", "ZDL", "ZFO", "ZTF",
            //Encapsulation Formatters
            "ABM", "BBM", "VDM", "VDO"
        ]
        
        let result = allSentenceFormat.contains(str)
        return result
    }
    
    //MARK: - Split Raw Data Function
    func splitNMEAString(str: String) -> [String] {
        
        //initialize an empty string that will be returned at the end of the function
        var splittedStr = [String]()
        
        //move first two letters for talker identifiers
        let index = str.index(str.startIndex, offsetBy: 2)
        let talkerID = str.prefix(upTo: index)
        //talkerID is of type String.SubSequence and needs to be converted back to String
        //insert it at 0 index position and remove the initialization ""
        splittedStr.append(String(talkerID))
        //get the string without the talkerID
        let nextStr = String(str[index...])
        //split the string until the asterisk and move the elements into an array
        var lastStr =  nextStr.components(separatedBy: [",", "*"])
        //remove the last element which is the checksum
        lastStr.removeLast()
        //combine it with the sentence heading
        splittedStr.append(contentsOf: lastStr)
        
        return splittedStr
    }
    
    //MARK: - Corrected Heading with Variation
    func correctedHeading(heading: Double, variation: Double,direction: String ) -> Double
    {
        
        //we are getting TRUE heading when adding or subtracting to the magnetic heading - it should in theory be the same as COG
        
        if direction == "E"{
            
            return (heading + variation)
            
        } else {
            
            return (heading - variation)
        }
        
    }
    
    
    //MARK: - Coordinates Conversion
    //The format for NMEA coordinates is (d)ddmm.mmmm
    //d=degrees and m=minutes
    //There are 60 minutes in a degree so divide the minutes by 60 and add that to the degrees.
    func toCLLDegreesLat(value: String, direction: String) -> Double? {
        
        //print("PRINTING FROM COORDINATES LAT FUNCTION")
        //print("string: \(value), direction: \(direction)")
        
        if let deg = (Double(value.dropLast(7))), var min = (Double(value.dropFirst(2))) {
            min /= 60
            //print("minutes: \(min)")
            let latitude = deg + min
            
            //print("final latitute: \(latitude)")
            return (direction == "N" ? latitude : -latitude)
        }
        return nil
    }
    
    func toCLLDegreesLon(value: String, direction: String) -> Double? {
        
        //print("PRINTING FROM COORDINATES LON FUNCTION")
        //print("string: \(value), direction: \(direction)")
        
        if let deg = (Double(value.dropLast(7))), var min = (Double(value.dropFirst(3))) {
            
            min /= 60
            let longtitude = deg + min
            //print("final latitute: \(longtitude)")
            
            return (direction == "E" ? longtitude : -longtitude)
        }
        
        return nil
    }
    
    //MARK: - True Wind Calculations
    func trueWindForceConvert(windAngle: Double,appWindForce: Double, heading: Double, boatSpeed: Double) -> Double {

        if boatSpeed > 0 {
            let tws = sqrt(pow(boatSpeed, 2) + pow(appWindForce, 2) - (2 * boatSpeed * appWindForce * cos(toRadians(windAngle))))
            return tws
            
        } else {
            //if the boat speed is ZERO TWF = AWF
            return appWindForce
        }
    }
    
    //MARK: - Bearing & Distance to Mark Function
    func calculateBearingToLocation(_ destinationLocation:CLLocationCoordinate2D) -> Double? {
        
        //locations coordinates that is moving
        if let unwrappedLat = boatLocation?.latitude, let unwrappedLon = boatLocation?.longitude {
            let lat1 = toRadians(unwrappedLat)
            let lon1 = toRadians(unwrappedLon)
            
            let lat2 = toRadians(destinationLocation.latitude)
            let lon2 = toRadians(destinationLocation.longitude)
            
            //        print("location2: \(lat2), \(lon2)")
            //        print("lat2: \(destinationLocation.coordinate.latitude)")
            //        print("lon2: \(destinationLocation.coordinate.longitude)")
            
            let dLon = lon2 - lon1
            
            let y = sin(dLon) * cos(lat2);
            let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
            let radiansBearing = atan2(y, x)
            
            //        print(radiansBearing)
            
            var degreesBearing = toDegrees(radiansBearing)
            //        print(degreesBearing)
            
            
            //wrap around for the negative values
            if degreesBearing < 0 {
                degreesBearing += 360
                return degreesBearing
            } else {
                return degreesBearing
            }
        }
        
        //        print("lat1: \(self.navigationReadings.boatLocation.latitude)")
        //        print("lon1: \(self.navigationReadings.boatLocation.longitude)")
        //        print("location1: \(lat1), \(lon1)")
        
        return nil
    }
    
    //MARK: - Another Function for Calculation (better accuracy)
    //hasn't been tested yet - to be confirmed
    
    
    
    func calcOffset(_ coord0: CLLocationCoordinate2D,
                    _ coord1: CLLocationCoordinate2D) -> (Double, Double) {
        
        let earthRadius: Double = 6372456.7
        let degToRad: Double = .pi / 180.0
        let radToDeg: Double = 180.0 / .pi
        
        
        let lat0: Double = coord0.latitude * degToRad
        let lat1: Double = coord1.latitude * degToRad
        let lon0: Double = coord0.longitude * degToRad
        let lon1: Double = coord1.longitude * degToRad
        let dLat: Double = lat1 - lat0
        let dLon: Double = lon1 - lon0
        let y: Double = cos(lat1) * sin(dLon)
        let x: Double = cos(lat0) * sin(lat1) - sin(lat0) * cos(lat1) * cos(dLon)
        let t: Double = atan2(y, x)
        let bearing: Double = t * radToDeg
        
        let a: Double = pow(sin(dLat * 0.5), 2.0) + cos(lat0) * cos(lat1) * pow(sin(dLon * 0.5), 2.0)
        let c: Double = 2.0 * atan2(sqrt(a), sqrt(1.0 - a));
        let distance: Double = c * earthRadius
        
        return (distance, bearing)
    }
    
    func trueWindAngleConvert(appWindAngle: Double, trueWindForce: Double,appWindForce: Double, courseOverGround: Double, boatSpeedSOG: Double) -> Double {
        
        var appConverted = Double()
        
        
        //if the boat speed is ZERO TWA = AWA
        if boatSpeedSOG == 0 {
            return appWindAngle
        }
        
        let u = (pow(appWindForce, 2) - pow(trueWindForce, 2) - pow(boatSpeedSOG, 2))
        let v = 2 * trueWindForce * boatSpeedSOG
        
        let beta = u/v
        
        //because of rounding precision acos returns NaN if the angle is very close to 180 degrees.
        //this will make sure that acos is within [-1, 1] limits
        let twa = acos(min(max(beta, -1.0), 1.0))
        let twaDegrees = toDegrees(twa)
        
        
        //MARK: - Side Note on the Wind Values
        //Because of the arccos function which is always positive, depending on the different values
        //of the apparent wind the true wind will be returned with different sign
        
        
        //wrap around the apparent wind
        if appWindAngle > 360 {
            appConverted = appWindAngle.truncatingRemainder(dividingBy: 360)
            //apparent wind is in the PORT side part of the anemometer
        } else if appWindAngle >= 180 && appWindAngle < 360 {
            appConverted = appWindAngle
            //apparent wind is negative - convert it to positive
        } else if appWindAngle < 0{
            //print("NEGATIVE AWA BEFORE CONVERSION: \(appWindAngle)")
            appConverted = appWindAngle + 360
            //print("NEGATIVE AWA AFTER CONVERSION: \(appConverted)")
            //everything else and when it is higher than -360
        } else {
            appConverted = appWindAngle.truncatingRemainder(dividingBy: 360)
            appConverted += 360
        }
        
        
        //if the appwind is PORT side return negative TWA
        if appConverted >= 180 && appConverted < 360 {
            
            return -twaDegrees
            //if it is in the STBD side return positive TWA
        } else {
            
            return twaDegrees
        }
    }
    
    //MARK: - Assisting / Tool Functions
    func normaliseAngle(_ angle: Double) -> Double {
        
        var normalisedAngle = Double()
        
        if angle >= 360 {
            
            normalisedAngle = angle.truncatingRemainder(dividingBy: 360)
            
            return normalisedAngle
            
        } else if angle < 0 {
            
            normalisedAngle = angle.truncatingRemainder(dividingBy: 360)
            normalisedAngle += 360
            
            return normalisedAngle
            
        } else {
            return angle
        }
    }
    
    //Function to normalize values for display
    func displayValue(a: Int) -> Double? {
        
        switch a {
        case 0:
            return depth
        case 1:
            return hdgForDisplayAndCalculation
        case 2:
            return seaWaterTemperature
        case 3:
            return boatSpeedLag
        case 4:
            return awaForDisplayAndCalculation
        case 5:
            return appWindDirection
        case 6:
            if isMetricSelected {
                if let unwrappedAWF = appWindForce {
                    return unwrappedAWF*toMetersPerSecond
                }
            } else {
                return appWindForce
            }
            
        case 7:
            return twaForDisplayAndCalculation
        case 8:
            return trueWindDirection
        case 9:
            if isMetricSelected {
                if let unwrappedTWF = trueWindForce {
                    return unwrappedTWF*toMetersPerSecond
                }
            } else {
                return trueWindForce
            }
        case 10:
            return courseOverGround
        case 11:
            return speedOverGround
        case 12:
            return polarSpeed
        case 13:
            return waypointVMC
        case 14:
            return polarVMG
        case 15:
            return trueMarkBearing
        case 16:
            if let unwrappedDistance = distance {
                return unwrappedDistance
            }
        case 17:
            if let unwrappedDistance = distance, let speed = speedOverGround {
                
                return unwrappedDistance / speed
            }
        case 18:
            if let unwrappedTackDistance = distanceToNextTack, let speed = speedOverGround {
                
                return unwrappedTackDistance / speed
            }
        default:
            return nil
        }
        return nil
    }//END OF displayValue function
    
    func windDirCalc(_ force: Double, _ wind: Double, _ heading: Double) -> Double {
        
        //if there is no wind, return 0 and don't calculate wind direction
        //accuracy to be adjusted if necessary
        if force < 0.001 {
            return 0
        } else {
            
            var windCalc = wind
            var headingCalc = heading
            
            //print("values before conversion: wind -> \(windCalc), heading -> \(headingCalc)")
            
            //prepare the angles for calculation
            if windCalc < 0 {
                windCalc += 360
            } else {
                windCalc = windCalc.truncatingRemainder(dividingBy: 360)
            }
            
            if headingCalc < 0 {
                headingCalc += 360
            } else {
                headingCalc = headingCalc.truncatingRemainder(dividingBy: 360)
            }
            
            let direction = (windCalc + headingCalc).truncatingRemainder(dividingBy: 360)
            
            //print("TWD = \(direction) + TWA: [\(windCalc)] + COG: [\(headingCalc)] ")
            
            return direction
        }
    }
}






