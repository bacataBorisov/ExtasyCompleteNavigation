import SwiftUI

struct SailingDashboardView: View {
    @State private var sessionManager = WatchSessionManager()

    var body: some View {
        VStack(spacing: 8) {
            Text("Depth: \(sessionManager.depth)m")
            Text("Speed: \(sessionManager.boatSpeedLog)kn")
            Text("Wind: \(sessionManager.wind)kn")
        }
        .font(.title3)
        .multilineTextAlignment(.center)
        .padding()
        .onAppear {
            print("👀 Watch UI appeared — binding active")
        }
    }
}
