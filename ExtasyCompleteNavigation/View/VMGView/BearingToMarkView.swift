//
//  BearingToMarkView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 27.11.24.
//

import SwiftUI
import SwiftData
import Foundation
import CoreLocation

struct BearingToMarkView: View {
    
    @ObservedObject var viewModel: VMGViewModel
    
    @Environment(\.modelContext) private var context
    @Bindable var lastUsedUnit: BearingToMarkUnitsMenu
    
    let width: CGFloat
    
    var body: some View {
        ZStack {
            Text("BTM")
                .frame(width: width, height: width, alignment: .topLeading)
                .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))
            Text(viewModel.unitBearingLabel)
                .frame(width: width, height: width, alignment: .topTrailing)
                .font(Font.custom("AppleSDGothicNeo-Bold", size: width * 0.2))
            
            Text(viewModel.formattedBearing)
                .frame(width: width, height: width, alignment: .center)
                .font(Font.custom("Futura-CondensedExtraBold", size: width * 0.4))
        }
        .minimumScaleFactor(0.2)
        .padding(.top, 5)
        .onTapGesture {
            toggleBearingUnit()
        }
        .foregroundStyle(Color("display_font"))
        
    }
    
    
    // MARK: - Methods
    
    private func toggleBearingUnit() {
        // Cycle through bearing units
        switch lastUsedUnit.angle {
        case .relativeAngle:
            lastUsedUnit.angle = .trueAngle
        case .trueAngle:
            lastUsedUnit.angle = .relativeAngle
        }
        
        // Update the view model
        viewModel.selectedBearingUnit = lastUsedUnit.angle
        
        // Save the change to the database
        context.insert(lastUsedUnit)
    }
}

#Preview {
    GeometryProvider { width, _ in
        // Provide a mock NauticalDistance object
        let mockBearingToMark = BearingToMarkUnitsMenu(angle: .relativeAngle)
        // Create a mock VMGProcessor
        let mockProcessor = VMGProcessor()
        // Provide a mock VMGViewModel with the VMGProcessor
        let mockViewModel = VMGViewModel(vmgProcessor: mockProcessor)
        // Set some mock data in the processor for testing
        mockProcessor.vmgData.relativeMarkBearing = 154 // Example: 1500 meters
        
        return BearingToMarkView(
            viewModel: mockViewModel,
            lastUsedUnit: mockBearingToMark,
            width: width
        )
        .modelContainer(for: NauticalDistance.self)
    }
    .aspectRatio(contentMode: .fit)
}

