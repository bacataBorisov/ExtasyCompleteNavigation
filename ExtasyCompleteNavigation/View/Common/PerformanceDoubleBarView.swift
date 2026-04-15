import SwiftUI

// MARK: - Power-bar style performance card
//
// Each card shows two segmented "battery" bars — like a charging indicator.
// Segments light up left-to-right based on the performance ratio (0–100 %).
// Colour zones: segments 1-3 red, 4-7 orange/yellow, 8-12 green→teal.
// Cards are compact (~68 pt tall) so all three fit on screen without scrolling.

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

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                Text(barLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("Max \(String(format: "%.1f", maxPolarValue)) kn")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            // Top bar
            BarRow(label: topBarLabel,
                   labelColor: topBarLabelColor,
                   value: topBarValue,
                   performance: topBarPerformance)

            // Bottom bar
            BarRow(label: bottomBarLabel,
                   labelColor: bottomBarLabelColor,
                   value: bottomBarValue,
                   performance: bottomBarPerformance)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Single bar row

private struct BarRow: View {
    let label: String
    let labelColor: Color
    let value: Double
    let performance: Double

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(labelColor)
                .frame(width: 34, alignment: .leading)

            PowerSegments(performance: performance)

            Text(String(format: "%.1f", value))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(Color("display_font"))
                .frame(width: 34, alignment: .trailing)
        }
    }
}

// MARK: - Segmented power bar

struct PowerSegments: View {
    let performance: Double   // 0–100
    private let total = 12

    // Segment colour by position — red zone → orange → teal
    private func segmentColor(index: Int) -> Color {
        switch index {
        case 0...2:  return .red
        case 3...6:  return .orange
        default:     return .teal
        }
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
                    .frame(height: 14)
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
            topBarLabelColor: Color(red: 1, green: 0.3, blue: 0.3),
            bottomBarLabelColor: Color(red: 0.2, green: 0.8, blue: 0.4)
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
