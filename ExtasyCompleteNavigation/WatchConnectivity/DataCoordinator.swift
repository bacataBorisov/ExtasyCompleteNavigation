import Foundation
import WatchConnectivity


final class DataCoordinator {
    static let shared = DataCoordinator()

    private init() {} // Prevent external initialization

    private var latestDepth: Double?
    private var latestSpeed: Double?
    private var latestWind: Double?
    private var latestSOG: Double?

    private var lastSentSnapshot: (depth: Double?, speed: Double?, wind: Double?, sog: Double?) = (nil, nil, nil, nil)
    private let watchSender = WatchDataSender()
    private var timer: Timer?
    
    func update(depth: Double?, speed: Double?, wind: Double?, sog: Double?) {
        if let depth = depth {
            latestDepth = round(depth * 100) / 100
        }
        if let speed = speed {
            latestSpeed = round(speed * 100) / 100
        }
        if let wind = wind {
            latestWind = round(wind * 100) / 100
        }
        
        if let sog = sog {
            latestSOG = round(sog * 100) / 100
        }

        debugLog("🆕 Coordinator received update → depth: \(latestDepth?.description ?? "nil"), speed: \(latestSpeed?.description ?? "nil"), wind: \(latestWind?.description ?? "nil")")
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.sendIfChanged()
        }
    }

    func sendIfChanged() {
        guard let depth = latestDepth,
              let speed = latestSpeed,
              let wind = latestWind,
              let sog = latestSOG
        else {
            debugLog("⏭️ Skipping send — one or more values are nil")
            return
        }

        // Round to the appropriate decimal places
        let roundedDepth = preciseRound(depth, precision: .tenths)
        let roundedSpeed = preciseRound(speed, precision: .hundredths)
        let roundedWind  = preciseRound(wind, precision: .tenths)
        let roundedSOG  = preciseRound(sog, precision: .hundredths)


        let current = (roundedDepth, roundedSpeed, roundedWind, roundedSOG)

        if current != lastSentSnapshot {
            lastSentSnapshot = current
            debugLog("📤 Sending to watch → depth: \(roundedDepth), speed: \(roundedSpeed), wind: \(roundedWind)")
            watchSender.send(depth: roundedDepth, speed: roundedSpeed, wind: roundedWind, sog: roundedSOG)
        } else {
            debugLog("⏭️ No visible change — skipping watch update")
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func updateDepth(_ depth: Double?) {
        update(depth: depth, speed: nil, wind: nil, sog: nil)
    }

    func updateSpeed(_ speed: Double?) {
        update(depth: nil, speed: speed, wind: nil, sog: nil)
    }

    func updateWind(_ wind: Double?) {
        update(depth: nil, speed: nil, wind: wind, sog: nil)
    }
    func updateSOG(_ sog: Double?) {
        update(depth: nil, speed: nil, wind: nil, sog: sog)
    }
}
