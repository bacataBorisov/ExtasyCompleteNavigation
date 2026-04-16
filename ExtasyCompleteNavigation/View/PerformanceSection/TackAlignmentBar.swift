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

    private var activeOptimalTWA: Double {
        sailingState == "Upwind" ? optimalUpTWA : optimalDnTWA
    }

    /// Same signed angle that drives the needle (before ±1 scale) — **not** polar TWA deviation,
    /// so the value matches the bar centre when visually aligned with the iPad column midline.
    private var headingErrorVsActiveTackTargetDegrees: Double {
        let targetHeading = isPortTack ? portTackTarget : starboardTackTarget
        return normalizeAngleTo180(currentHeading - targetHeading)
    }

    /// Bumps needle refresh when TWD / polar / mode change — `onChange(of: heading)` alone missed those.
    private var needleInputSignature: String {
        "\(currentHeading)|\(trueWindDirection)|\(sailingState)|\(optimalUpTWA)|\(optimalDnTWA)|\(tolerance)|\(rangeMultiplier)"
    }

    var body: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width
            let barH = geometry.size.height
            /// iPad strip uses a ~22 pt bar; embedded performance uses a taller bar.
            let thinBar = barH < 30
            let barCorner = thinBar ? min(barH * 0.45, 5) : 8
            let pillFont = Font.system(size: thinBar ? 9 : 11, weight: .semibold, design: .monospaced)
            let pillHPad: CGFloat = thinBar ? 3 : 4
            let pillVPad: CGFloat = thinBar ? 2 : 3
            let pillCorner: CGFloat = thinBar ? 3 : 4
            let edgePad: CGFloat = thinBar ? 4 : 6
            let needleW: CGFloat = 3

            ZStack {
                // Alignment Bar with Gradient
                RoundedRectangle(cornerRadius: barCorner)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: TacticalPalette.tackBarGradientStops),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(maxHeight: .infinity)
                    .shadow(color: Color.black.opacity(thinBar ? 0.12 : 0.2), radius: thinBar ? 2 : 5, x: 0, y: thinBar ? 1 : 3)
                    .zIndex(0)

                // Current Heading Indicator (centre of ZStack + horizontal offset)
                Rectangle()
                    .fill(TacticalPalette.transition)
                    .frame(maxHeight: .infinity)
                    .frame(width: needleW)
                    .overlay {
                        Rectangle()
                            .strokeBorder(Color.white.opacity(0.85), lineWidth: thinBar ? 0.75 : 0.5)
                    }
                    .offset(x: animatedOffset, y: 0)
                    .animation(shouldAnimate ? .interpolatingSpring(stiffness: 80, damping: 15) : .none, value: animatedOffset)
                    .zIndex(1)

                // Overlay: target angle (left) + deviation (right)
                HStack {
                    // Optimal angle label — what we are targeting
                    let stateArrow = sailingState == "Upwind" ? "↑" : "↓"
                    Text("\(stateArrow) \(String(format: "%.0f", activeOptimalTWA))°")
                        .font(pillFont)
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, pillHPad)
                        .padding(.vertical, pillVPad)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: pillCorner))

                    Spacer()

                    // Signed **heading** error vs active tack target (same signal as needle).
                    let dev = headingErrorVsActiveTackTargetDegrees
                    let sign = dev >= 0 ? "+" : ""
                    Text("\(sign)\(String(format: "%.1f", dev))°")
                        .font(pillFont)
                        .foregroundStyle(abs(dev) <= tolerance ? Color.primary : TacticalPalette.transition)
                        .padding(.horizontal, pillHPad)
                        .padding(.vertical, pillVPad)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: pillCorner))
                }
                .padding(.horizontal, edgePad)
                .allowsHitTesting(false)
                .zIndex(2)
            }
            .onAppear {
                applyNeedleOffset(barWidth: barWidth, needleW: needleW)
                shouldAnimate = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    shouldAnimate = true
                }
            }
            .onChange(of: needleInputSignature) { _, _ in
                applyNeedleOffset(barWidth: barWidth, needleW: needleW)
            }
            .onChange(of: geometry.size.width) { _, newWidth in
                applyNeedleOffset(barWidth: newWidth, needleW: needleW)
            }
        }
    }

    private func applyNeedleOffset(barWidth: CGFloat, needleW: CGFloat) {
        let raw = xOffset(for: currentHeading, barWidth: barWidth)
        let newOffset = clampedPixelOffset(raw, barWidth: barWidth, needleWidth: needleW)
        animatedOffset = newOffset
        storedOffset = Double(newOffset)
    }

    private func xOffset(for heading: Double, barWidth: CGFloat) -> CGFloat {
        let targetHeading = isPortTack ? portTackTarget : starboardTackTarget
        let offset = normalizeAngleTo180(heading - targetHeading)
        // Guard: clamp scale denominator to at least 5° so a mis-configured tolerance
        // never makes the bar hyper-sensitive or causes division by zero.
        let scale = max(tolerance * rangeMultiplier, 5.0)
        let scaledOffset = offset / scale
        let effectiveOffset = max(min(scaledOffset, 1), -1)
        let pixelOffset = CGFloat(effectiveOffset) * (barWidth / 2)
        return pixelOffset
    }

    /// Keeps the needle fully inside the bar (centre-origin layout + horizontal offset).
    private func clampedPixelOffset(_ raw: CGFloat, barWidth: CGFloat, needleWidth: CGFloat) -> CGFloat {
        let limit = max(0, barWidth / 2 - needleWidth / 2)
        return max(-limit, min(limit, raw))
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
