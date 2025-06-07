import Foundation
import WatchConnectivity


final class DataCoordinator {

    static let shared = DataCoordinator()
    private init() {}

    private var latestValues: [String: Double] = [:]
    private var lastSentValues: [String: Double] = [:]
    private let watchSender = WatchDataSender()
    
    // MARK: - Update Metric
    func update(metric key: String, value: Double?, precision: RoundingPrecision) {
        guard let value = value else { return }
        let rounded = preciseRound(value, precision: precision)
        latestValues[key] = rounded
        
        debugLog("🆕 Updated \(key): \(rounded)")
    }

    // MARK: - Trigger Send
    func sendIfChanged() {
        guard !latestValues.isEmpty else {
            debugLog("⏭️ No values to send")
            return
        }

        if latestValues != lastSentValues {
            lastSentValues = latestValues
            debugLog("📤 Sending to watch → \(latestValues)")
            watchSender.send(metrics: latestValues)
        } else {
            debugLog("⏭️ No visible change — skipping watch update")
        }
    }
}
