import SwiftUI
import CoreLocation

struct VMGSimpleView: View {
    @Environment(NMEAParser.self) private var navigationReadings
    var waypointName: String
    @State private var cardGradient: [Color] = [Color.teal.opacity(0.7), Color.blue.opacity(0.7)]
    let sectionPadding: CGFloat = 8
    @State private var showWarningView = false
    
    var body: some View {
        
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let totalHeight = geometry.size.height
            let iconSize = totalHeight * 0.08
            let valueFont = Font.system(size: totalHeight * 0.08, weight: .bold)
            let labelFont = Font.system(size: totalHeight * 0.06)
            let iconFont = Font.system(size: totalHeight * 0.1)
            let messageFont = Font.system(size: totalHeight * 0.1, weight: .semibold)
            
            ZStack {
                // Main View
                VStack(spacing: sectionPadding) {
                    // MARK: - Top Row: Waypoint Name and Buttons
                    HStack {
                        NavigationLink(destination: WaypointListView()) {
                            Image(systemName: "dot.scope")
                                .foregroundColor(.white)
                                .font(iconFont)
                        }
                        Spacer()
                        Text(waypointName)
                            .font(Font.system(size: totalHeight * 0.09, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .shadow(color: Color.black.opacity(0.8), radius: 6, x: 2, y: 2)
                        Spacer()
                        Button(action: deselectWaypoint) {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.white)
                                .font(iconFont)
                        }
                    }
                    .padding()
                    
                    // MARK: - Waypoint Info
                    HStack(spacing: sectionPadding) {
                        infoColumn(
                            icon: "flag.checkered",
                            value: "\(String(format: "%.1f", (navigationReadings.waypointData?.distanceToMark ?? 0) / 1852)) NM",
                            iconSize: iconSize,
                            valueFont: valueFont
                        )
                        infoColumn(
                            icon: "timer",
                            value: formatTripDuration(navigationReadings.waypointData?.tripDurationToWaypoint),
                            iconSize: iconSize,
                            valueFont: valueFont
                        )
                        infoColumn(
                            icon: "hourglass",
                            value: formatETA(navigationReadings.waypointData?.etaToWaypoint),
                            iconSize: iconSize,
                            valueFont: valueFont
                        )
                    }
                    
                    Spacer()
                    // Show warning message if VMC is negative
                    if navigationReadings.waypointData?.isVMCNegative ?? false {
                        VStack {
                            Text("Moving away from waypoint")
                                .font(messageFont)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.8))
                                        .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 2)
                                )
                                .padding(.horizontal, sectionPadding)
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity), // Slide in from bottom and fade in
                            removal: .move(edge: .top).combined(with: .opacity) // Slide out to top and fade out
                        ))
                    } else {
                        
                        // MARK: - Tacks Info
                        HStack(spacing: sectionPadding) {
                            tackInfo(
                                title: navigationReadings.vmgData?.sailingState ?? "N/A",
                                icon: "arrowtriangle.up.circle",
                                distance: navigationReadings.waypointData?.tackDistance ?? 0,
                                duration: navigationReadings.waypointData?.tackDuration,
                                iconSize: iconSize,
                                valueFont: valueFont,
                                labelFont: labelFont
                            )
                            Spacer()
                            tackInfo(
                                title: navigationReadings.waypointData?.oppositeTackState ?? "N/A",
                                icon: "arrow.2.squarepath",
                                distance: navigationReadings.waypointData?.distanceOnOppositeTack ?? 0,
                                duration: navigationReadings.waypointData?.tripDurationOnOppositeTack,
                                iconSize: iconSize,
                                valueFont: valueFont,
                                labelFont: labelFont
                            )
                        }
                    }
                    
                    
                    Spacer()
                }
                .frame(width: totalWidth, height: totalHeight)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: cardGradient),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                    .padding(.bottom, sectionPadding)
                    .padding(.trailing, sectionPadding)
                )
                
                .onChange(of: navigationReadings.waypointData?.currentTackRelativeBearing) { _, _ in
                    handleTackLogic()
                }
            }
            .animation(.easeInOut(duration: 0.8), value: showWarningView)
        }
        
    }
    
    // MARK: - Info Column
    private func infoColumn(icon: String, value: String, iconSize: CGFloat, valueFont: Font) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(.white)
            Text(value)
                .font(valueFont)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Tack Info
    private func tackInfo(title: String, icon: String, distance: Double, duration: Double?, iconSize: CGFloat, valueFont: Font, labelFont: Font) -> some View {
        VStack(spacing: sectionPadding) {
            Text(title)
                .font(labelFont)
                .foregroundColor(.white.opacity(0.7))
            HStack {
                infoColumn(
                    icon: icon,
                    value: "\(String(format: "%.1f", distance)) NM",
                    iconSize: iconSize,
                    valueFont: valueFont
                )
                infoColumn(
                    icon: "timer",
                    value: formatTripDuration(duration),
                    iconSize: iconSize,
                    valueFont: valueFont
                )
            }
        }
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
    
    // MARK: - Button Actions
    private func deselectWaypoint() {
        navigationReadings.waypointProcessor.resetWaypointCalculations()
        navigationReadings.gpsProcessor.gpsData.markerCoordinate = nil
        navigationReadings.gpsProcessor.disableMarker()
    }
    
    // MARK: - Handle Tack Logic
    private func handleTackLogic() {
        guard let relativeBearing = navigationReadings.waypointData?.currentTackRelativeBearing else { return }
        
        // Normalize the relative bearing to the range -180° to 180°
        var normalizedBearing = relativeBearing.truncatingRemainder(dividingBy: 360)
        if normalizedBearing > 180 { normalizedBearing -= 360 }
        if normalizedBearing < -180 { normalizedBearing += 360 }
        
        //debugLog("Normalized Bearing: \(normalizedBearing)")
        
        // Handle logic based on the normalized bearing
        if abs(normalizedBearing) >= 85 && abs(normalizedBearing) <= 95 {
            cardGradient = [Color.orange.opacity(0.8), Color.pink.opacity(0.8)]
        } else if abs(normalizedBearing) > 90 {
            showWarningView = true
        } else {
            cardGradient = [Color.teal.opacity(0.7), Color.blue.opacity(0.7)]
        }
    }
}

#Preview {
    VMGSimpleView(waypointName: "Balchik")
        .environment(NMEAParser())
        .background(Color.black.edgesIgnoringSafeArea(.all))
}
