//
//  AudioManager.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 22.01.25.
//

// MARK: - Audio Manager
import AVFoundation

@MainActor
class AudioManager: ObservableObject {
    private var audioPlayer: AVAudioPlayer?

    init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error setting up audio session: \(error.localizedDescription)")
        }
    }

    func playMusic() {
        guard let audioPath = Bundle.main.path(forResource: "share_your_passion", ofType: "m4a") else {
            print("Audio file not found.")
            return
        }

        let url = URL(fileURLWithPath: audioPath)

        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                do {
                    self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                    self.audioPlayer?.numberOfLoops = 0  // Play once
                    self.audioPlayer?.prepareToPlay()
                    self.audioPlayer?.volume = 1.0  // Start at full volume
                    self.audioPlayer?.play()

                    print("Music started playing successfully.")
                } catch {
                    print("Error playing music: \(error.localizedDescription)")
                }
            }
        }
    }

    func fadeOutMusic(duration: TimeInterval = 20.0) {
        guard let player = audioPlayer else { return }

        let steps = 10  // Number of fade steps
        let fadeStepDuration = duration / Double(steps)
        let volumeStep = player.volume / Float(steps)

        DispatchQueue.global(qos: .userInitiated).async {
            for _ in 0..<steps {
                DispatchQueue.main.async {
                    player.volume -= volumeStep
                }
                Thread.sleep(forTimeInterval: fadeStepDuration)
            }
            DispatchQueue.main.async {
                player.stop()
                player.volume = 1.0  // Reset volume for next play
            }
        }
    }

    func stopMusic() {
        fadeOutMusic()  // Call fade out when stopping music
    }
}
