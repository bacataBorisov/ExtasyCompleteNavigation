//
//  NextTackDistance.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 7.02.24.
//

import SwiftUI
import SwiftData
import Foundation
import CoreLocation

struct DistanceToNextTack: View {
    
    @ObservedObject var viewModel: VMGViewModel
    
    @Environment(\.modelContext) private var context
    @Bindable var lastUsedUnit: NextTackNauticalDistance
    
    let width: CGFloat
    
    var body: some View {
        ZStack {
            Text("tckDT")
                .frame(width: width, height: width, alignment: .topLeading)
                .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))

            Text(viewModel.unitTackDistanceLabel)
                .frame(width: width, height: width, alignment: .topTrailing)
                .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))

            Text(viewModel.formattedTackDistance)
                .frame(width: width, height: width, alignment: .center)
                .font(Font.custom("Futura-CondensedExtraBold", size: width * 0.4))
        }
        .minimumScaleFactor(0.2)
        .padding(.top, 5)
        .onTapGesture {
            // Cycle through distance units
            switch viewModel.selectedTackDistanceUnit {
            case .nauticalMiles:
                viewModel.selectedTackDistanceUnit = .nauticalCables
            case .nauticalCables:
                viewModel.selectedTackDistanceUnit = .meters
            case .meters:
                viewModel.selectedTackDistanceUnit = .boatLength
            case .boatLength:
                viewModel.selectedTackDistanceUnit = .nauticalMiles
            }
        }
        .foregroundStyle(Color("display_font"))

    }
    
    
    // MARK: - Methods
    
    /// Toggles between the distance units in a circular sequence
    private func toggleDistanceUnit() {
        switch lastUsedUnit.distance {
        case .nauticalMiles:
            lastUsedUnit.distance = .nauticalCables
        case .nauticalCables:
            lastUsedUnit.distance = .meters
        case .meters:
            lastUsedUnit.distance = .boatLength
        case .boatLength:
            lastUsedUnit.distance = .nauticalMiles
        }
        context.insert(lastUsedUnit)
    }
}

#Preview {
    GeometryProvider { width, _ in
        // Provide a mock NauticalDistance object
        let mockNauticalDistance = NauticalDistance(distance: .nauticalMiles)

        // Create a mock VMGProcessor
        let mockProcessor = VMGProcessor()

        // Provide a mock VMGViewModel with the VMGProcessor
        let mockViewModel = VMGViewModel(vmgProcessor: mockProcessor)

        // Set some mock data in the processor for testing
        mockProcessor.vmgData.distanceToMark = 1500.0 // Example: 1500 meters

        return DistanceToWaypoint(
            viewModel: mockViewModel,
            lastUsedUnit: mockNauticalDistance,
            width: width
        )
        .modelContainer(for: NauticalDistance.self)
    }
    .aspectRatio(contentMode: .fit)
}
//#Preview {
//
//    GeometryProvider { width, _ in
//
//        DistanceToWaypoint(viewModel: VMGViewModel(), lastUsedUnit: NauticalDistance(), width: width)
//            .environment(NMEAParser())
//            .modelContainer(for: NauticalDistance.self)
//    }
//    .aspectRatio(contentMode: .fit)
//
//}
