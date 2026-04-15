import SwiftUI
import CoreLocation

struct iPhoneVMGView: View {
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(SettingsManager.self) private var settingsManager
    var waypointName: String
    @State private var cardGradient: [Color] = [Color.teal.opacity(0.7), Color.blue.opacity(0.7)] // unused during debug phase
    @State private var showWarningView = false
    @State private var isWaypointListPresented = false

    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                let valueFont = Font.system(size: size * 0.07, weight: .bold)
                let labelFont = Font.system(size: size * 0.045, weight: .regular)
                let headerFont = Font.system(size: size * 0.05, weight: .semibold)
                let messageFont = Font.system(size: size * 0.09, weight: .semibold)

                ZStack {
                    VStack(spacing: 0) {

                        // MARK: - Header
                        HStack {
                            Button(action: { isWaypointListPresented.toggle() }) {
                                Image(systemName: "dot.scope")
                                    .foregroundColor(.white)
                                    .frame(width: size * 0.15, height: size * 0.15)
                            }
                            .buttonStyle(.plain)
                            .sheet(isPresented: $isWaypointListPresented) {
                                WaypointListView()
                                    .presentationDetents([.medium, .large])
                                    .presentationDragIndicator(.visible)
                            }
                            Spacer()
                            Button(action: deselectWaypoint) {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.white)
                                    .frame(width: size * 0.15, height: size * 0.15)
                            }
                            .buttonStyle(.plain)
                        }
                        .overlay(
                            Text(waypointName)
                                .font(Font.system(size: size * 0.07, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .shadow(color: Color.black.opacity(0.8), radius: 6, x: 2, y: 2)
                        )
                        .padding(.top)
                        .padding(.bottom, size * 0.04)

                        // MARK: - Column Headers
                        tackRowHeader(labels: ("DIST", "TIME", "ETA / STATE"), headerFont: labelFont)
                            .padding(.bottom, 2)

                        Divider().background(Color.white.opacity(0.3))

                        // MARK: - Row 1: Direct to Waypoint
                        tackRow(
                            label: "DIRECT",
                            col1: "\(settingsManager.formatDistance(meters: navigationReadings.waypointData?.distanceToMark ?? 0)) \(settingsManager.distanceAbbreviation)",
                            col2: formatTripDuration(navigationReadings.waypointData?.tripDurationToWaypoint),
                            col3: formatETA(navigationReadings.waypointData?.etaToWaypoint),
                            stateColor: .white,
                            headerFont: headerFont,
                            valueFont: valueFont,
                            labelFont: labelFont
                        )

                        Divider().background(Color.white.opacity(0.3))

                        // MARK: - Warning or Tack Rows
                        if navigationReadings.waypointData?.isVMCNegative ?? false {
                            Spacer()
                            Text("Moving away from waypoint")
                                .font(messageFont)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.8))
                                )
                                .padding(.horizontal)
                            Spacer()
                        } else {
                            // Determine PORT / STBD from TWA (0-360°):
                            // 0-180° = wind from starboard side → Starboard tack/gybe
                            // Current leg: tack derived from boat's live TWA (> 180° = wind on port).
                            let rawTWA = (navigationReadings.windData?.trueWindAngle ?? 0)
                            let normalizedTWA = (rawTWA + 360).truncatingRemainder(dividingBy: 360)
                            let isPortTack = normalizedTWA > 180
                            let tack1Label = isPortTack ? "PORT" : "STBD"
                            let tack1Color = TacticalPalette.tackLabelColor(for: tack1Label)

                            // Next leg: tack derived from the second-leg heading vs TWD (computed in processor).
                            // This is independent of the current tack — e.g. on a downwind leg the wind
                            // can still come from the port side even though the boat just tacked.
                            let nextLegTackStr = navigationReadings.waypointData?.nextLegTack ?? "—"
                            let nextLabel: String = nextLegTackStr == "Port" ? "PORT" : (nextLegTackStr == "Starboard" ? "STBD" : "—")
                            let nextColor: Color = nextLabel == "—" ? .white.opacity(0.55) : TacticalPalette.tackLabelColor(for: nextLabel)

                            // CURRENT subtitle = live boat mode (TWA vs polar threshold), same as debug “Boat”.
                            // `waypointApproachState` is mark-vs-wind only; it can say Downwind while you
                            // are close-hauled (e.g. AoM 95° vs 93° threshold) — wrong label for this row.
                            let currentLegMode = navigationReadings.vmgData?.sailingState
                                ?? navigationReadings.waypointData?.waypointApproachState
                                ?? "—"
                            let currentLegModeColor: Color = {
                                switch currentLegMode {
                                case "Upwind": return .cyan
                                case "Downwind": return .orange
                                default: return .white.opacity(0.55)
                                }
                            }()

                            // MARK: - Row 2: Current tack leg (boat → tack point)
                            // col3 = PORT/STBD (which tack), col3Sub = UPWIND/DOWNWIND (live boat mode)
                            tackRow(
                                label: "CURRENT",
                                col1: "\(settingsManager.formatDistanceFromNM(navigationReadings.waypointData?.tackDistance ?? 0)) \(settingsManager.distanceAbbreviation)",
                                col2: formatTripDuration(navigationReadings.waypointData?.tackDuration),
                                col3: tack1Label,
                                col3Sub: currentLegMode.uppercased(),
                                col3SubColor: currentLegModeColor,
                                stateColor: tack1Color,
                                headerFont: headerFont,
                                valueFont: valueFont,
                                labelFont: labelFont
                            )

                            Divider().background(Color.white.opacity(0.3))

                            // MARK: - Row 3: Second tack leg (tack point → mark)
                            // nextLegSailingState is computed from the INTERSECTION's bearing
                            // to the mark, not from the boat's current position — so it correctly
                            // reflects what the boat will actually sail on the second leg.
                            let nextLegState = navigationReadings.waypointData?.nextLegSailingState
                                ?? navigationReadings.waypointData?.waypointApproachState
                                ?? "—"
                            let nextLegStateColor: Color = nextLegState == "Upwind" ? .cyan : .orange
                            tackRow(
                                label: "NEXT",
                                col1: "\(settingsManager.formatDistanceFromNM(navigationReadings.waypointData?.distanceOnOppositeTack ?? 0)) \(settingsManager.distanceAbbreviation)",
                                col2: formatTripDuration(navigationReadings.waypointData?.tripDurationOnOppositeTack),
                                col3: nextLabel,
                                col3Sub: nextLegState.uppercased(),
                                col3SubColor: nextLegStateColor,
                                stateColor: nextColor,
                                headerFont: headerFont,
                                valueFont: valueFont,
                                labelFont: labelFont
                            )

                            Divider().background(Color.white.opacity(0.3))

                            // MARK: - Debug Row
                            debugRow(size: size, labelFont: labelFont)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(red: 0.05, green: 0.12, blue: 0.20))
                    .onChange(of: navigationReadings.waypointData?.currentTackRelativeBearing) { _, _ in
                        handleTackLogic()
                    }
                }
            }
        }
    }

    // MARK: - Column Header Row
    private func tackRowHeader(labels: (String, String, String), headerFont: Font) -> some View {
        HStack {
            Text(labels.0)
                .font(headerFont)
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity)
            Text(labels.1)
                .font(headerFont)
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity)
            Text(labels.2)
                .font(headerFont)
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Data Row
    /// col3Sub: optional second line below col3 (smaller, different color).
    /// Used to show both tack (PORT/STBD) and sailing mode (UPWIND/DOWNWIND) together.
    private func tackRow(
        label: String,
        col1: String, col2: String, col3: String,
        col3Sub: String? = nil, col3SubColor: Color = .white.opacity(0.6),
        stateColor: Color,
        headerFont: Font, valueFont: Font, labelFont: Font
    ) -> some View {
        HStack(alignment: .center) {
            // Row label
            Text(label)
                .font(labelFont)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 50, alignment: .leading)

            // Distance
            Text(col1)
                .font(valueFont)
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .frame(maxWidth: .infinity)

            // Duration
            Text(col2)
                .font(valueFont)
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .frame(maxWidth: .infinity)

            // Tack + optional sailing-mode subtitle
            VStack(spacing: 2) {
                Text(col3)
                    .font(valueFont)
                    .foregroundColor(stateColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                if let sub = col3Sub {
                    Text(sub)
                        .font(labelFont)
                        .foregroundColor(col3SubColor)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Debug Row
    @ViewBuilder
    private func debugRow(size: CGFloat, labelFont: Font) -> some View {
        let rawTWA = navigationReadings.windData?.trueWindAngle
        let threshold = navigationReadings.vmgData?.sailingStateLimit
        // "Boat" = current TWA-based state; "Mark" = bearing-to-mark state (stable vs heading changes)
        let boatState = navigationReadings.vmgData?.sailingState ?? "—"
        let markState = navigationReadings.waypointData?.waypointApproachState ?? "—"
        let optUp = navigationReadings.vmgData?.optimalUpTWA
        let optDn = navigationReadings.vmgData?.optimalDnTWA

        VStack(spacing: 2) {
            HStack(spacing: 8) {
                debugChip(label: "TWA", value: rawTWA.map { String(format: "%.1f°", $0) } ?? "—")
                debugChip(label: "Thresh", value: threshold.map { String(format: "%.0f°", $0) } ?? "—")
                debugChip(label: "Boat", value: boatState)
            }
            HStack(spacing: 8) {
                debugChip(label: "OptUp", value: optUp.map { String(format: "%.1f°", $0) } ?? "—")
                debugChip(label: "OptDn", value: optDn.map { String(format: "%.1f°", $0) } ?? "—")
                debugChip(label: "Mark", value: markState)
            }
            HStack(spacing: 8) {
                debugChip(label: "VMC", value: navigationReadings.waypointData?.currentTackVMC.map { String(format: "%.2f kn", $0) } ?? "—")
                let bearing = navigationReadings.waypointData?.trueMarkBearing
                debugChip(label: "Brg", value: bearing.map { String(format: "%.0f°", $0) } ?? "—")
                let angleToMark = rawTWA.flatMap { twa -> Double? in
                    guard let twdRaw = navigationReadings.windData?.trueWindDirection,
                          let brg = navigationReadings.waypointData?.trueMarkBearing else { return nil }
                    return abs(((brg - twdRaw) + 540).truncatingRemainder(dividingBy: 360) - 180)
                }
                debugChip(label: "AoM", value: angleToMark.map { String(format: "%.0f°", $0) } ?? "—")
            }
        }
        .padding(.vertical, 6)
        .font(Font.system(size: size * 0.038, weight: .regular, design: .monospaced))
    }

    private func debugChip(label: String, value: String) -> some View {
        HStack(spacing: 3) {
            Text(label + ":")
                .foregroundColor(.white.opacity(0.55))
            Text(value)
                .foregroundColor(.yellow)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .background(Color.black.opacity(0.2))
        .cornerRadius(4)
    }
    
    // MARK: - Helper Functions
    private func formatTripDuration(_ eta: Double?) -> String {
        guard let eta = eta, eta.isFinite, eta >= 0 else { return "-" }
        let totalSeconds = Int(eta * 3600)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
    
    private func formatETA(_ eta: Date?) -> String {
        guard let eta = eta else { return "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: eta)
    }
    
    // MARK: - Tack Logic
    private func handleTackLogic() {
        guard let relativeBearing = navigationReadings.waypointData?.currentTackRelativeBearing else { return }
        let normalizedBearing = (relativeBearing + 360).truncatingRemainder(dividingBy: 360)
        if abs(normalizedBearing - 90) <= 5 || abs(normalizedBearing - 270) <= 5 {
            cardGradient = [Color.orange.opacity(0.8), Color.pink.opacity(0.8)]
        } else if normalizedBearing > 90 && normalizedBearing < 270 {
            showWarningView = true
        } else {
            cardGradient = [Color.teal.opacity(0.7), Color.blue.opacity(0.7)]
        }
    }
    // MARK: - Button Actions
    private func deselectWaypoint() {
        navigationReadings.deselectWaypoint()
    }
}

extension NMEAParser {
    static func mockVMCNegative() -> NMEAParser {
        let parser = NMEAParser()
        
        // Set only the VMC negative flag for preview testing
        parser.waypointData = WaypointData(isVMCNegative: true)
        
        return parser
    }
}


#Preview("VMC Negative") {
    GeometryProvider {width, geomtry, height in
        VStack {
            Spacer()
            iPhoneVMGView(waypointName: "Balchik")
                .environment(NMEAParser.mockVMCNegative())
                .background(Color.black.edgesIgnoringSafeArea(.all))
                .frame(height: height/2)
        }
        
    }
}

#Preview("VMC Normal") {
    GeometryProvider {width, geomtry, height in
        VStack {
            Spacer()
            iPhoneVMGView(waypointName: "Balchik")
                .environment(NMEAParser())
                .background(Color.black.edgesIgnoringSafeArea(.all))
                .frame(height: height/2)
        }
        
        
    }
}

