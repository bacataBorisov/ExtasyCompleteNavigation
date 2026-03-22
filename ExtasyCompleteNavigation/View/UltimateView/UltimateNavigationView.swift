import SwiftUI

struct UltimateNavigationView: View {
    
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(SettingsManager.self) private var settingsManager
    @Environment(UDPHandler.self) private var udpHandler
    @State private var showSensorDetail = false

    var body: some View {
        GeometryReader { geometry in
            let buttonSize = max(geometry.size.width * 0.075, 14)
            let spacing = geometry.size.width * 0.02
            
            ZStack {
                // Central pseudo-boat illustration
                PseudoBoat()
                    .stroke(lineWidth: 4)
                    .foregroundColor(Color(UIColor.systemGray))
                    .scaleEffect(x: 0.25, y: 0.55, anchor: .center)
                
                // Connection status dot just inside the bow
                connectionStatusDot
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2 - geometry.size.height * 0.55 / 2 + geometry.size.height * 0.12
                    )
                
                // Navigation buttons in a vertical stack
                VStack(spacing: spacing) {
                    NavigationButton(
                        systemName: "gear",
                        gradientColors: [Color.gray.opacity(0.6), Color.black],
                        buttonSize: buttonSize,
                        destination: RoundedBackgroundView(content: {
                            SettingsMenuView()
                        })
                    )
                    if DeviceType.isIPad {
                        NavigationButton(
                            systemName: "map",
                            gradientColors: [Color.blue.opacity(0.6), Color.cyan],
                            buttonSize: buttonSize,
                            destination: MapView()
                        )
                    }
                    
                    //                    if DeviceType.isIPhone {
                    //                        NavigationButton(
                    //                            systemName: "scope",
                    //                            gradientColors: [Color.green.opacity(0.6), Color.teal],
                    //                            buttonSize: buttonSize,
                    //                            destination: WaypointListView()
                    //                        )
                    //                    }
                }
                .frame(maxHeight: .infinity, alignment: .center) // Keep buttons pinned near the top center
                //.padding(.top, geometry.size.height * 0.2) // Adjust vertical position of the buttons
            }
        }
    }

    // MARK: - Connection Status Dot
    private var connectionStatusDot: some View {
        let sensorStatus = navigationReadings.dataStatus
        let connState = udpHandler.connectionState
        let color: Color = {
            if connState == .error || connState == .disconnected { return .red }
            if connState == .reconnecting || connState == .connecting { return .orange }
            if sensorStatus.overallHealthy { return .green }
            if sensorStatus.anyActive { return .yellow }
            return .red
        }()
        return Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .shadow(color: color.opacity(0.8), radius: 5)
            .popover(isPresented: $showSensorDetail) { sensorDetailView }
            .onTapGesture { showSensorDetail = true }
    }

    private var sensorDetailView: some View {
        let status = navigationReadings.dataStatus
        let connState = udpHandler.connectionState
        return VStack(alignment: .leading, spacing: 12) {
            Text("Connection")
                .font(.headline)
            connectionRow(state: connState)
            Divider()
            Text("Sensors")
                .font(.headline)
            sensorRow("Wind", status: status.wind)
            sensorRow("GPS", status: status.gps)
            sensorRow("Depth/Speed", status: status.hydro)
            sensorRow("Compass", status: status.compass)
        }
        .padding()
        .presentationCompactAdaptation(.popover)
    }

    private func connectionRow(state: ConnectionState) -> some View {
        HStack {
            Circle().fill(connectionColor(for: state)).frame(width: 8, height: 8)
            Text("UDP").font(.subheadline)
            Spacer()
            Text(connectionLabel(for: state)).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func connectionColor(for state: ConnectionState) -> Color {
        switch state {
        case .connected: return .green
        case .connecting, .reconnecting: return .orange
        case .disconnected, .error: return .red
        }
    }

    private func connectionLabel(for state: ConnectionState) -> String {
        switch state {
        case .connected: return "Connected"
        case .connecting: return "Connecting…"
        case .reconnecting: return "Reconnecting…"
        case .disconnected: return "Disconnected"
        case .error: return "Error"
        }
    }

    private func sensorRow(_ name: String, status: SensorStatus) -> some View {
        HStack {
            Circle()
                .fill(status == .active ? .green : (status == .stale ? .yellow : .red))
                .frame(width: 8, height: 8)
            Text(name).font(.subheadline)
            Spacer()
            Text(status.rawValue.capitalized).font(.caption).foregroundStyle(.secondary)
        }
    }
}  // end UltimateNavigationView

struct NavigationButton<Destination: View>: View {
    let systemName: String
    let gradientColors: [Color]
    let buttonSize: CGFloat
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            ZStack {
                RoundedRectangle(cornerRadius: buttonSize / 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: buttonSize, height: buttonSize)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                
                Image(systemName: systemName)
                    .foregroundColor(.white)
                    .font(.system(size: buttonSize * 0.5, weight: .bold))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    GeometryProvider { width, _, _ in
        UltimateNavigationView()
            .environment(NMEAParser())
            .environment(SettingsManager())
            .background(Color.white)
    }
    .aspectRatio(contentMode: .fit)
}
