import SwiftUI
import SwiftData
import Network

@main
struct ExtasyCompleteNavigationApp: App {
    
    let modelContainer: ModelContainer
    private let watchConnectivityManager = WatchConnectivityManager()
    
    // Environment properties
    @State private var navigationManager = NavigationManager()
    @State private var settingsManager = SettingsManager()
    // Splash screen state - MARK: -> false during debug
    @State private var showSplashScreen = false
    
    //@StateObject private var audioManager = AudioManager() // Persisted audio manager instance
    
    init() {
        // Workaround for iOS 26 simulator TLS initialization crash
        nw_tls_create_options()
        
        // Initialize default settings
        DefaultSettings.initializeDefaults()
        
        do {
            let config = ModelConfiguration(for: Waypoints.self)
            
            modelContainer = try ModelContainer(for: Waypoints.self, configurations: config)
            debugLog("ModelContainer initialized successfully.")
            
        } catch {
            fatalError("Could not initialize ModelContainer: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                
                if showSplashScreen {
                    SplashScreenView()
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                                showSplashScreen = false  // Remove splash screen with fade-out
                                
                            }
                        }
                }
            }
            .animation(.easeInOut, value: showSplashScreen)
            .environment(navigationManager.udpHandler)
            .environment(navigationManager.nmeaParser)
            .environment(navigationManager)
            .environment(settingsManager)
            //.environmentObject(audioManager)
            .onAppear {
                let parser = navigationManager.nmeaParser
                parser.updateWindDamping(level: settingsManager.windDamping)
                parser.updateSpeedDamping(level: settingsManager.speedDamping)
                parser.updateHeadingDamping(level: settingsManager.headingDamping)
                parser.updateHydroDamping(level: settingsManager.hydroDamping)
                parser.setPeriodicUIUpdateInterval(settingsManager.uiRefreshIntervalSeconds)
            }
            .onChange(of: settingsManager.uiRefreshIntervalPreset) { _, _ in
                navigationManager.nmeaParser.setPeriodicUIUpdateInterval(settingsManager.uiRefreshIntervalSeconds)
            }
        }
        .modelContainer(modelContainer)
    }
}
