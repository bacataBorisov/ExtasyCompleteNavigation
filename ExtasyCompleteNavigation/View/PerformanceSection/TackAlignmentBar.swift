import SwiftUI

struct TackAlignmentBar: View {
    let currentHeading: Double // Boat's current heading or COG
    let optimalUpTWA: Double // Optimal Upwind TWA
    let optimalDnTWA: Double // Optimal Downwind TWA
    let sailingState: String // "Upwind" or "Downwind"
    var tolerance: Double // Tolerance range in degrees (e.g., ±15°)
    var rangeMultiplier: Double = 1.0 // Setting to extend or shrink the range
    let trueWindDirection: Double // True Wind Direction (TWD)

    // Use Double instead of CGFloat to work with @AppStorage
    @AppStorage("tackAlignmentOffset") private var storedOffset: Double = 0.0
    @AppStorage("tackAlignmentShouldAnimate") private var shouldAnimate: Bool = false
    @State private var animatedOffset: CGFloat = 0.0

    private var starboardTackTarget: Double {
        let optimalTWA = sailingState == "Upwind" ? optimalUpTWA : optimalDnTWA
        return normalizeAngle(trueWindDirection - optimalTWA)
    }

    private var portTackTarget: Double {
        let optimalTWA = sailingState == "Upwind" ? optimalUpTWA : optimalDnTWA
        return normalizeAngle(trueWindDirection + optimalTWA)
    }

    private var isPortTack: Bool {
        let portOffset = abs(normalizeAngleTo180(currentHeading - portTackTarget))
        let starboardOffset = abs(normalizeAngleTo180(currentHeading - starboardTackTarget))
        return portOffset < starboardOffset
    }

    var body: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width

            ZStack {
                // Alignment Bar with Gradient
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.red.opacity(0.1), location: 0),
                                .init(color: Color.red.opacity(0.3), location: 0.25),
                                .init(color: Color.green.opacity(0.8), location: 0.5),
                                .init(color: Color.green.opacity(0.3), location: 0.75),
                                .init(color: Color.mint.opacity(0.1), location: 1)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(maxHeight: .infinity)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)

                // Current Heading Indicator
                Rectangle()
                    .fill(Color.orange)
                    .frame(maxHeight: .infinity)
                    .frame(width: 3)
                    .offset(x: animatedOffset, y: 0)
                    .animation(shouldAnimate ? .interpolatingSpring(stiffness: 80, damping: 15) : .none, value: animatedOffset)

                // Debug Info Overlay
//                VStack {
//                    Text("Current Heading: \(String(format: "%.1f", currentHeading))°")
//                    Text("Optimal Port Tack: \(String(format: "%.1f", portTackTarget))°")
//                    Text("Optimal Starboard Tack: \(String(format: "%.1f", starboardTackTarget))°")
//                }
//                .foregroundColor(.white)
//                .font(.caption)
//                .padding()
//                .background(Color.black.opacity(0.6).cornerRadius(8))
//                .padding(.top, 50)
            }
            .onAppear {
                let newOffset = xOffset(for: currentHeading, barWidth: barWidth)
                animatedOffset = CGFloat(storedOffset) // Restore last known offset
                shouldAnimate = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    animatedOffset = newOffset
                    storedOffset = Double(newOffset)  // Save the new position as Double
                    shouldAnimate = true
                }
            }
            .onChange(of: currentHeading) { newValue, _ in
                let newOffset = xOffset(for: newValue, barWidth: barWidth)
                animatedOffset = newOffset
                storedOffset = Double(newOffset)  // Persist new value
            }
        }
    }

    private func xOffset(for heading: Double, barWidth: CGFloat) -> CGFloat {
        let targetHeading = isPortTack ? portTackTarget : starboardTackTarget
        let offset = normalizeAngleTo180(heading - targetHeading)
        let scaledOffset = offset / (tolerance * rangeMultiplier)
        let effectiveOffset = max(min(scaledOffset, 1), -1)
        let pixelOffset = CGFloat(effectiveOffset) * (barWidth / 2)
        return pixelOffset
    }

    private func normalizeAngleTo180(_ angle: Double) -> Double {
        var normalized = angle.truncatingRemainder(dividingBy: 360)
        if normalized > 180 { normalized -= 360 }
        if normalized < -180 { normalized += 360 }
        return normalized
    }

    private func normalizeAngle(_ angle: Double) -> Double {
        return angle.truncatingRemainder(dividingBy: 360) + (angle < 0 ? 360 : 0)
    }
}

// MARK: - Preview
#Preview {
    VStack {
        TackAlignmentBar(
            currentHeading: 90.0,
            optimalUpTWA: 45.0,
            optimalDnTWA: 135.0,
            sailingState: "Upwind",
            tolerance: 15.0,
            rangeMultiplier: 1.5,
            trueWindDirection: 135.0
        )
        .frame(height: 50)
        .padding()
    }
}
