//
//  PerformanceView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 4.01.25.
//

import SwiftUI
import CoreLocation

struct PerformanceView: View {
    
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(SettingsManager.self) private var settingsManager

    @State private var isTargetSelected: Bool = false // State for target selection animation
    
    var body: some View {
        
        GeometryReader { geometry in
            //let totalWidth = geometry.size.width
            let sectionPadding: CGFloat = 8
            
            //                let titleFont = Font.system(size: totalWidth * 0.05, weight: .bold)
            //                let dataFont = Font.system(size: totalWidth * 0.04, weight: .regular)
            
            VStack (spacing: sectionPadding){
                
                VStack {
                    // Speed Efficiency
                    PerformanceDoubleBarView(
                        topBarValue: navigationReadings.hydroData?.boatSpeedLag ?? 0,
                        bottomBarValue: navigationReadings.gpsData?.speedOverGround ?? 0,
                        maxPolarValue: navigationReadings.vmgData?.polarSpeed ?? 0,
                        barLabel: "Speed",
                        topBarLabel: "Log",
                        bottomBarLabel: "SOG",
                        topBarPerformance: navigationReadings.vmgData?.speedPerformanceThroughWater ?? 0,
                        bottomBarPerformance: navigationReadings.vmgData?.speedPerformanceOverGround ?? 0
                    )
                    .frame(maxHeight: .infinity)

                    
                    // VMG Efficiency
                    PerformanceDoubleBarView(
                        topBarValue: navigationReadings.vmgData?.vmgThroughWater ?? 0,
                        bottomBarValue: navigationReadings.vmgData?.vmgOverGround ?? 0,
                        maxPolarValue: navigationReadings.vmgData?.polarVMG ?? 0,
                        barLabel: "VMG",
                        topBarLabel: "Log",
                        bottomBarLabel: "SOG",
                        topBarPerformance: navigationReadings.vmgData?.vmgThroughWaterPerformance ?? 0,
                        bottomBarPerformance: navigationReadings.vmgData?.vmgOverGroundPerformance ?? 0
                    )
                    .frame(maxHeight: .infinity)

                    // VMC Progress Bar (slide in/out from left)
                    ZStack {
                        if isTargetSelected {

                            PerformanceDoubleBarView(
                                topBarValue: navigationReadings.waypointData?.currentTackVMCDisplay ?? 0,
                                bottomBarValue: navigationReadings.waypointData?.oppositeTackVMCDisplay ?? 0,
                                maxPolarValue: navigationReadings.waypointData?.maxTackPolarVMC ?? 0,
                                barLabel: "VMC",
                                topBarLabel: "Current Tack",
                                bottomBarLabel: "Opposite Tack",
                                topBarPerformance: navigationReadings.waypointData?.currentTackVMCPerformance ?? 0,
                                bottomBarPerformance: navigationReadings.waypointData?.oppositeTackVMCPerformance ?? 0)
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            
                        }
                    }
                    
                    
                    TackAlignmentBar(
                        currentHeading: navigationReadings.compassData?.normalizedHeading ?? 0,
                        optimalUpTWA: navigationReadings.vmgData?.optimalUpTWA ?? 0,
                        optimalDnTWA: navigationReadings.vmgData?.optimalDnTWA ?? 0,
                        sailingState: navigationReadings.vmgData?.sailingState ?? "Unknown",
                        tolerance: settingsManager.tackTolerance,
                        rangeMultiplier: 1, //optional if you want to extend dynamically
                        trueWindDirection: navigationReadings.windData?.trueWindDirection ?? 0
                        )
                    .frame(height: 40)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    
                }
            }
        }
        .onAppear {
            updateTargetState()
        }
        .onChange(of: navigationReadings.gpsData?.isTargetSelected) {
            updateTargetState()
        }
        
    }
    private func updateTargetState() {
        isTargetSelected = navigationReadings.gpsData?.isTargetSelected ?? false
    }
    
}

#Preview {
    PerformanceView()
        .environment(NMEAParser())
        .environment(SettingsManager())
}
