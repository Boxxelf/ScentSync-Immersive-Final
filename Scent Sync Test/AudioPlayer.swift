//
//  AudioPlayer.swift
//  Scent Sync Test
//
//  Created by Tina Jiang on 11/21/25.
//

import AVFoundation
import SwiftUI

@MainActor
@Observable
class AudioPlayer: NSObject {
    private var audioPlayer: AVAudioPlayer?
    var isPlaying: Bool = false
    
    func playAudio(fileName: String, fileExtension: String = "mp3") {
        // Stop any currently playing audio
        stop()
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            print("⚠️ Audio file \(fileName).\(fileExtension) not found in bundle.")
            return
        }
        
        do {
            // Configure audio session for playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            print("🔊 Started playing audio: \(fileName).\(fileExtension)")
        } catch {
            print("❌ Error playing audio: \(error.localizedDescription)")
            isPlaying = false
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            print("✅ Audio finished playing successfully: \(flag)")
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            isPlaying = false
            if let error = error {
                print("❌ Audio decode error: \(error.localizedDescription)")
            }
        }
    }
}

