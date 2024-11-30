//
//  VMGViewModel.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 27.11.24.
//


import Foundation
import SwiftUI
import Combine

class VMGViewModel: ObservableObject {
    
    @Published private(set) var estTimeOfArrival: String = "-:-:-"
    @Published private(set) var estTimeToNextTack: String = "-:-:-"
    @Published private(set) var distanceToMark: Double = 0
    @Published private(set) var nextTackDistance: Double = 0
    @Published private(set) var relativeBearing: Double = 0
    @Published private(set) var trueBearing: Double = 0
    @Published private(set) var polarSpeed: Double = 0
    @Published private(set) var waypointVMC: Double = 0
    @Published private(set) var polarVMG: Double = 0

    @Published var selectedDistanceUnit: DistanceUnit =  .meters
    @Published var selectedTackDistanceUnit: NextTackDistance =  .meters
    @Published var selectedBearingUnit: WaypointAngle = .relativeAngle
    
    private var vmgProcessor: VMGProcessor

    init(vmgProcessor: VMGProcessor) {
        self.vmgProcessor = vmgProcessor
        observeVMGProcessor()
    }

    private func observeVMGProcessor() {
        // Observe the processor and update the view model's properties
        vmgProcessor.$vmgData.sink { [weak self] vmgData in
            DispatchQueue.main.async {
                
                self?.estTimeOfArrival = Self.formatETA(vmgData.estTimeOfArrival)
                self?.estTimeToNextTack = Self.formatETA(vmgData.etaToNextTack)
                self?.distanceToMark = vmgData.distanceToMark ?? 0
                self?.nextTackDistance = vmgData.distanceToNextTack ?? 0
                self?.relativeBearing = vmgData.relativeMarkBearing
                self?.trueBearing = vmgData.trueMarkBearing
                self?.polarSpeed = vmgData.polarSpeed ?? 0
                self?.waypointVMC = vmgData.waypointVMC ?? 0
                self?.polarVMG = vmgData.polarVMG ?? 0 

            }
        }
        .store(in: &subscriptions)
    }
    // MARK: - Formatting Properties
    /// Label for the current distance unit
    var unitDistanceLabel: String {
        switch selectedDistanceUnit {
        case .nauticalMiles: return "nmi"
        case .nauticalCables: return "cab"
        case .meters: return "mtrs"
        case .boatLength: return "bLEN"
        }
    }
    
    var unitTackDistanceLabel: String {
        switch selectedTackDistanceUnit {
        case .nauticalMiles: return "nmi"
        case .nauticalCables: return "cab"
        case .meters: return "mtrs"
        case .boatLength: return "bLEN"
        }
    }
    /// Label for the Bearing to Mark
    var unitBearingLabel: String {
        switch selectedBearingUnit {
        case .trueAngle: return "T°"
        case .relativeAngle: return "R°"
        }
    }
    /// Calculated distance value based on the selected unit (computed property)
    var formattedDistance: String {
        let distanceInMeters = distanceToMark
        let formattedValue: Double
        switch selectedDistanceUnit {
        case .nauticalMiles:
            formattedValue = distanceInMeters * toNauticalMiles
        case .nauticalCables:
            formattedValue = distanceInMeters * toNauticalCables
        case .meters:
            formattedValue = distanceInMeters
        case .boatLength:
            formattedValue = distanceInMeters * toBoatLengths
        }
        return String(format: "%.f", formattedValue)
    }
    
    /// Calculated distance value based on the selected unit (computed property)
    var formattedTackDistance: String {
        let distanceInMeters = nextTackDistance
        let formattedValue: Double
        switch selectedTackDistanceUnit {
        case .nauticalMiles:
            formattedValue = distanceInMeters * toNauticalMiles
        case .nauticalCables:
            formattedValue = distanceInMeters * toNauticalCables
        case .meters:
            formattedValue = distanceInMeters
        case .boatLength:
            formattedValue = distanceInMeters * toBoatLengths
        }
        return String(format: "%.f", formattedValue)
    }
    
    /// Calculated distance value based on the selected unit (computed property)
    var formattedBearing: String {
        
        let formattedValue: Double
        switch selectedBearingUnit {
        case .trueAngle:
            formattedValue = trueBearing
        case .relativeAngle:
            formattedValue = relativeBearing
        }
        return String(format: "%.f", formattedValue)
        
    }
    
    // MARK: - Computed Properties for Formatted Strings
    
    var formattedPolarSpeed: String {
        return Self.formatSpeed(polarSpeed)
    }
    
    var formattedWaypointVMC: String {
        return Self.formatSpeed(waypointVMC)
    }
    
    var formattedPolarVMG: String {
        return Self.formatSpeed(polarVMG)
    }
    
    //MARK: - Helper Methods
    private static func formatETA(_ eta: Double?) -> String {
        guard let eta = eta else { return "Not Available" }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter.string(from: eta * 3600) ?? "Invalid ETA"
    }

    private static func formatDistance(_ distance: Double?) -> String {
        guard let distance = distance else { return "0.0 m" }
        return String(format: "%.1f m", distance)
    }

    private static func formatBearing(_ bearing: Double?) -> String {
        guard let bearing = bearing else { return "0°" }
        return String(format: "%.0f°", bearing)
    }
    private static func formatSpeed(_ speed: Double?) -> String {
        guard let speed = speed else { return "0.0 km/h" }
        return String(format: "%.2f", speed)
    }

    // Allow interaction with the processor if needed
    func resetVMGData() {
        vmgProcessor.resetVMGCalculations()
    }

    private var subscriptions = Set<AnyCancellable>()
}
