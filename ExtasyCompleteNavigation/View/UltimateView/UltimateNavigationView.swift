import SwiftUI

struct UltimateNavigationView: View {
    
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(SettingsManager.self) private var settingsManager
    
    var body: some View {
        GeometryReader { geometry in
            let buttonSize = max(geometry.size.width * 0.075, 14) // Button size relative to screen width
            let spacing = geometry.size.width * 0.02   // Spacing relative to screen width
            
            ZStack {
                // Central pseudo-boat illustration
                PseudoBoat()
                    .stroke(lineWidth: 4)
                    .foregroundColor(Color(UIColor.systemGray))
                    .scaleEffect(x: 0.25, y: 0.55, anchor: .center)
                
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
}

struct NavigationButton<Destination: View>: View {
    let systemName: String
    let gradientColors: [Color]
    let buttonSize: CGFloat
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            ZStack {
                // Background with gradient and shadow
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
                
                // Button icon
                Image(systemName: systemName)
                    .foregroundColor(.white)
                    .font(.system(size: buttonSize * 0.5, weight: .bold))
            }
            .buttonStyle(.plain)
        }
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
