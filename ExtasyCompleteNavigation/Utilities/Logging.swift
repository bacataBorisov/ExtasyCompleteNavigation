import Foundation
import os

// MARK: - Structured Logging

enum Log {
    static let navigation = Logger(subsystem: "com.extasy.navigation", category: "navigation")
    static let network    = Logger(subsystem: "com.extasy.navigation", category: "network")
    static let parsing    = Logger(subsystem: "com.extasy.navigation", category: "parsing")
    static let ui         = Logger(subsystem: "com.extasy.navigation", category: "ui")
    static let settings   = Logger(subsystem: "com.extasy.navigation", category: "settings")
    static let watch      = Logger(subsystem: "com.extasy.navigation", category: "watch")
    static let audio      = Logger(subsystem: "com.extasy.navigation", category: "audio")
    static let general    = Logger(subsystem: "com.extasy.navigation", category: "general")
}

// MARK: - Legacy Bridge (calls forward to os.Logger)

public func debugLog(_ message: String) {
    #if DEBUG
    Log.general.debug("\(message, privacy: .public)")
    #endif
}

private var loggedMessages = Set<String>()
private let logQueue = DispatchQueue(label: "com.extasy.navigation.debugLogQueue", attributes: .concurrent)

public func debugLogOnce(_ message: String) {
    logQueue.sync {
        if !loggedMessages.contains(message) {
            logQueue.async(flags: .barrier) {
                loggedMessages.insert(message)
            }
            debugLog(message)
        }
    }
}
