import SwiftUI

struct BearingMarkerView: View {
    // The source for the data to be displayed
    @Environment(NMEAParser.self) private var navigationReadings
    let width: CGFloat

    // Persisted values to store the last known state
    @AppStorage("lastKnownBearing") private var lastKnownBearing: Double = 0.0
    @AppStorage("bearingShouldAnimate") private var shouldAnimate: Bool = false

    // State to track the displayed relative bearing
    @State private var displayedRelativeBearing: Double = 0
    @State private var animationDelta: Double = 0 // Tracks the delta for smooth rotation
    @State private var hasValidBearing: Bool = false // Tracks if a valid bearing is available

    // Computed properties for font size
    private var fontSize: CGFloat {
        max(width / 30, 14)
    }

    var body: some View {
        ZStack {
            // Arrow Indicator
            Image(systemName: "arrowtriangle.down.fill")
                .resizable()
                .frame(width: fontSize * 1.7, height: fontSize * 1.7)
                .offset(y: -width / 2.4)
                .foregroundStyle(Color.green)
            
            // Dot Scope Indicator
            Image(systemName: "dot.scope")
                .resizable()
                .frame(width: fontSize, height: fontSize)
                .offset(y: -width / 2.36)
                .foregroundStyle(Color.black)
        }
        .frame(width: width, height: width) // Ensures the ZStack has a square frame
        .rotationEffect(.degrees(animationDelta)) // Use animation delta for rotation
        .animation(shouldAnimate ? .easeInOut(duration: 1) : .none, value: animationDelta) // Smooth rotation
        .onAppear {
            if !hasValidBearing {
                displayedRelativeBearing = lastKnownBearing
                animationDelta = lastKnownBearing
                hasValidBearing = true
                shouldAnimate = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    shouldAnimate = true
                }
            }
        }
        .onDisappear {
            // Store the last known bearing when the view disappears
            lastKnownBearing = displayedRelativeBearing
        }
        .onChange(of: navigationReadings.waypointData?.currentTackRelativeBearing) { _, newValue in
            guard let newValue = newValue else {
                // Handle invalid value (e.g., data loss)
                hasValidBearing = false
                return
            }
            updateBearingRotation(to: newValue)
        }
    }

    // MARK: - Rotation Logic

    private func updateBearingRotation(to newAngle: Double) {
        if !hasValidBearing {
            displayedRelativeBearing = newAngle
            animationDelta = newAngle
            hasValidBearing = true
        } else {
            let shortestDelta = calculateShortestRotation(from: displayedRelativeBearing, to: newAngle)
            animationDelta += shortestDelta
            displayedRelativeBearing = newAngle
        }
    }

    private func calculateShortestRotation(from sourceAngle: Double, to targetAngle: Double) -> Double {
        let delta = (targetAngle - sourceAngle).truncatingRemainder(dividingBy: 360)
        return delta > 180 ? delta - 360 : (delta < -180 ? delta + 360 : delta)
    }
}

// Preview
#Preview {
    GeometryProvider { width, _, _ in
        BearingMarkerView(width: width)
            .environment(NMEAParser())
    }
    .aspectRatio(contentMode: .fit)
}
