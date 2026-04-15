//
//  NMEASentenceProcessor.swift
//  ExtasyCompleteNavigation
//
//  Declares which NMEA sentence formatters each domain processor handles.
//  `NMEAParser` still owns routing; this protocol supports tests and future registration.
//

import Foundation

/// Uppercase NMEA sentence formatter (after talker), e.g. `"DPT"`, `"MWV"`.
protocol NMEASentenceProcessor: AnyObject {
    static var supportedNMEASentenceFormats: [String] { get }
}

extension HydroProcessor: NMEASentenceProcessor {
    static var supportedNMEASentenceFormats: [String] { ["DPT", "MTW", "VHW", "VLW"] }
}

extension CompassProcessor: NMEASentenceProcessor {
    static var supportedNMEASentenceFormats: [String] { ["HDG"] }
}

extension WindProcessor: NMEASentenceProcessor {
    static var supportedNMEASentenceFormats: [String] { ["MWV"] }
}

extension GPSProcessor: NMEASentenceProcessor {
    static var supportedNMEASentenceFormats: [String] { ["GLL", "GGA", "GSA", "GSV", "RMC"] }
}
