//
//  ValidateNMEA.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 18.11.24.
//

import Foundation

struct UtilsNMEA {
    
    //MARK: - NMEA Calculating Checksum Function
    static func validateChecksum(_ str: String) -> Bool {
        
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
    static func validateChar(_ str: String) -> Bool {
        
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
    
    //MARK: - Split Raw Data Function
    static func splitNMEAString(_ str: String) -> [String] {
        
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
    
    //MARK: - Validate TalkerID Function
    static func validateTalkerID(_ str: String) -> Bool {
        
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
    static func validateSentenceFormat(_ str: String) -> Bool {
        
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
    
}
