//
//  GPSProcessor.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 21.11.24.
//
//  For the moment I rely on one source of GPS - it is external one, since the one integrated with B&N 'II'
//  does not work.
//  In case we fix it I need to fix the code and decide how to proceed - choose one at a time or average for both
//  for better accuracy
//  To be decided later on
//

class GPSProcessor {
    private(set) var gpsData = GPSData()

    func processGLL(_ splitStr: [String]) {
        guard splitStr.count >= 6 else {
            print("Invalid GLL Sentence!")
            return
        }
        gpsData.latitude = toCLLDegreesLat(value: splitStr[2], direction: splitStr[3])
        gpsData.longitude = toCLLDegreesLon(value: splitStr[4], direction: splitStr[5])
    }

    func processRMC(_ splitStr: [String]) {
        guard splitStr.count >= 11, splitStr[3] == "A" else {
            print("Invalid RMC Sentence!")
            return
        }
        gpsData.utcTime = splitStr[2]
        gpsData.latitude = toCLLDegreesLat(value: splitStr[4], direction: splitStr[5])
        gpsData.longitude = toCLLDegreesLon(value: splitStr[6], direction: splitStr[7])
        gpsData.courseOverGround = Double(splitStr[9])
        gpsData.speedOverGround = Double(splitStr[8])
        gpsData.gpsDate = splitStr[10]
        if let sog = gpsData.speedOverGround {
            gpsData.speedOverGroundKmh = sog * 1.852 // Convert knots to km/h
        }
    }

    func processGGA(_ splitStr: [String]) {
        guard splitStr.count >= 7 else {
            print("Invalid GGA Sentence!")
            return
        }
        gpsData.latitude = toCLLDegreesLat(value: splitStr[2], direction: splitStr[3])
        gpsData.longitude = toCLLDegreesLon(value: splitStr[4], direction: splitStr[5])
        // Other GGA-specific processing can be added here
    }

    func resetGPSData() {
        gpsData.reset()
    }
    
    //MARK: - Coordinates Conversion
    
    /*Better and more generalized function to convert coordinates into decimal*/
    //MARK: - Generalized Coordinates Conversion
    /// Converts NMEA coordinate format `(d)ddmm.mmmm` into decimal degrees.
    ///
    /// - Parameters:
    ///   - value: The coordinate value as a string.
    ///   - direction: The direction as a string (`N`, `S`, `E`, `W`).
    /// - Returns: The converted decimal degrees or `nil` if input is invalid.
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
    
    
    //The format for NMEA coordinates is (d)ddmm.mmmm
    //d=degrees and m=minutes
    //There are 60 minutes in a degree so divide the minutes by 60 and add that to the degrees.
//    func toCLLDegreesLat(value: String, direction: String) -> Double? {
//        
//        //print("PRINTING FROM COORDINATES LAT FUNCTION")
//        //print("string: \(value), direction: \(direction)")
//        
//        if let deg = (Double(value.dropLast(7))), var min = (Double(value.dropFirst(2))) {
//            min /= 60
//            //print("minutes: \(min)")
//            let latitude = deg + min
//            
//            //print("final latitute: \(latitude)")
//            return (direction == "N" ? latitude : -latitude)
//        }
//        return nil
//    }
//    
//    func toCLLDegreesLon(value: String, direction: String) -> Double? {
//        
//        //print("PRINTING FROM COORDINATES LON FUNCTION")
//        //print("string: \(value), direction: \(direction)")
//        
//        if let deg = (Double(value.dropLast(7))), var min = (Double(value.dropFirst(3))) {
//            
//            min /= 60
//            let longtitude = deg + min
//            //print("final latitute: \(longtitude)")
//            
//            return (direction == "E" ? longtitude : -longtitude)
//        }
//        
//        return nil
//    }
    

}

