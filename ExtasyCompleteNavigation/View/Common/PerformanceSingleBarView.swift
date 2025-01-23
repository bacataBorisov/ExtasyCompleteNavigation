import SwiftUI

struct PerformanceSingleBarView: View {
    
    let currentValue: Double   // Measured value through log
    let maxValue: Double       // Maximum polar speed
    let barLabel: String       // Label for the bar
    let performance: Double    // Performance percentage
    
    // Bar color based on performance with gradients
    private func gradientColor(for ratio: Double) -> LinearGradient {
        let colors: [Color]
        switch ratio {
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

        
        // Progress Bar
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background bar
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 30)
                
                // Foreground bar with animation
                RoundedRectangle(cornerRadius: 8)
                    .fill(gradientColor(for: performance))
                    .frame(
                        width: geometry.size.width * CGFloat(performance / 100),
                        height: 30
                    )
                    .animation(.easeInOut(duration: 0.8), value: performance)
                // Title
                Text(barLabel)
                    .font(.headline)
                    .foregroundColor(Color("display_font"))
                    .frame(maxWidth: .infinity, alignment: .center)
                // Log text on top of the bar
                Text(String(format: "%.2f kn", currentValue))
                    .font(.footnote)
                    .foregroundColor(.black)
                    .padding(.leading, 8)
                    .padding(.vertical, 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(String(format: "Max: %.2f kn", maxValue))
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing)
            }
        }
        .frame(height: 30)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
        )
    }
}

#Preview {
    PerformanceSingleBarView(
        currentValue: 6.7,
        maxValue: 8.0,
        barLabel: "Speed Efficiency",
        performance: 83.0
    )
    .frame(maxWidth: .infinity, maxHeight: 100)
    .padding()
    .background(Color.gray.opacity(0.1)) // Debugging background
}
