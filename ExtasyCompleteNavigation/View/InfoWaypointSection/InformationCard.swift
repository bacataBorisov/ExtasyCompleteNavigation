import SwiftUI

struct InformationCard: View {
    @State private var currentTime: String = ""
    @State private var weatherForecast: String = "Sunny, 15°C" // Placeholder weather info
    
    var body: some View {
        
        ZStack {
            // Background with subtle gradients
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
            
            // Card content
            VStack(spacing: 8) {
                Text("Current Information")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                VStack(spacing: 4) {
                    Text("⏰ Time: \(currentTime)")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                    
                    Text("🌤️ Weather: \(weatherForecast)")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            updateCurrentTime()
        }
    }
    
    // Update Current Time
    private func updateCurrentTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        currentTime = formatter.string(from: Date())
        
        // Update the time every second
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = formatter.string(from: Date())
        }
    }
}

// MARK: - Preview

struct InformationCard_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            VStack(spacing: 16) {
                InformationCard()
            }
            .padding()
            .background(Color(UIColor.systemGray6))
        }
    }
}
