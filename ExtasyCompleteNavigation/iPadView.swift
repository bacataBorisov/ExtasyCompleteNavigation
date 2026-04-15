import SwiftUI

/// iPad cockpit: **Map** (largest share) + **VStack** of **Ultimate** and **Multi** in a square-bounded column.
/// Below: **Performance** (left) and **Waypoints** or **VMG** (right); polar is only in the top stack toggle.
struct iPadView: View {
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(SettingsManager.self) private var settingsManager

    /// Top stack cell: alternate **Ultimate** instruments and **Polar** (same cell size as Ultimate).
    @State private var ultimateColumnShowsPolar = false

    private var isTargetSelected: Bool {
        navigationReadings.gpsData?.isTargetSelected == true
    }

    /// Map width, stack column width, and half-stack height (must not live in `ViewBuilder` — assignment-only `if` breaks the build).
    private func mainRowLayoutMetrics(
        innerWidth: CGFloat,
        mainRowHeight: CGFloat,
        columnGap: CGFloat,
        stackSpacing: CGFloat
    ) -> (mapWidth: CGFloat, stackColumnWidth: CGFloat, panelH: CGFloat) {
        let panelH = max(100, (mainRowHeight - stackSpacing) / 2)
        var stackColumnWidth = min(innerWidth * 0.34, panelH)
        var mapWidth = innerWidth - columnGap - stackColumnWidth
        let minMapFraction: CGFloat = 0.485
        if mapWidth < innerWidth * minMapFraction {
            mapWidth = innerWidth * minMapFraction
            stackColumnWidth = innerWidth - columnGap - mapWidth
            stackColumnWidth = min(stackColumnWidth, panelH)
            mapWidth = innerWidth - columnGap - stackColumnWidth
        }
        return (mapWidth, stackColumnWidth, panelH)
    }

    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = 8
            let columnGap: CGFloat = 10
            let stackSpacing: CGFloat = 6

            let innerWidth = max(0, geometry.size.width - horizontalPadding * 2)

            let secondaryHeight = min(max(geometry.size.height * 0.26, 160), geometry.size.height * 0.34)
            let mainRowHeight = max(geometry.size.height - secondaryHeight - 14, 200)

            let metrics = mainRowLayoutMetrics(
                innerWidth: innerWidth,
                mainRowHeight: mainRowHeight,
                columnGap: columnGap,
                stackSpacing: stackSpacing
            )

            VStack(spacing: 0) {
                HStack(alignment: .bottom, spacing: columnGap) {
                    MapView(iPadLeadingControl: .settingsLink, iPadDashboardBleedMargins: true)
                        .frame(width: metrics.mapWidth, height: mainRowHeight)

                    VStack(spacing: stackSpacing) {
                        NavigationStack {
                            // Center matches `UltimateNavigationView`’s `PseudoBoat` (same square as instruments).
                            ZStack {
                                Group {
                                    if ultimateColumnShowsPolar {
                                        PolarInstrumentView(compactChrome: true, showTWSCaption: false, iPadStackCell: true)
                                    } else {
                                        UltimateView()
                                    }
                                }
                                .frame(width: metrics.stackColumnWidth, height: metrics.panelH)

                                iPadUltimatePolarToggleButton(showsPolar: $ultimateColumnShowsPolar)
                                    .zIndex(1)
                            }
                            .frame(width: metrics.stackColumnWidth, height: metrics.panelH)
                        }
                        .frame(width: metrics.stackColumnWidth, height: metrics.panelH)

                        MultiDisplay()
                            .frame(width: metrics.stackColumnWidth, height: metrics.panelH)
                    }
                    .frame(height: mainRowHeight, alignment: .top)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 6)

                Divider()
                    .padding(.vertical, 4)

                secondaryStrip(height: secondaryHeight, horizontalInset: horizontalPadding)
                    .padding(.bottom, max(8, geometry.safeAreaInsets.bottom))
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .animation(.easeInOut(duration: 0.35), value: isTargetSelected)
        .animation(.easeInOut(duration: 0.28), value: ultimateColumnShowsPolar)
    }

    @ViewBuilder
    private func secondaryStrip(height: CGFloat, horizontalInset: CGFloat) -> some View {
        // Short bar: just above caption text — leaves more room for performance + waypoint.
        let tackRowHeight: CGFloat = 22
        let tackGap: CGFloat = 6
        let tackBottomPad: CGFloat = 10

        GeometryReader { stripGeo in
            let columnGap: CGFloat = 10
            let total = stripGeo.size.width
            let performanceWidth = max(200, (total - columnGap) * 0.56)
            let waypointColumnWidth = max(120, total - columnGap - performanceWidth)

            VStack(spacing: tackGap) {
                HStack(alignment: .top, spacing: columnGap) {
                    NavigationStack {
                        PerformanceView(useBarCardChrome: false, embeddedTackBar: false)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(width: performanceWidth)

                    Divider()

                    NavigationStack {
                        Group {
                            if isTargetSelected {
                                VMGSimpleView(waypointName: navigationReadings.gpsData?.waypointName ?? "Mark")
                            } else {
                                InfoWaypointSection()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(width: waypointColumnWidth)
                }
                .padding(.horizontal, horizontalInset)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

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
                .frame(height: tackRowHeight)
                .frame(maxWidth: .infinity)
            }
            .padding(.bottom, tackBottomPad)
            .frame(width: total, height: stripGeo.size.height, alignment: .top)
        }
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .top)
    }
}

// MARK: - Ultimate ↔ Polar (iPad top cell)

private struct iPadUltimatePolarToggleButton: View {
    @Binding var showsPolar: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.28)) {
                showsPolar.toggle()
            }
        } label: {
            Image(systemName: showsPolar ? "gauge.with.dots.needle.67percent" : "chart.line.uptrend.xyaxis")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
                .shadow(color: .black.opacity(0.18), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(showsPolar ? "Show instruments" : "Show polar diagram")
        .help(showsPolar ? "Switch to instruments" : "Switch to polar")
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
