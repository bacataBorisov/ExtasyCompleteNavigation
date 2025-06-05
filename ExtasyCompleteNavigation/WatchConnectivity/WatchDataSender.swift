//
//  WatchDataSender.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 2.06.25.
//

import WatchConnectivity

class WatchDataSender {
    func send(depth: Double?, speed: Double?, wind: Double?, sog: Double?) {
        guard WCSession.default.isReachable else {
            print("⌛️ Watch is not reachable")
            return
        }

        let message: [String: Any] = [
            "depth": depth ?? -1.0,
            "speed": speed ?? -1.0,
            "wind": wind ?? -1.0,
            "sog": sog ?? -1.0
            //"sentAt": Date().timeIntervalSince1970     //timestamp to measure delay between phone and watch

        ]

        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("❌ Send failed: \(error.localizedDescription)")
        }

        print("📤 Sent to watch: \(message)")
    }
}
