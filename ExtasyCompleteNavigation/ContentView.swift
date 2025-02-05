import SwiftUI
import SwiftData

// MARK: - Main View
struct ContentView: View {
    var body: some View {
        if DeviceType.isIPad {
            iPadView()
        } else {
            iPhoneView()
        }
    }
}

#Preview {
    ContentView()
        .environment(NMEAParser())
        .environment(SettingsManager())
        .modelContainer(for: [
            Waypoints.self,
        ])
}
