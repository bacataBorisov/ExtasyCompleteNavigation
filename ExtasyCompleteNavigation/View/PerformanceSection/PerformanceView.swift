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

    /// `false` on iPad lower strip: flatter bars, no card chrome per bar.
    var useBarCardChrome: Bool = true
    /// When `false`, the tack strip is hosted outside (e.g. full-width row under performance + waypoint on iPad).
    var embeddedTackBar: Bool = true

    private var isTargetSelected: Bool {
        navigationReadings.gpsData?.isTargetSelected ?? false
    }

    /// iPad lower strip + active mark: tighter bars and centered stack for even vertical padding.
    private var stripCompactBars: Bool {
        !useBarCardChrome && isTargetSelected
    }

    var body: some View {

        GeometryReader { geometry in
            let stackSpacing: CGFloat = useBarCardChrome ? 8 : (stripCompactBars ? 5 : 8)

            let barStack = VStack(spacing: stackSpacing) {
                    // Speed Efficiency
                    PerformanceDoubleBarView(
                        topBarValue: navigationReadings.hydroData?.boatSpeedLag ?? 0,
                        bottomBarValue: navigationReadings.gpsData?.speedOverGround ?? 0,
                        maxPolarValue: navigationReadings.vmgData?.polarSpeed ?? 0,
                        barLabel: "Speed",
                        topBarLabel: "Log",
                        bottomBarLabel: "SOG",
                        topBarPerformance: navigationReadings.vmgData?.speedPerformanceThroughWater ?? 0,
                        bottomBarPerformance: navigationReadings.vmgData?.speedPerformanceOverGround ?? 0,
                        cardStyle: useBarCardChrome,
                        stripCompact: stripCompactBars
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
                        bottomBarPerformance: navigationReadings.vmgData?.vmgOverGroundPerformance ?? 0,
                        cardStyle: useBarCardChrome,
                        stripCompact: stripCompactBars
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
                            let currentTackColor = TacticalPalette.tackLabelColor(for: currentTackLabel)
                            let oppositeTackColor = TacticalPalette.tackLabelColor(for: oppositeTackLabel)

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
                                bottomBarLabelColor: oppositeTackColor,
                                cardStyle: useBarCardChrome,
                                stripCompact: stripCompactBars
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                    }

                    if embeddedTackBar {
                        TackAlignmentBar(
                            currentHeading: navigationReadings.compassData?.normalizedHeading ?? 0,
                            optimalUpTWA: navigationReadings.vmgData?.optimalUpTWA ?? 0,
                            optimalDnTWA: navigationReadings.vmgData?.optimalDnTWA ?? 0,
                            sailingState: navigationReadings.tackAlignmentSailingState,
                            tolerance: settingsManager.tackTolerance,
                            rangeMultiplier: 1,
                            trueWindDirection: navigationReadings.windData?.trueWindDirection ?? 0
                        )
                        .frame(height: stripCompactBars ? 34 : 40)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, useBarCardChrome ? 8 : (stripCompactBars ? 3 : 4))
                    }
            }
            .padding(.horizontal, useBarCardChrome ? 8 : 4)
            .padding(.vertical, useBarCardChrome ? 4 : (stripCompactBars ? 3 : 2))

            Group {
                if stripCompactBars {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        barStack
                        Spacer(minLength: 0)
                    }
                } else {
                    barStack
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: stripCompactBars ? .center : .top)
        }
    }
}

#Preview {
    PerformanceView()
        .environment(NMEAParser())
        .environment(SettingsManager())
}
