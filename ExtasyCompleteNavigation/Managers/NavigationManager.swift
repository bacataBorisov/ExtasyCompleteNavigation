//
//  NavigationManager.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 18.11.24.
//
//
/*
 
 The navigation manager is responsible for connection the UDPHandler and the NMEAParser. Could be further extended if necessary
 
 */

import Foundation

@Observable
class NavigationManager {
    let udpHandler = UDPHandler()
    let nmeaParser = NMEAParser()
    //used for watch data send
    
    init() {
        // Connect UDPHandler to NMEAParser
        udpHandler.onDataReceived = { rawData in
            
            // MARK: - Commented variables are for measuring processing time - avg for now is ~0.2 ms
            //let startTime = CFAbsoluteTimeGetCurrent()
            self.nmeaParser.processRawString(rawData: rawData)
            
            //let elapsedTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000 // Convert to milliseconds
            //debugLog("Processing Time: \(elapsedTime) ms")
        }
        udpHandler.startListening()
    }
}
