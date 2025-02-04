//
//  Logging.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 25.12.24.
//
import Foundation

// DEBUG log wrapper helper function
// TODO: - think about extending the functionality of the function with timestamp and logs to file here
public func debugLog(_ message: String) {
    #if DEBUG
    print(message)
    #endif
}

// MARK: - Helper Function to Log Only Once
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

//public func debugLog(
//    _ message: String,
//    file: String = #file,
//    function: String = #function,
//    line: Int = #line
//) {
//    #if DEBUG
//    let fileName = (file as NSString).lastPathComponent
//    let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
//    print("[DEBUG] [\(timestamp)] [\(fileName):\(line)] \(function) -> \(message)")
//    #endif
//}
