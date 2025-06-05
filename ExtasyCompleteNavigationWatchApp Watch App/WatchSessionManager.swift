import WatchConnectivity
import Observation

@Observable
class WatchSessionManager: NSObject, WCSessionDelegate {
    var depth = "--"
    var boatSpeedLog = "--"
    var wind = "--"
    var sog = "--"

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
            print("⌚️ Watch: WCSession setup and activation started")
        } else {
            print("❌ Watch: WCSession is NOT supported")
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("✅ Watch: WCSession activated = \(activationState == .activated)")
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            print("📡 Watch: Received message → \(message)")

            // Depth
            if let depthValue = message["depth"] as? Double {
                self.depth = String(format: "%.1f", depthValue)
            } else if let depthStr = message["depth"] as? String {
                self.depth = depthStr
            } // ❌ Don't overwrite if nil

            // Speed
            if let boatSpeedValue = message["speed"] as? Double {
                self.boatSpeedLog = String(format: "%.2f", boatSpeedValue)
            } else if let boatSpeedValue = message["speed"] as? String {
                self.boatSpeedLog = boatSpeedValue
            } // ❌ Don't overwrite if nil

            // Wind
            if let windValue = message["wind"] as? Double {
                self.wind = String(format: "%.1f", windValue)
            } else if let windStr = message["wind"] as? String {
                self.wind = windStr
            } // ❌ Don't overwrite if nil
            
            // Wind
            if let sogValue = message["sog"] as? Double {
                self.sog = String(format: "%.2f", sogValue)
            } else if let sogStr = message["sog"] as? String {
                self.sog = sogStr
            } // ❌ Don't overwrite if nil
            
            /*
             Used for measuring the delay - to be used again when I connect to real devices
             
            if let sentAt = message["sentAt"] as? TimeInterval {
                let receivedAt = Date().timeIntervalSince1970
                let delay = receivedAt - sentAt
                print("⏱️ Delay from iPhone to Watch: \(delay * 1000) ms")
            }
             */
        }
    }}
