import SwiftUI

struct AnemometerView: View {
    let trueWindAngle: Double
    let apparentWindAngle: Double
    /// The active optimal TWA for the current sailing state:
    /// pass optimalUpTWA when Upwind, optimalDnTWA when Downwind.
    let optimalTWA: Double
    let width: CGFloat

    // Persisted as AppStorage so the arrow starts at the correct position immediately
    // on every view creation — no initial 0° flash, no animated jump on tab switch.
    @AppStorage("storedTrueWindAngle") private var displayedTrueWindAngle: Double = 0.0
    @AppStorage("storedApparentWindAngle") private var displayedApparentWindAngle: Double = 0.0

    // @State (not AppStorage) so it resets to false when the view is recreated.
    // This prevents the 0→stored animation that occurred when AppStorage held `true`
    // from the previous session and state updates batched in different cycles.
    @State private var shouldAnimate: Bool = false

    var body: some View {
        ZStack {
            // Dial Gauge Base
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color("dial_gauge_start"), Color("dial_gauge_end")]),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: width / 14
                )
                .padding(width / 20 / 2)

            // STBD Sector (same palette as performance / map — `TacticalPalette`)
            SectorView(
                gradientColors: TacticalPalette.starboardSectorGradient,
                startAngle: 270,
                lineWidth: width / 14,
                padding: width / 20 / 2
            )

            // PORT Sector
            SectorView(
                gradientColors: TacticalPalette.portSectorGradient,
                startAngle: 210,
                lineWidth: width / 14,
                padding: width / 20 / 2
            )

            // Dial Gauge Indicators
            DialGaugeIndicators(width: width)

            // Target TWA markers — starboard (positive) and port (negative)
            // These show where the T arrow should be to sail at optimal angle.
            if optimalTWA > 0 {
                TargetTWAMarker(angle: optimalTWA, width: width)
                TargetTWAMarker(angle: -optimalTWA, width: width)
            }

            // True Wind Arrow
            WindArrow(
                label: "T",
                color: Color(UIColor.systemBlue),
                delta: displayedTrueWindAngle,
                fontSize: width / 13,
                offset: width / 2.15,
                shouldAnimate: shouldAnimate
            )

            // Apparent Wind Arrow
            WindArrow(
                label: "A",
                color: Color(UIColor.systemPink),
                delta: displayedApparentWindAngle,
                fontSize: width / 13,
                offset: width / 2.15,
                shouldAnimate: shouldAnimate
            )
        }
        .onAppear {
            // displayedTrueWindAngle / displayedApparentWindAngle are already loaded
            // from AppStorage — no restoration needed here.
            // Sync to the live NMEA value in case it changed while the view was off-screen
            // (onChange won't fire for a steady value).
            shouldAnimate = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                updateArrowRotation(&displayedTrueWindAngle, to: trueWindAngle)
                updateArrowRotation(&displayedApparentWindAngle, to: apparentWindAngle)
                shouldAnimate = true
            }
        }
        .onChange(of: trueWindAngle) { _, newAngle in
            updateArrowRotation(&displayedTrueWindAngle, to: newAngle)
        }
        .onChange(of: apparentWindAngle) { _, newAngle in
            updateArrowRotation(&displayedApparentWindAngle, to: newAngle)
        }
    }

    // MARK: - Rotation Logic

    private func updateArrowRotation(_ displayedAngle: inout Double, to newAngle: Double) {
        let shortestDelta = calculateShortestRotation(from: displayedAngle, to: newAngle)
        if shouldAnimate {
            withAnimation(.easeInOut(duration: 1)) {
                displayedAngle += shortestDelta
            }
        } else {
            displayedAngle += shortestDelta
        }
    }

    private func calculateShortestRotation(from sourceAngle: Double, to targetAngle: Double) -> Double {
        let delta = (targetAngle - sourceAngle).truncatingRemainder(dividingBy: 360)
        return delta > 180 ? delta - 360 : (delta < -180 ? delta + 360 : delta)
    }
}

// MARK: - Subviews

struct SectorView: View {
    let gradientColors: [Color]
    let startAngle: Double
    let lineWidth: CGFloat
    let padding: CGFloat

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.167)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .topTrailing,
                    endPoint: .bottom
                ),
                lineWidth: lineWidth
            )
            .padding(padding)
            .rotationEffect(.degrees(startAngle))
    }
}

/// A yellow chevron sitting in the gap between the wind ring and the compass ring,
/// indicating the target (optimal) TWA for the current sailing state.
/// Draw two instances — one at +optimalTWA (starboard) and one at -optimalTWA (port).
///
/// Geometry reference (all relative to `width`):
///   Wind ring inner edge  ≈ 0.439 × width
///   Compass ring outer edge ≈ 0.403 × width  (after 0.82 scaleEffect)
///   Gap centre             ≈ 0.421 × width  → offset -(width / 2.37)
struct TargetTWAMarker: View {
    let angle: Double
    let width: CGFloat

    var body: some View {
        Image(systemName: "chevron.compact.down")
            .resizable()
            .scaledToFit()
            .frame(width: width / 20, height: width / 20)
            .foregroundColor(.yellow)
            .offset(y: -(width / 2.37))
            .rotationEffect(.degrees(angle))
            .animation(.easeInOut(duration: 0.4), value: angle)
    }
}

struct DialGaugeIndicators: View {
    let width: CGFloat

    var body: some View {
        ZStack {
            // Long Indicators
            MyShape(sections: 12, lineLengthPercentage: 0.1)
                .stroke(Color(UIColor.systemBackground), style: StrokeStyle(lineWidth: width / 90))

            // Short Indicators
            MyShape(sections: 36, lineLengthPercentage: 0.03)
                .stroke(Color(UIColor.systemBackground), style: StrokeStyle(lineWidth: width / 90))
                .padding(width / 60)
        }
    }
}

struct WindArrow: View {
    let label: String
    let color: Color
    let delta: Double
    let fontSize: CGFloat
    let offset: CGFloat
    let shouldAnimate: Bool  // Add shouldAnimate parameter

    var body: some View {
        ZStack {
            Image(systemName: "arrowtriangle.down.fill")
                .resizable()
                .scaledToFit()
                .frame(width: fontSize * 2, height: fontSize * 1.25)
                .foregroundColor(color)
                .offset(y: -offset * 1.02)

            Text(label)
                .font(Font.custom("AppleSDGothicNeo-Bold", size: fontSize * 0.8))
                .offset(y: -offset * 1.035)
                .foregroundStyle(Color(UIColor.white))
        }
        .rotationEffect(.degrees(delta)) // Rotate the arrow by delta
        .animation(shouldAnimate ? .easeInOut(duration: 1) : .none, value: delta) // Smooth rotation animation
    }
}

// MARK: - Preview
#Preview {
    GeometryProvider { width, _, _ in
        AnemometerView(
            trueWindAngle: 50,
            apparentWindAngle: 35,
            optimalTWA: 42,
            width: width
        )
    }
    .aspectRatio(contentMode: .fit)
}
