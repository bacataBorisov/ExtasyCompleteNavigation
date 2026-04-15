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

    private var isTargetSelected: Bool {
        navigationReadings.gpsData?.isTargetSelected ?? false
    }

    var body: some View {

        GeometryReader { geometry in
            let sectionPadding: CGFloat = 8

            VStack(spacing: sectionPadding) {

                VStack(spacing: sectionPadding) {
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

                    // VMC Progress Bar (slide in/out from left)
                    ZStack {
                        if isTargetSelected {
                            // Determine current tack from TWA: > 180° (normalized) = wind on port = PORT tack.
                            let rawTWA = navigationReadings.windData?.trueWindAngle ?? 0
                            let normTWA = (rawTWA + 360).truncatingRemainder(dividingBy: 360)
                            let isPortTack = normTWA > 180
                            // Nautical convention: port = red, starboard = green
                            let currentTackLabel  = isPortTack ? "PORT" : "STBD"
                            let oppositeTackLabel = isPortTack ? "STBD" : "PORT"
                            let currentTackColor:  Color = isPortTack ? Color(red: 1, green: 0.3, blue: 0.3) : Color(red: 0.2, green: 0.8, blue: 0.4)
                            let oppositeTackColor: Color = isPortTack ? Color(red: 0.2, green: 0.8, blue: 0.4) : Color(red: 1, green: 0.3, blue: 0.3)

                            PerformanceDoubleBarView(
                                topBarValue: navigationReadings.waypointData?.currentTackVMCDisplay ?? 0,
                                bottomBarValue: navigationReadings.waypointData?.oppositeTackVMCDisplay ?? 0,
                                maxPolarValue: navigationReadings.waypointData?.maxTackPolarVMC ?? 0,
                                barLabel: "VMC",
                                topBarLabel: currentTackLabel,
                                bottomBarLabel: oppositeTackLabel,
                                topBarPerformance: navigationReadings.waypointData?.currentTackVMCPerformance ?? 0,
                                bottomBarPerformance: navigationReadings.waypointData?.oppositeTackVMCPerformance ?? 0,
                                topBarLabelColor: currentTackColor,
                                bottomBarLabelColor: oppositeTackColor)
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
                        rangeMultiplier: 1,
                        trueWindDirection: navigationReadings.windData?.trueWindDirection ?? 0,
                        tackDeviation: navigationReadings.vmgData?.tackDeviation
                    )
                    .frame(height: 40)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
    }
}

#Preview {
    PerformanceView()
        .environment(NMEAParser())
        .environment(SettingsManager())
}
