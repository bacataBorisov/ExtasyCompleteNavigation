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
            /// Map flush to the leading edge; small inset on the trailing screen edge only.
            let leadingInset: CGFloat = 0
            let trailingInset: CGFloat = 8
            /// Breathing room between map and Ultimate / Multi column (not flush).
            let columnGap: CGFloat = 8
            let stackSpacing: CGFloat = 6

            let innerWidth = max(0, geometry.size.width - leadingInset - trailingInset)

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
                    MapView(iPadLeadingControl: .settingsLink)
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
                .padding(.leading, leadingInset)
                .padding(.trailing, trailingInset)
                .padding(.top, 6)

                Divider()
                    .padding(.top, 0)
                    .padding(.bottom, 4)

                secondaryStrip(height: secondaryHeight, horizontalLeading: leadingInset, horizontalTrailing: trailingInset)
                    .padding(.bottom, 0)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .animation(.easeInOut(duration: 0.35), value: isTargetSelected)
        .animation(.easeInOut(duration: 0.28), value: ultimateColumnShowsPolar)
    }

    @ViewBuilder
    private func secondaryStrip(height: CGFloat, horizontalLeading: CGFloat, horizontalTrailing: CGFloat) -> some View {
        // Short bar: flush to bottom of dashboard (no extra strip padding — avoids white gap).
        let tackRowHeight: CGFloat = 22
        let tackGap: CGFloat = 6

        GeometryReader { stripGeo in
            let total = stripGeo.size.width
            let inner = max(0, total - horizontalLeading - horizontalTrailing)
            let midlineWidth: CGFloat = 2
            let columnWidth = max(0, (inner - midlineWidth) / 2)
            /// Avoid `maxHeight: .infinity` in a `VStack` above a fixed tack row — it can confuse
            /// layout and leave a dead band / clip `PerformanceView`’s `GeometryReader` stack.
            let performanceBlockHeight = max(0, stripGeo.size.height - tackGap - tackRowHeight)

            VStack(spacing: tackGap) {
                HStack(alignment: .top, spacing: 0) {
                    NavigationStack {
                        PerformanceView(useBarCardChrome: false, embeddedTackBar: false)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(width: columnWidth)

                    Rectangle()
                        .fill(TacticalPalette.cockpitStripMidline)
                        .frame(width: midlineWidth)
                        .frame(maxHeight: .infinity)
                        .accessibilityLabel("Performance and waypoint column divider")

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
                    .frame(width: columnWidth)
                }
                .padding(.leading, horizontalLeading)
                .padding(.trailing, horizontalTrailing)
                .frame(maxWidth: .infinity)
                .frame(height: performanceBlockHeight, alignment: .top)

                // Same horizontal inset as the row above so the bar centre matches the column midline.
                TackAlignmentBar(
                    currentHeading: navigationReadings.compassData?.normalizedHeading ?? 0,
                    optimalUpTWA: navigationReadings.vmgData?.optimalUpTWA ?? 0,
                    optimalDnTWA: navigationReadings.vmgData?.optimalDnTWA ?? 0,
                    sailingState: navigationReadings.tackAlignmentSailingState,
                    tolerance: settingsManager.tackTolerance,
                    rangeMultiplier: 1,
                    trueWindDirection: navigationReadings.windData?.trueWindDirection ?? 0
                )
                .frame(height: tackRowHeight)
                .padding(.leading, horizontalLeading)
                .padding(.trailing, horizontalTrailing)
                .frame(maxWidth: .infinity)
            }
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
