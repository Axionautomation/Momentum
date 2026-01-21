//
//  SoundManager.swift
//  Momentum
//
//  Created by Henry Bowman on 1/20/26.
//

import AVFoundation
import UIKit

@MainActor
class SoundManager {
    static let shared = SoundManager()

    private var audioPlayer: AVAudioPlayer?

    private init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    // MARK: - Sound Effects

    /// Play pop sound for task completion
    func playPop() {
        // Using system sound as fallback - you can add a custom pop.mp3 to the bundle
        // and use playSound(named: "pop") instead
        playSystemSound(id: 1104) // Tock sound
    }

    /// Play celebration sound for all tasks complete
    func playCelebration() {
        // Using system sound as fallback
        playSystemSound(id: 1025) // New Mail sound (pleasant chime)
    }

    /// Play a custom sound file from the bundle
    func playSound(named name: String, withExtension ext: String = "mp3") {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("Sound file not found: \(name).\(ext)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }

    /// Play a system sound by ID
    private func playSystemSound(id: SystemSoundID) {
        AudioServicesPlaySystemSound(id)
    }

    // MARK: - Haptic Feedback

    /// Light haptic for touch down
    func lightHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Medium haptic for task completion
    func mediumHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Heavy haptic for emphasis
    func heavyHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Success haptic for achievements
    func successHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// Selection haptic for toggles
    func selectionHaptic() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
