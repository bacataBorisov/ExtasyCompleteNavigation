import SwiftUI

struct PseudoBoatView: View {
    @Environment(NMEAParser.self) private var navigationReadings
    
    var body: some View {
        ZStack {
            // Background (if needed)
            Color.clear // Placeholder for any background adjustments
            
                PseudoBoat()
                    .stroke(lineWidth: 2)
                

        }
    }
}

#Preview {
    PseudoBoatView()
        .environment(NMEAParser())
        .frame(width: 300, height: 400) // Adjust for testing preview
        .background(Color.gray.opacity(0.2)) // Debugging background
}
