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
    
    init() {
        // Connect UDPHandler to NMEAParser
        udpHandler.onDataReceived = { rawData in
            self.nmeaParser.processRawString(rawData: rawData)
        }
        udpHandler.start()
    }
}
