import SwiftUI

struct AnemometerView: View {
    let trueWindAngle: Double
    let apparentWindAngle: Double
    let width: CGFloat

    @AppStorage("storedTrueWindAngle") private var storedTrueWindAngle: Double = 0.0
    @AppStorage("storedApparentWindAngle") private var storedApparentWindAngle: Double = 0.0
    @AppStorage("anemometerShouldAnimate") private var shouldAnimate: Bool = false

    @State private var displayedTrueWindAngle: Double = 0.0
    @State private var displayedApparentWindAngle: Double = 0.0

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

            // STBD Sector
            SectorView(
                gradientColors: [Color.green.opacity(0.7), Color.teal.opacity(0.7)],
                startAngle: 270,
                lineWidth: width / 14,
                padding: width / 20 / 2
            )

            // PORT Sector
            SectorView(
                gradientColors: [Color.red.opacity(0.7), Color.purple.opacity(0.7)],
                startAngle: 210,
                lineWidth: width / 14,
                padding: width / 20 / 2
            )

            // Dial Gauge Indicators
            DialGaugeIndicators(width: width)

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
            // Restore last known values when view appears
            displayedTrueWindAngle = storedTrueWindAngle
            displayedApparentWindAngle = storedApparentWindAngle
            shouldAnimate = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                updateArrowRotation(&displayedTrueWindAngle, to: trueWindAngle)
                updateArrowRotation(&displayedApparentWindAngle, to: apparentWindAngle)
                shouldAnimate = true
            }
        }
        .onChange(of: trueWindAngle) { _, newAngle in
            updateArrowRotation(&displayedTrueWindAngle, to: newAngle)
            storedTrueWindAngle = newAngle
        }
        .onChange(of: apparentWindAngle) { _, newAngle in
            updateArrowRotation(&displayedApparentWindAngle, to: newAngle)
            storedApparentWindAngle = newAngle
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
            trueWindAngle: 350,
            apparentWindAngle: 10,
            width: width
        )
    }
    .aspectRatio(contentMode: .fit)
}
