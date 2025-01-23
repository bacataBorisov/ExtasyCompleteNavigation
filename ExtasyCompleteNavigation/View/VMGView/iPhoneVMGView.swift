import SwiftUI
import CoreLocation

struct iPhoneVMGView: View {
    @Environment(NMEAParser.self) private var navigationReadings
    var waypointName: String
    @State private var cardGradient: [Color] = [Color.teal.opacity(0.7), Color.blue.opacity(0.7)]
    @State private var showWarningView = false
    @State private var isWaypointListPresented = false

    
    var body: some View {
        NavigationStack {
            
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height) // Ensure 1:1 aspect ratio
                let iconSize = size * 0.08
                let valueFont = Font.system(size: size * 0.07, weight: .bold)
                let messageFont = Font.system(size: size * 0.09, weight: .semibold)
                
                ZStack {
                    VStack(spacing: 12) { // Adjust spacing for consistency
                        // MARK: - Waypoint Name
                        
                        HStack {

                            Button(action: {
                                isWaypointListPresented.toggle()
                            }) {
                                Image(systemName: "dot.scope")
                                    .foregroundColor(.white)
                                    .frame(width: size * 0.15, height: size * 0.15)
                            }
                            .sheet(isPresented: $isWaypointListPresented) {
                                WaypointListView()
                                    .presentationDetents([.medium, .large]) // Allows lower half presentation
                                    .presentationDragIndicator(.visible) // Optional drag-to-dismiss indicator
                            }
                            Spacer()
                            Button(action: deselectWaypoint) {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.white)
                                .frame(width: size * 0.15, height: size * 0.15)                        }
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
                        
                        Spacer()
                        // MARK: - Waypoint Info
                        HStack(spacing: 8) {
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
                        // MARK: - Warning or Tack Info
                        if navigationReadings.waypointData?.isVMCNegative ?? false {
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
                                .padding(.horizontal)
                                .transition(.asymmetric(
                                    insertion: .opacity,
                                    removal: .opacity
                                ))
                            Spacer()
                        } else {
                            
                            // MARK: - Row #2 - Current Tack Information
                            
                            let sailingState = navigationReadings.vmgData?.sailingState
                            
                            HStack(spacing: 12) {
                                infoColumn(icon: "arrow.uturn.up",
                                           value: "\(String(format: "%.1f", (navigationReadings.waypointData?.tackDistance ?? 0))) NM",
                                           iconSize: iconSize,
                                           valueFont: valueFont
                                )
                                infoColumn(icon: "timer",
                                           value: formatTripDuration(navigationReadings.waypointData?.tackDuration),
                                           iconSize: iconSize,
                                           valueFont: valueFont
                                )
                                infoColumn(icon: (sailingState == "Upwind" ? "arrow.down" : "arrow.up"),
                                           value: navigationReadings.vmgData?.sailingState ?? "N/A",
                                           iconSize: iconSize,
                                           valueFont: valueFont
                                )
                            }
                            Spacer()
                            // MARK: - Row #3 - Opposite Tack Information
                            
                            let oppositeSailingState = navigationReadings.waypointData?.oppositeTackState
                            
                            HStack(spacing: 12) {
                                infoColumn(icon: "arrow.2.squarepath",
                                           value: "\(String(format: "%.1f", (navigationReadings.waypointData?.distanceOnOppositeTack ?? 0))) NM",
                                           iconSize: iconSize,
                                           valueFont: valueFont
                                )
                                infoColumn(icon: "timer",
                                           value: formatTripDuration(navigationReadings.waypointData?.tripDurationOnOppositeTack),
                                           iconSize: iconSize,
                                           valueFont: valueFont
                                )
                                infoColumn(icon: (oppositeSailingState == "Upwind" ? "arrow.down" : "arrow.up"),
                                           value: navigationReadings.waypointData?.oppositeTackState ?? "N/A",
                                           iconSize: iconSize,
                                           valueFont: valueFont
                                )
                            }
                            Spacer()
                        }
                    }
                    .padding([.leading, .trailing], 5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: cardGradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .onChange(of: navigationReadings.waypointData?.currentTackRelativeBearing) { _, _ in
                        handleTackLogic()
                    }
                }
            }
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
        navigationReadings.waypointProcessor.resetWaypointCalculations()
        navigationReadings.gpsProcessor.gpsData.markerCoordinate = nil
        navigationReadings.gpsProcessor.disableMarker()
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

