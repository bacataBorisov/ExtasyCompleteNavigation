import WatchConnectivity

class WatchConnectivityManager: NSObject, WCSessionDelegate {

    private var session: WCSession { WCSession.default }

    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
            debugLog("📲 iPhone: WCSession setup and activation started")
        } else {
            debugLog("❌ iPhone: WCSession is NOT supported")
        }
    }

    // Called when session activation completes
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            debugLog("✅ iPhone: WCSession activated")
            debugLog("📡 iPhone: isReachable = \(session.isReachable)")
            //tryToSendTestMessage()
        } else {
            debugLog("❌ iPhone: WCSession failed to activate — state: \(activationState)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        debugLog("⚠️ iPhone: Session did become inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        debugLog("⚠️ iPhone: Session did deactivate")
    }

    /// Call this after activation or manually later
    func tryToSendTestMessage(retryCount: Int = 3) {
        if session.isReachable {
            let message: [String: Any] = [
                "depth": "999.0",
                "sog": "888.0",
                "wind": "777.0"
            ]
            session.sendMessage(message, replyHandler: nil) { error in
                debugLog("❌ iPhone: sendMessage failed: \(error.localizedDescription)")
            }
            debugLog("📤 iPhone: Sent test message: \(message)")
        } else if retryCount > 0 {
            debugLog("⌛️ iPhone: Watch not reachable. Retrying in 1s... (\(retryCount) left)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.tryToSendTestMessage(retryCount: retryCount - 1)
            }
        } else {
            debugLog("❌ iPhone: Watch is not reachable after retries — giving up")
        }
    }
}
