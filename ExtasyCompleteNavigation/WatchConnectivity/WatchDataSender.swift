//
//  WatchDataSender.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 2.06.25.
//

import WatchConnectivity

class WatchDataSender {
    
    func send(metrics: [String: Double]) {
        var message = metrics
        message["sentAt"] = Date().timeIntervalSince1970

        guard WCSession.default.isReachable else {
            print("⌛️ Watch not reachable")
            return
        }

        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("❌ Send failed: \(error.localizedDescription)")
        }

        print("📤 Sent to watch: \(message)")
    }
}
