//
//  UDPHandler.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 18.11.24.
//

import Foundation
import CocoaAsyncSocket

@Observable
class UDPHandler: NSObject, GCDAsyncUdpSocketDelegate {
    private var socket: GCDAsyncUdpSocket!
    var onDataReceived: ((String) -> Void)? // Callback for incoming data

    override init() {
        super.init()
        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: .global())
    }

    func start(port: UInt16 = 4950) {
        do {
            try socket.bind(toPort: port)
            print("UDP connection started on port \(port)...")
            try socket.beginReceiving()
        } catch {
            print("Failed to start UDP connection: \(error)")
            socket.close()
        }
    }

    func stop() {
        socket.close()
        print("UDP connection stopped.")
    }

    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        if let receivedString = String(data: data, encoding: .utf8) {
            onDataReceived?(receivedString) // Pass data to the NMEAParser
        }
    }

    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        print("UDP socket closed: \(String(describing: error))")
    }
}
