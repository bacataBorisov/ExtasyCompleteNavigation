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
    }

    // MARK: - Start Listening (Foreground)
    func startListening() {
        if !isSocketOpen {
            openSocket()
            debugLog("UDP continuous listening started.")
        }
    }

    // MARK: - Stop Listening
    func stopListening() {
        udpPollingTimer?.invalidate()
        udpPollingTimer = nil
        closeSocket()
        endBackgroundTask()
        debugLog("UDP listening stopped.")
    }

    // MARK: - Open/Close Socket
    private func openSocket() {
        guard !isSocketOpen else {
            debugLog("UDP socket already open. Skipping rebind.")
            return
        }
        
        do {
            try socket.bind(toPort: 4950)
            try socket.beginReceiving()
            isSocketOpen = true
            debugLog("UDP socket opened on port 4950 and started receiving data.")
        } catch {
            debugLog("Failed to open UDP socket: \(error.localizedDescription)")
        }
    }

    private func closeSocket() {
        guard isSocketOpen else {
            debugLog("Socket is already closed. No action taken.")
            return
        }
        socket.close()
        isSocketOpen = false
        debugLog("UDP socket closing ...")
    }

    // MARK: - Background Polling Logic
    private func scheduleBackgroundPolling() {
        udpPollingTimer?.invalidate() // Ensure no duplicate timers

        udpPollingTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if UIApplication.shared.applicationState == .active {
                    debugLog("App is active. Skipping background polling.")
                    return
                }

                if self.isSocketOpen {
                    debugLog("Socket is already open, closing before reopening...")
                    self.closeSocket()
                }

                debugLog("Polling for UDP data...")
                self.openSocket()
                debugLog("Socket opened for polling.")

                DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                    DispatchQueue.main.async {
                        if UIApplication.shared.applicationState == .background {
                            self.closeSocket()
                            debugLog("Socket closed after polling period.")
                        } else {
                            debugLog("App became active during polling, keeping socket open.")
                        }
                    }
                }
            }
        }
        RunLoop.current.add(udpPollingTimer!, forMode: .common)
        debugLog("Scheduled UDP polling every 20 seconds")
    }

    // MARK: - App State Handlers
    @objc private func handleAppDidEnterBackground() {
        debugLog("App entered background. Starting polling mode...")
        closeSocket()
        scheduleBackgroundPolling()
    }

    @objc private func handleAppDidBecomeActive() {
        debugLog("App became active. Checking UDP socket status...")

        // Cancel polling timer when app enters foreground
        udpPollingTimer?.invalidate()
        udpPollingTimer = nil

        if !isSocketOpen {
            debugLog("UDP socket is not open. Opening socket for continuous listening.")
            openSocket()
        } else {
            debugLog("UDP socket is already open. No action needed.")
        }
    }

    // MARK: - Configure Notifications
    private func configureNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    // MARK: - Background Task Management
    private func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "UDPBackgroundTask") {
            self.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    // MARK: - UDP Delegate Methods
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        if let receivedString = String(data: data, encoding: .utf8) {
            onDataReceived?(receivedString)
            //debugLog("Received UDP data: \(receivedString)")
        }
    }

    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        if let error = error {
            debugLog("UDP socket closed with error: \(error.localizedDescription)")
        } else {
            debugLog("UDP socket closed normally.")
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
