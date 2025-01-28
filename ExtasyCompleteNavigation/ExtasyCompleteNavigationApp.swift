import SwiftUI
import SwiftData

@main
struct ExtasyCompleteNavigationApp: App {
    
    let modelContainer: ModelContainer
    
    // Environment properties
    @State private var navigationManager = NavigationManager()
    @State private var settingsManager = SettingsManager()
    
    // Splash screen state - MARK: -> false during debug
    @State private var showSplashScreen = true
    
    @StateObject private var audioManager = AudioManager() // Persisted audio manager instance
    
    init() {
        // Initialize default settings
        DefaultSettings.initializeDefaults()
        
        do {
            let config = ModelConfiguration(for: Waypoints.self,
                                            isStoredInMemoryOnly: true)
            
            modelContainer = try ModelContainer(for: Waypoints.self,
                                                configurations: config)
        } catch {
            fatalError("Could not initialize ModelContainer for these guys")
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
            .environmentObject(audioManager)
            .onAppear{
                audioManager.playMusic()
            }
        }
        .modelContainer(for: Waypoints.self)
    }
}
