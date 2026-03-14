import Foundation
import CocoaAsyncSocket
import UIKit

enum ConnectionState: String {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case error
}

@Observable
class UDPHandler: NSObject, GCDAsyncUdpSocketDelegate {
    private var socket: GCDAsyncUdpSocket!
    private let delegateQueue = DispatchQueue(label: "com.extasy.udp.delegate")
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var udpPollingTimer: Timer?
    private var isSocketOpen = false
    
    var connectionState: ConnectionState = .disconnected
    
    /// Tracks whether UDP data has been received recently (within 10s)
    var isReceivingData: Bool = false
    @ObservationIgnored private var lastReceiveTime: Date?
    @ObservationIgnored private var receiveCheckTimer: Timer?
    private let receiveTimeout: TimeInterval = 10
    
    @ObservationIgnored private var reconnectTimer: Timer?
    @ObservationIgnored private var reconnectAttempts: Int = 0
    private let maxReconnectAttempts = 10
    private var intentionallyClosed = false

    var onDataReceived: ((String) -> Void)?

    override init() {
        super.init()
        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: delegateQueue)
        configureNotifications()
        startReceiveMonitor()
        debugLog("UDPHandler initialized and notifications configured.")
    }
    
    private func startReceiveMonitor() {
        receiveCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let receiving: Bool
            if let last = self.lastReceiveTime {
                receiving = Date().timeIntervalSince(last) <= self.receiveTimeout
            } else {
                receiving = false
            }
            DispatchQueue.main.async {
                if self.isReceivingData != receiving {
                    self.isReceivingData = receiving
                }
                if self.isSocketOpen && self.connectionState != .connected {
                    self.connectionState = .connected
                }
            }
        }
    }

    // MARK: - Start Listening (Foreground)
    func startListening() {
        intentionallyClosed = false
        if !isSocketOpen {
            openSocket()
            debugLog("UDP continuous listening started.")
        } else {
            debugLog("Attempted to start listening, but socket is already open.")
        }
    }

    // MARK: - Stop Listening
    func stopListening() {
        intentionallyClosed = true
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        reconnectAttempts = 0
        udpPollingTimer?.invalidate()
        udpPollingTimer = nil
        closeSocket()
        endBackgroundTask()
        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
        debugLog("UDP listening stopped and background task ended.")
    }

    // MARK: - Open/Close Socket
    private func openSocket() {
        guard !isSocketOpen else {
            debugLog("Attempted to open socket, but it's already open.")
            return
        }
        
        DispatchQueue.main.async {
            self.connectionState = self.reconnectAttempts > 0 ? .reconnecting : .connecting
        }
        
        do {
            try socket.bind(toPort: 4950)
            try socket.beginReceiving()
            isSocketOpen = true
            reconnectAttempts = 0
            DispatchQueue.main.async {
                self.connectionState = .connected
            }
            debugLog("UDP socket successfully opened on port 4950 and started receiving data.")
        } catch {
            debugLog("Failed to open UDP socket: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.connectionState = .error
            }
            if !intentionallyClosed {
                scheduleReconnect()
            }
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
    
    private func recreateSocket() {
        if isSocketOpen {
            socket.close()
            isSocketOpen = false
        }
        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: delegateQueue)
        debugLog("Socket instance recreated.")
    }
    
    // MARK: - Auto-Reconnection
    private func scheduleReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            debugLog("Max reconnect attempts (\(maxReconnectAttempts)) reached. Giving up.")
            DispatchQueue.main.async {
                self.connectionState = .error
            }
            return
        }
        
        let delay = min(pow(2.0, Double(reconnectAttempts)), 30.0)
        reconnectAttempts += 1
        debugLog("Scheduling reconnect attempt \(reconnectAttempts) in \(delay)s...")
        
        DispatchQueue.main.async {
            self.connectionState = .reconnecting
        }
        
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self, !self.intentionallyClosed else { return }
            debugLog("Reconnect attempt \(self.reconnectAttempts)...")
            self.recreateSocket()
            self.openSocket()
        }
    }

    // MARK: - Background Polling Logic
    private func scheduleBackgroundPolling() {
        udpPollingTimer?.invalidate()

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
                self.recreateSocket()
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
        intentionallyClosed = true
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        closeSocket()
        intentionallyClosed = false
        scheduleBackgroundPolling()
        startBackgroundTask()
    }

    @objc private func handleAppDidBecomeActive() {
        debugLog("App became active. Checking socket status...")

        udpPollingTimer?.invalidate()
        udpPollingTimer = nil
        intentionallyClosed = false
        reconnectAttempts = 0

        if !isSocketOpen {
            debugLog("Socket is closed. Opening socket for continuous listening.")
            recreateSocket()
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
        lastReceiveTime = Date()
        if let receivedString = String(data: data, encoding: .utf8) {
            onDataReceived?(receivedString)
            debugLog("Received UDP data: \(receivedString)")
        } else {
            debugLog("Received UDP data but failed to decode.")
        }
    }

    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        isSocketOpen = false
        if let error = error {
            debugLog("UDP socket closed unexpectedly with error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.connectionState = .error
            }
            if !intentionallyClosed {
                scheduleReconnect()
            }
        } else {
            debugLog("UDP socket closed normally.")
            if !intentionallyClosed {
                DispatchQueue.main.async {
                    self.connectionState = .disconnected
                }
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        debugLog("UDPHandler deinitialized and observers removed.")
    }
}
