import Foundation

struct LoggerStub {
    func debug(_ message: String) {}
    func warning(_ message: String) {}
}

enum Log {
    static let navigation = LoggerStub()
}

public func debugLog(_ message: String) {}
public func debugLogOnce(_ message: String) {}
