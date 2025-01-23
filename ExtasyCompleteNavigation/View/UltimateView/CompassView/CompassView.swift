import SwiftUI

struct CompassView: View {
    @Environment(NMEAParser.self) private var navigationReadings

    let width: CGFloat
    let markers = GaugeMarkerCompass.labelSet()
    let geometry: GeometryProxy

    // State to track the displayed heading
    @State private var displayedHeading: Double = 0
    @State private var animationDelta: Double = 0 // Tracks the delta for smooth rotation
    @State private var hasValidHeading: Bool = false // Tracks if a valid heading is available

    // Persisting values
    @AppStorage("lastKnownHeading") private var lastKnownHeading: Double = 0.0
    @AppStorage("compassShouldAnimate") private var shouldAnimate: Bool = false

    var body: some View {
        ZStack {
            ZStack {
                // Compass Circle
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color("dial_gauge_start"), Color("dial_gauge_end")]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: width / 12
                    )
                    .padding(width / 20)
                    .scaleEffect(x: 0.82, y: 0.82)

                // Compass Labels
                ForEach(markers) { marker in
                    CompassLabelView(marker: marker, geometry: geometry)
                        .position(CGPoint(x: width / 2, y: width / 2))
                        .transition(.identity) // Prevent transitions on labels
                }
            }
            // Rotate Compass using the animation delta
            .rotationEffect(.degrees(-animationDelta))
            .animation(shouldAnimate ? .easeInOut(duration: 1) : .none, value: animationDelta)

            // Yellow Indicator (Fixed)
            Text("▼")
                .font(Font.custom("AppleSDGothicNeo-Bold", size: width / 8))
                .position(x: width / 2, y: width / 2)
                .offset(y: -width / 2)
                .foregroundColor(Color(UIColor.systemYellow))
                .scaleEffect(x: 0.82, y: 0.82)
        }
        .onAppear {
            if !hasValidHeading {
                displayedHeading = lastKnownHeading
                animationDelta = lastKnownHeading
                hasValidHeading = true
                shouldAnimate = false // Disable animation for initial load
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    shouldAnimate = true // Enable animation after initial positioning
                }
            }
        }
        .onDisappear {
            // Store the last known heading when the view disappears
            lastKnownHeading = displayedHeading
        }
        .onChange(of: navigationReadings.compassData?.normalizedHeading) { _, newValue in
            guard let newValue = newValue else {
                hasValidHeading = false
                return
            }
            updateCompassRotation(to: newValue)
        }
    }

    // MARK: - Rotation Logic

    private func updateCompassRotation(to newHeading: Double) {
        if !hasValidHeading {
            displayedHeading = newHeading
            animationDelta = newHeading
            hasValidHeading = true
        } else {
            let shortestDelta = calculateShortestRotation(from: displayedHeading, to: newHeading)
            animationDelta += shortestDelta
            displayedHeading = newHeading
        }
    }

    private func calculateShortestRotation(from sourceAngle: Double, to targetAngle: Double) -> Double {
        let delta = (targetAngle - sourceAngle).truncatingRemainder(dividingBy: 360)
        return delta > 180 ? delta - 360 : (delta < -180 ? delta + 360 : delta)
    }
}

// MARK: - Preview
#Preview {
    GeometryProvider { width, geometry, _ in
        CompassView(width: width, geometry: geometry)
            .environment(NMEAParser())
    }
    .aspectRatio(contentMode: .fit)
}
