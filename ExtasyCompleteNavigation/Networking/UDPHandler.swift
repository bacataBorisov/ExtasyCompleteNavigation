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
                    if receiving {
                        consoleSignal("NMEA: receiving UDP (traffic within \(Int(self.receiveTimeout))s)")
                    } else if self.isSocketOpen {
                        consoleSignal("NMEA: idle (no UDP for \(Int(self.receiveTimeout))s)")
                    }
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
        } else {
            debugLog("UDP: startListening ignored (socket already open)")
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
        consoleSignal("UDP: listening stopped")
    }

    // MARK: - Open/Close Socket
    private func openSocket() {
        guard !isSocketOpen else {
            debugLog("UDP: openSocket ignored (already open)")
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
            consoleSignal("UDP: socket open — port 4950, listening for NMEA")
        } catch {
            consoleSignal("UDP: failed to open socket — \(error.localizedDescription)")
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
            debugLog("UDP: closeSocket ignored (already closed)")
            return
        }
        socket.close()
        isSocketOpen = false
        consoleSignal("UDP: socket closed")
    }
    
    private func recreateSocket() {
        if isSocketOpen {
            socket.close()
            isSocketOpen = false
        }
        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: delegateQueue)
        debugLog("UDP: socket instance recreated")
    }
    
    // MARK: - Auto-Reconnection
    private func scheduleReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            consoleSignal("UDP: max reconnect attempts (\(maxReconnectAttempts)) — giving up")
            DispatchQueue.main.async {
                self.connectionState = .error
            }
            return
        }
        
        let delay = min(pow(2.0, Double(reconnectAttempts)), 30.0)
        reconnectAttempts += 1
        consoleSignal("UDP: reconnect #\(reconnectAttempts) in \(String(format: "%.1f", delay))s")
        
        DispatchQueue.main.async {
            self.connectionState = .reconnecting
        }
        
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self, !self.intentionallyClosed else { return }
            consoleSignal("UDP: reconnect attempt \(self.reconnectAttempts)…")
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
                    debugLog("UDP: poll tick skipped (app active)")
                    return
                }

                if self.isSocketOpen {
                    self.closeSocket()
                }

                consoleSignal("UDP: background polling — opening socket (5s window)")
                self.recreateSocket()
                self.openSocket()

                DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                    DispatchQueue.main.async {
                        if UIApplication.shared.applicationState == .background {
                            self.closeSocket()
                            consoleSignal("UDP: background poll — socket closed after 5s window")
                        } else {
                            debugLog("UDP: poll — app became active during window; socket left open")
                        }
                    }
                }
            }
        }
        RunLoop.current.add(udpPollingTimer!, forMode: .common)
        consoleSignal("UDP: background polling scheduled (every 15s)")
    }

    // MARK: - App State Handlers
    @objc private func handleAppDidEnterBackground() {
        consoleSignal("UDP: app backgrounded — switching to polling mode")
        intentionallyClosed = true
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        closeSocket()
        intentionallyClosed = false
        scheduleBackgroundPolling()
        startBackgroundTask()
    }

    @objc private func handleAppDidBecomeActive() {
        consoleSignal("UDP: app active — continuous listening")

        udpPollingTimer?.invalidate()
        udpPollingTimer = nil
        intentionallyClosed = false
        reconnectAttempts = 0

        if !isSocketOpen {
            recreateSocket()
            openSocket()
        } else {
            debugLog("UDP: app active — socket already open")
        }

        endBackgroundTask()
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
        debugLog("UDP: background task started")
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
            debugLog("UDP: background task ended")
        }
    }

    // MARK: - UDP Delegate Methods
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        lastReceiveTime = Date()
        if let receivedString = String(data: data, encoding: .utf8) {
            onDataReceived?(receivedString)
        } else {
            consoleSignal("UDP: received packet but could not decode as UTF-8")
        }
    }

    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        isSocketOpen = false
        if let error = error {
            consoleSignal("UDP: socket closed with error — \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.connectionState = .error
            }
            if !intentionallyClosed {
                scheduleReconnect()
            }
        } else {
            debugLog("UDP: socket closed normally (no error)")
            if !intentionallyClosed {
                DispatchQueue.main.async {
                    self.connectionState = .disconnected
                }
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        debugLog("UDPHandler deinit")
    }
}
