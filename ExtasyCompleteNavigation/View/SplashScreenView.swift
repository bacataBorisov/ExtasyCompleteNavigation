import SwiftUI
import AVFoundation // For speech synthesis and audio playback

struct SplashScreenView: View {
    @Environment(NMEAParser.self) private var navigationReadings

    @State private var isActive = false // Controls transition to the main view
    @State private var fadeOut = false // Controls fade-out animation
    @State private var fadeIn = false  // Controls fade-in animation
    @StateObject private var speechManager = SpeechManager() // Use an ObservableObject for speech
    @EnvironmentObject private var audioManager: AudioManager  // Persisted audio manager instance

    var body: some View {
        ZStack {
            // Background gradient with blue, teal, and purple shades
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.9),
                    Color.teal.opacity(0.8),
                    Color.purple.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(fadeOut ? 0 : 1) // Gradually fade out

            VStack {
                Spacer()
                // Boat Logo
                Image("Extasy_Splash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .shadow(color: .black.opacity(0.7), radius: 10, x: 5, y: 5)
                    .padding(.bottom, 20)

                // Silver glowing text effect
                Text("Hello Bori!")
                    .font(Font.custom("Noteworthy", size: 48))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white, Color.gray]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.7), radius: 10, x: 5, y: 5)

                Text("Welcome onboard!")
                    .font(Font.custom("Noteworthy", size: 48))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white, Color.gray]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.7), radius: 10, x: 5, y: 5)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .opacity(fadeOut ? 0 : 1) // gradually fadeIN
        }
        .onAppear {
            // Fade-in animation for content
            withAnimation(.easeInOut(duration: 2)) {
                fadeIn = true
            }
            
            // Start welcome message
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                speechManager.playWelcomeMessage("Hello Bori! Welcome onboard!")
            }

            // Start fade-out animation after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation(.easeInOut(duration: 2)) {
                    fadeOut = true
                    audioManager.fadeOutMusic()  // Gradually fade out the music
                }
            }
        }
    }
}

// MARK: - Speech Manager
@MainActor
class SpeechManager: ObservableObject {
    private var speechSynthesizer: AVSpeechSynthesizer

    init() {
        self.speechSynthesizer = AVSpeechSynthesizer()
    }

    func playWelcomeMessage(_ message: String) {
        let speechUtterance = AVSpeechUtterance(string: message)

        // Configure speech settings
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechUtterance.rate = 0.5
        speechUtterance.volume = 1.0
        speechUtterance.pitchMultiplier = 1.2

        // Ensure speech doesn't override the music by setting the audio session properly
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session: \(error.localizedDescription)")
        }

        speechSynthesizer.speak(speechUtterance)
    }
}

// MARK: - Preview
#Preview {
    SplashScreenView()
        .environment(NMEAParser())
        .environment(SettingsManager())
        .environmentObject(AudioManager())
}
