import SwiftUI

// MARK: - Performance double bar
//
// **Card style** (`cardStyle == true`): segmented “battery” blocks (12 segments) by colour zone.
// **Strip style** (`cardStyle == false`): continuous **racing fill** bar — one gradient track, fill = % of polar.

struct PerformanceDoubleBarView: View {
    let topBarValue: Double
    let bottomBarValue: Double
    let maxPolarValue: Double
    let barLabel: String
    let topBarLabel: String
    let bottomBarLabel: String
    let topBarPerformance: Double
    let bottomBarPerformance: Double
    var topBarLabelColor: Color = Color("display_font")
    var bottomBarLabelColor: Color = Color("display_font")
    /// When `false`, drops the rounded “card” background and shadow (e.g. iPad strip) to save space.
    var cardStyle: Bool = true
    /// iPad strip + mark selected: tighter vertical metrics so the stack can sit with even top/bottom padding.
    var stripCompact: Bool = false

    private var headerLabelSize: CGFloat { stripCompact ? 10 : 11 }
    private var headerMaxSize: CGFloat { stripCompact ? 9 : 10 }
    private var segmentHeight: CGFloat { stripCompact ? 11 : 14 }
    private var blockSpacing: CGFloat { stripCompact ? 3 : 5 }
    private var horizontalPadding: CGFloat { stripCompact ? 6 : (cardStyle ? 12 : 8) }
    private var verticalPadding: CGFloat { stripCompact ? 3 : (cardStyle ? 8 : 4) }

    private var useRacingFillBar: Bool { !cardStyle }

    var body: some View {
        VStack(alignment: .leading, spacing: blockSpacing) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                Text(barLabel)
                    .font(.system(size: headerLabelSize, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("Max \(String(format: "%.1f", maxPolarValue)) kn")
                    .font(.system(size: headerMaxSize))
                    .foregroundColor(.secondary)
            }

            // Top bar
            BarRow(
                label: topBarLabel,
                labelColor: topBarLabelColor,
                value: topBarValue,
                performance: topBarPerformance,
                segmentHeight: segmentHeight,
                useRacingFill: useRacingFillBar
            )

            // Bottom bar
            BarRow(
                label: bottomBarLabel,
                labelColor: bottomBarLabelColor,
                value: bottomBarValue,
                performance: bottomBarPerformance,
                segmentHeight: segmentHeight,
                useRacingFill: useRacingFillBar
            )
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background {
            if cardStyle {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
    }
}

// MARK: - Single bar row

private struct BarRow: View {
    let label: String
    let labelColor: Color
    let value: Double
    let performance: Double
    var segmentHeight: CGFloat = 14
    var useRacingFill: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: segmentHeight < 12 ? 10 : 11, weight: .semibold, design: .monospaced))
                .foregroundColor(labelColor)
                .frame(width: segmentHeight < 12 ? 32 : 34, alignment: .leading)

            Group {
                if useRacingFill {
                    RacingFillBar(performance: performance, height: segmentHeight)
                } else {
                    PowerSegments(performance: performance, barHeight: segmentHeight)
                }
            }

            Text(String(format: "%.1f", value))
                .font(.system(size: segmentHeight < 12 ? 12 : 13, weight: .bold, design: .rounded))
                .foregroundColor(Color("display_font"))
                .frame(width: segmentHeight < 12 ? 32 : 34, alignment: .trailing)
        }
    }
}

// MARK: - Racing-style continuous fill (strip / iPad lower row)

private struct RacingFillBar: View {
    let performance: Double
    var height: CGFloat = 12

    private var fillFraction: CGFloat {
        CGFloat(min(max(performance, 0), 100) / 100.0)
    }

    var body: some View {
        GeometryReader { geo in
            let w = max(geo.size.width, 1)
            let fillW = max(w * fillFraction, fillFraction > 0 ? 3 : 0)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: TacticalPalette.racingFillGradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillW)
                    .animation(.easeInOut(duration: 0.32), value: performance)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Segmented power bar

struct PowerSegments: View {
    let performance: Double   // 0–100
    /// Vertical size of each segment (slightly shorter when the strip is compact).
    var barHeight: CGFloat = 14
    private let total = 12

    private func segmentColor(index: Int) -> Color {
        TacticalPalette.segmentColor(index: index)
    }

    private func isFilled(_ index: Int) -> Bool {
        let threshold = Double(index + 1) / Double(total) * 100
        return threshold <= min(max(performance, 0), 100)
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<total, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(isFilled(i)
                          ? segmentColor(index: i).opacity(0.88)
                          : Color.gray.opacity(0.15))
                    .frame(height: barHeight)
                    .animation(
                        .easeInOut(duration: 0.5).delay(Double(i) * 0.025),
                        value: performance)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 8) {
        PerformanceDoubleBarView(
            topBarValue: 7.7, bottomBarValue: 6.9,
            maxPolarValue: 8.2, barLabel: "Speed",
            topBarLabel: "Log", bottomBarLabel: "SOG",
            topBarPerformance: 94, bottomBarPerformance: 84
        )
        PerformanceDoubleBarView(
            topBarValue: 6.0, bottomBarValue: 5.3,
            maxPolarValue: 6.5, barLabel: "VMG",
            topBarLabel: "Log", bottomBarLabel: "SOG",
            topBarPerformance: 55, bottomBarPerformance: 45
        )
        PerformanceDoubleBarView(
            topBarValue: 4.1, bottomBarValue: 5.6,
            maxPolarValue: 6.2, barLabel: "VMC",
            topBarLabel: "PORT", bottomBarLabel: "STBD",
            topBarPerformance: 20, bottomBarPerformance: 70,
            topBarLabelColor: TacticalPalette.tackLabelColor(for: "PORT"),
            bottomBarLabelColor: TacticalPalette.tackLabelColor(for: "STBD")
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
