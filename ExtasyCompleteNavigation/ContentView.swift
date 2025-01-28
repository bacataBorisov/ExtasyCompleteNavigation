import SwiftUI
import MapKit
import SwiftData

// MARK: - Main View
struct ContentView: View {
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(SettingsManager.self) private var settingsManager
    
    @Query private var waypoints: [Waypoints]
    @State private var showSplashScreen = true  // Track splash screen visibility
    
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
