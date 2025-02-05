import Foundation
import CocoaAsyncSocket
import UIKit

@Observable
class UDPHandler: NSObject, GCDAsyncUdpSocketDelegate {
    private var socket: GCDAsyncUdpSocket!
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var udpPollingTimer: Timer?
    private var isSocketOpen = false

    var onDataReceived: ((String) -> Void)? // Callback for incoming data

    override init() {
        super.init()
        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: .global())
        configureNotifications()
        debugLog("UDPHandler initialized and notifications configured.")
    }

    // MARK: - Start Listening (Foreground)
    func startListening() {
        if !isSocketOpen {
            openSocket()
            debugLog("UDP continuous listening started.")
        } else {
            debugLog("Attempted to start listening, but socket is already open.")
        }
    }

    // MARK: - Stop Listening
    func stopListening() {
        udpPollingTimer?.invalidate()
        udpPollingTimer = nil
        closeSocket()
        endBackgroundTask()
        debugLog("UDP listening stopped and background task ended.")
    }

    // MARK: - Open/Close Socket
    private func openSocket() {
        guard !isSocketOpen else {
            debugLog("Attempted to open socket, but it's already open.")
            return
        }
        
        do {
            try socket.bind(toPort: 4950)
            try socket.beginReceiving()
            isSocketOpen = true
            debugLog("UDP socket successfully opened on port 4950 and started receiving data.")
        } catch {
            debugLog("Failed to open UDP socket: \(error.localizedDescription)")
        }
    }

    private func closeSocket() {
        guard isSocketOpen else {
            debugLog("Attempted to close socket, but it's already closed.")
            return
        }
        socket.close()
        isSocketOpen = false
        debugLog("UDP socket successfully closed.")
    }

    // MARK: - Background Polling Logic
    private func scheduleBackgroundPolling() {
        udpPollingTimer?.invalidate() // Prevent multiple timers

        udpPollingTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if UIApplication.shared.applicationState == .active {
                    debugLog("App is active, skipping background polling.")
                    return
                }

                if self.isSocketOpen {
                    debugLog("Socket is already open during polling, closing to reset connection...")
                    self.closeSocket()
                }

                debugLog("Polling for UDP data...")
                self.openSocket()

                DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                    DispatchQueue.main.async {
                        if UIApplication.shared.applicationState == .background {
                            self.closeSocket()
                            debugLog("Socket closed after 5-second polling period.")
                        } else {
                            debugLog("App became active during polling, keeping socket open.")
                        }
                    }
                }
            }
        }
        RunLoop.current.add(udpPollingTimer!, forMode: .common)
        debugLog("Background polling scheduled every 15 seconds.")
    }

    // MARK: - App State Handlers
    @objc private func handleAppDidEnterBackground() {
        debugLog("App entered background. Switching to polling mode...")
        closeSocket()
        scheduleBackgroundPolling()
        startBackgroundTask()
    }

    @objc private func handleAppDidBecomeActive() {
        debugLog("App became active. Checking socket status...")

        udpPollingTimer?.invalidate()
        udpPollingTimer = nil

        if !isSocketOpen {
            debugLog("Socket is closed. Opening socket for continuous listening.")
            openSocket()
        } else {
            debugLog("Socket is already open. No action needed.")
        }

        endBackgroundTask()
    }

    // MARK: - Configure Notifications
    private func configureNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        debugLog("App state notifications configured.")
    }

    // MARK: - Background Task Management
    private func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "UDPBackgroundTask") {
            self.endBackgroundTask()
        }
        debugLog("Background task started.")
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
            debugLog("Background task ended.")
        }
    }

    // MARK: - UDP Delegate Methods
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        if let receivedString = String(data: data, encoding: .utf8) {
            onDataReceived?(receivedString)
            debugLog("Received UDP data: \(receivedString)")
        } else {
            debugLog("Received UDP data but failed to decode.")
        }
    }

    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        if let error = error {
            debugLog("UDP socket closed unexpectedly with error: \(error.localizedDescription)")
        } else {
            debugLog("UDP socket closed normally.")
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        debugLog("UDPHandler deinitialized and observers removed.")
    }
}
