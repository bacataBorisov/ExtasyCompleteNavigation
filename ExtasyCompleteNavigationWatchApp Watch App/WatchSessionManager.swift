import WatchConnectivity
import Observation

@Observable
class WatchSessionManager: NSObject, WCSessionDelegate {
    
    //core metrics
    var depth = "--"
    var boatSpeedLog = "--"
    var heading = "--"
    var sog = "--"
    
    //wind metrics
    var tws = "--"
    var twa = "--"
    var twd = "--"
    var aws = "--"
    var awa = "--"
    var awd = "--"
    
    
    
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
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            print("📡 Watch: Received message → \(message)")

            let fieldMap: [String: (String, (String) -> Void)] = [
                //core values
                "depth"     : ("%.1f", { self.depth = $0 }),
                "speed"     : ("%.2f", { self.boatSpeedLog = $0 }),
                "heading"   : ("%.f",  { self.heading = $0 }),
                "sog"       : ("%.2f", { self.sog = $0 }),
                
                //wind values
                "tws"       : ("%.1f", { self.tws = $0 }),
                "twa"       : ("%.f", { self.twa = $0 }),
                "twd"       : ("%.f", { self.twd = $0 }),
                "aws"       : ("%.1f", { self.aws = $0 }),
                "awa"       : ("%.f", { self.awa = $0 }),
                "awd"       : ("%.f", { self.awd = $0 })

            ]

            for (key, (format, setter)) in fieldMap {
                if let value = message[key] as? Double {
                    setter(String(format: format, value))
                } else if let stringValue = message[key] as? String {
                    setter(stringValue)
                }
            }

            // Optional delay logger
    //        if let sentAt = message["sentAt"] as? TimeInterval {
    //            let delay = Date().timeIntervalSince1970 - sentAt
    //            print("⏱️ Delay from iPhone to Watch: \(delay * 1000) ms")
    //        }
        }
    }
}
