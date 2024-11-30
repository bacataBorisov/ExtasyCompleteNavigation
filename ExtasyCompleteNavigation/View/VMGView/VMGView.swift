//
//  VMGView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 14.01.24.
//

import SwiftUI
import CoreLocation
import SwiftData

struct VMGView: View {
    
    @ObservedObject var viewModel: VMGViewModel
    
    @Query private var lastUsedSettings: [NauticalDistance]
    @Query private var lastMarkAngle: [BearingToMarkUnitsMenu]
    @Query private var lastUsedDistanceForTack: [NextTackNauticalDistance]
    @Query private var lastUsedPosition: [SwitchCoordinatesView]
        
    var body: some View {
        GeometryProvider { width, _ in
            ZStack{
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 3), spacing: 0) {
                    
                    //Row 1
                    BearingToMarkView(viewModel: viewModel, lastUsedUnit: lastMarkAngle.last ?? BearingToMarkUnitsMenu(angle: .relativeAngle), width: width/3)
                    DistanceToWaypoint(viewModel: viewModel, lastUsedUnit: lastUsedSettings.last ?? NauticalDistance(distance: .nauticalMiles), width: width/3)
                    ReusableETACell(viewModel: viewModel, label: "ETA", value: viewModel.estTimeOfArrival, width: width/3)
                    //Row 2
                    ReusableSpeedCell(name: "pSPD", value: viewModel.polarSpeed, unit: "kn", width: width/3)
                    ReusableSpeedCell(name: "VMC", value: viewModel.waypointVMC, unit: "kn", width: width/3)
                    ReusableSpeedCell(name: "pVMG", value: viewModel.polarVMG, unit: "kn", width: width/3)

                    //Row 3
                    ReusableETACell(viewModel: viewModel, label: "ETA Tk", value: viewModel.estTimeToNextTack, width: width/3)
                    DistanceToNextTack(viewModel: viewModel, lastUsedUnit: lastUsedDistanceForTack.last ?? NextTackNauticalDistance(distance: .nauticalMiles), width: width/3)
                    CoordinatesView(lastUsedUnit: lastUsedPosition.last ?? SwitchCoordinatesView(position: .waypointCoordinates) , width: width/3)
                }
                DisplayGrid3x3Sectors()
            }
        }

        .aspectRatio(1, contentMode: .fit)
    }//END OF BODY
    
    // MARK: - Helper for HStack Rows
    private func row<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 10) {
            content()
        }
    }
    
}//END OF STRUCT

#Preview {
    let mockVMGProcessor = VMGProcessor()
    mockVMGProcessor.vmgData.markerCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    mockVMGProcessor.vmgData.estTimeOfArrival = 1.5 // 1.5 hours
    mockVMGProcessor.vmgData.distanceToMark = 2500.0 // 2500 meters
    mockVMGProcessor.vmgData.relativeMarkBearing = 45.0 // 45 degrees
    
    let viewModel = VMGViewModel(vmgProcessor: mockVMGProcessor)
    
    return VMGView(viewModel: viewModel)
        .modelContainer(for: [
            UserSettingsMenu.self,
            NauticalDistance.self,
            BearingToMarkUnitsMenu.self,
            NextTackNauticalDistance.self,
            SwitchCoordinatesView.self
        ])
}

