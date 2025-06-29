import SwiftUI
import SwiftData

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
            .onAppear{
                //audioManager.playMusic()
            }
        }
        .modelContainer(for: Waypoints.self)
    }
}
