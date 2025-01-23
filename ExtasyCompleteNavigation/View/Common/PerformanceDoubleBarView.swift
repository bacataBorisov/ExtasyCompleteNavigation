import SwiftUI

struct PerformanceDoubleBarView: View {
    let topBarValue: Double   // Measured value through log
    let bottomBarValue: Double   // Measured value over ground
    let maxPolarValue: Double        // Maximum polar speed
    let barLabel: String             // Overall label for the bar view
    let topBarLabel: String          // Label for the top bar
    let bottomBarLabel: String       // Label for the bottom bar
    let topBarPerformance: Double
    let bottomBarPerformance: Double
    
    // Bar gradient color based on performance
    private func gradientColor(for ratio: Double) -> LinearGradient {
        let clampedRatio = min(max(ratio, 0), 100) // Clamp the ratio between 0 and 100
        let colors: [Color]
        switch clampedRatio {
        case 0..<30:
            colors = [Color.red, Color.orange]
        case 30..<80:
            colors = [Color.orange, Color.yellow]
        default:
            colors = [Color.green, Color.teal]
        }
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 2) {
                    
                    // Top Performance Bar
                    ZStack(alignment: .leading) {
                        // Background bar
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: geometry.size.height / 2)
                        
                        // Foreground bar
                        if topBarPerformance >= 0 {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(gradientColor(for: topBarPerformance))
                                .frame(
                                    width: geometry.size.width * CGFloat(topBarPerformance / 100),
                                    height: geometry.size.height / 2
                                )
                                .animation(.easeInOut(duration: 0.8), value: topBarPerformance)
                        }
                        
                        // Label
                        HStack {
                            Text("\(topBarLabel): \(String(format: "%.2f kn", topBarValue))")
                                .font(.caption)
                                .foregroundColor(.black)
                                .padding(.leading, 8)
                            
                            Spacer() // Push the `barLabel` to the center

                            Text(barLabel)
                                .font(.headline)
                                .foregroundColor(Color("display_font"))
                                .frame(maxWidth: .infinity, alignment: .center) // Center align the bar label

                            Spacer() // Push the max label to the right

                            Text(String(format: "Max: %.2f kn", maxPolarValue))
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.trailing, 8)
                        }
                    }
                    // Bottom Performance Bar
                    ZStack(alignment: .leading) {
                        // Background bar
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: geometry.size.height / 2)
                        
                        // Foreground bar
                        if bottomBarPerformance >= 0 {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(gradientColor(for: bottomBarPerformance))
                                .frame(
                                    width: geometry.size.width * CGFloat(bottomBarPerformance / 100),
                                    height: geometry.size.height / 2
                                )
                                .animation(.easeInOut(duration: 0.8), value: bottomBarPerformance)
                        }
                        
                        // Label
                        HStack {
                            Text("\(bottomBarLabel): \(String(format: "%.2f kn", bottomBarValue))")
                                .font(.caption)
                                .foregroundColor(.black)
                                .padding(.leading, 8)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure it fills the available space
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
        )
    }
}

// Preview
#Preview {
    PerformanceDoubleBarView(
        topBarValue: 6.7,
        bottomBarValue: 5.4,
        maxPolarValue: 8.0,
        barLabel: "Performance",
        topBarLabel: "LOG",
        bottomBarLabel: "SOG",
        topBarPerformance: 85.0,
        bottomBarPerformance: 45.3
    )
    .frame(maxWidth: .infinity, maxHeight: 100)
    .padding()
    .background(Color.gray.opacity(0.1))
}
