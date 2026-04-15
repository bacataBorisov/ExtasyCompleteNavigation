import SwiftUI

struct iPadView: View {
    @Environment(NMEAParser.self) private var navigationReadings

    @State private var lowerInstrumentPanel: Int = 0

    private var isTargetSelected: Bool {
        navigationReadings.gpsData?.isTargetSelected ?? false
    }

    /// Cockpit dashboard (ROADMAP): full-window width — wide landscape shows Performance + Polar together.
    private func showLowerPerformancePolarSideBySide(totalWidth: CGFloat) -> Bool {
        totalWidth >= 1000
    }

    var body: some View {
        GeometryReader { geometry in
            let columnSpacing: CGFloat = 16
            let innerWidth = max(0, geometry.size.width - columnSpacing)
            let leftColumnWidth = innerWidth * 0.45
            let rightColumnWidth = innerWidth * 0.55
            let lowerBandHeight = geometry.size.height * 0.35
            let upperBandHeight = geometry.size.height * 0.65

            HStack(alignment: .top, spacing: columnSpacing) {
                // Left (~45%): Ultimate + lower performance / polar
                VStack(spacing: 0) {
                    NavigationStack {
                        UltimateView()
                            .frame(height: upperBandHeight)
                    }

                    lowerInstrumentBand(
                        height: lowerBandHeight,
                        totalWidth: geometry.size.width
                    )
                }
                .frame(width: leftColumnWidth, height: geometry.size.height, alignment: .top)

                // Right (~55%): Multi + VMG or waypoints
                VStack(spacing: 0) {
                    if isTargetSelected {
                        MultiDisplay()
                            .frame(height: upperBandHeight)
                        NavigationStack {
                            VMGSimpleView(waypointName: navigationReadings.gpsData?.waypointName ?? "Mark Unknown")
                                .frame(height: lowerBandHeight)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        }
                    } else {
                        MultiDisplay()
                            .frame(height: upperBandHeight)
                        NavigationStack {
                            InfoWaypointSection()
                                .frame(height: lowerBandHeight)
                        }
                    }
                }
                .frame(width: rightColumnWidth, height: geometry.size.height, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .animation(.easeInOut(duration: 1), value: isTargetSelected)
    }

    @ViewBuilder
    private func lowerInstrumentBand(height: CGFloat, totalWidth: CGFloat) -> some View {
        let sideBySide = showLowerPerformancePolarSideBySide(totalWidth: totalWidth)

        VStack(spacing: 8) {
            if !sideBySide {
                Picker("Lower panel", selection: $lowerInstrumentPanel) {
                    Text("Performance").tag(0)
                    Text("Polar").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
            }

            Group {
                if sideBySide {
                    HStack(alignment: .top, spacing: 10) {
                        PerformanceView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        PolarInstrumentView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else if lowerInstrumentPanel == 0 {
                    PerformanceView()
                } else {
                    PolarInstrumentView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: height)
    }
}

#Preview {
    iPadView()
        .environment(NMEAParser())
        .environment(SettingsManager())
        .modelContainer(for: [
            Waypoints.self,
        ])
}
