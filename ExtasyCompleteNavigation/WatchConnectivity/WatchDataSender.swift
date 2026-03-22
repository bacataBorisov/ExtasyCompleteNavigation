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
            Log.watch.debug("Watch not reachable")
            return
        }

        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            Log.watch.error("Send failed: \(error.localizedDescription)")
        }

        Log.watch.debug("Sent to watch: \(message)")
    }
}
