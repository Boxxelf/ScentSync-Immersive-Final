//
//  BGMAudioPlayer.swift
//  Scent Sync Test
//
//  Created by Tina Jiang on 11/21/25.
//

import AVFoundation
import SwiftUI

@MainActor
@Observable
class BGMAudioPlayer: NSObject {
    private var audioPlayer: AVAudioPlayer?
    var isPlaying: Bool = false
    
    func playBGM(fileName: String, fileExtension: String = "mp3", volume: Float = 0.4) {
        // Don't stop if already playing the same file
        if audioPlayer != nil && isPlaying {
            return
        }
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            print("⚠️ BGM file \(fileName).\(fileExtension) not found in bundle.")
            return
        }
        
        do {
            // Configure audio session for playback (mix with other audio)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.volume = volume
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            print("🎵 Started playing BGM: \(fileName).\(fileExtension) at volume \(volume)")
        } catch {
            print("❌ Error playing BGM: \(error.localizedDescription)")
            isPlaying = false
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        print("🛑 Stopped BGM")
    }
}

extension BGMAudioPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            // BGM should loop, so this shouldn't happen, but handle it anyway
            if flag {
                print("✅ BGM finished playing (unexpected for looped audio)")
            }
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            isPlaying = false
            if let error = error {
                print("❌ BGM decode error: \(error.localizedDescription)")
            }
        }
    }
}

