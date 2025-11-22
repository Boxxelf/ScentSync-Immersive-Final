//
//  WelcomeView.swift
//  Scent Sync Test
//
//  Created by iya student on 11/18/25.
//

import SwiftUI
import AVKit

struct WelcomeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var audioPlayer = AudioPlayer()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.05, blue: 0.08),
                    Color(red: 0.11, green: 0.13, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            heroCard
        }
    }

    private var heroCard: some View {
        ZStack(alignment: .leading) {
            VideoHeroView(videoFileName: "flowers")
                .clipShape(RoundedRectangle(cornerRadius: 40))

            RoundedRectangle(cornerRadius: 40)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.75),
                            Color.black.opacity(0.25)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 12)

                // ScentSync Product Introduction
                VStack(alignment: .leading, spacing: 16) {
                    Text("SCENTSYNC")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Visualize scents and embark on an immersive fragrance journey. Experience perfumes through stunning visuals that bring each fragrance to life in an immersive environment.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(maxWidth: 500, alignment: .leading)
                        .lineSpacing(4)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Explore More")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            // Collection 1: Springtime In A Park
                            NavigationLink {
                                ScentDetailView(scent: ScentInfo(
                                    title: "Springtime In A Park",
                                    description: "This fresh scent evokes a stroll through a park during springtime with blossoms and fruit in every breath.",
                                    category: "COLLECTION",
                                    type: "Eau de Toilette • Floral Fruity",
                                    videoFileName: "Springtime",
                                    accentColor: .pink
                                ))
                                .environment(appModel)
                            } label: {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 220, height: 140)
                                    .overlay(
                                        VStack(alignment: .leading) {
                                            Text("Springtime In A Park")
                                                .font(.headline)
                                            Text("Tap to preview")
                                                .font(.footnote)
                                                .opacity(0.8)
                                        }
                                        .padding()
                                        .foregroundStyle(.white)
                                    )
                            }
                            .buttonStyle(.plain)
                            
                            // Collection 2: Lazy Sunday Morning
                            NavigationLink {
                                ScentDetailView(scent: ScentInfo(
                                    title: "Lazy Sunday Morning",
                                    description: "A relaxing blend that captures the essence of a peaceful morning with soft florals and gentle musks.",
                                    category: "COLLECTION",
                                    type: "Eau de Parfum • Floral Musky",
                                    videoFileName: "lazy_sunday_morning",
                                    accentColor: .orange
                                ))
                                .environment(appModel)
                            } label: {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 220, height: 140)
                                    .overlay(
                                        VStack(alignment: .leading) {
                                            Text("Lazy Sunday Morning")
                                                .font(.headline)
                                            Text("Tap to preview")
                                                .font(.footnote)
                                                .opacity(0.8)
                                        }
                                        .padding()
                                        .foregroundStyle(.white)
                                    )
                            }
                            .buttonStyle(.plain)
                            
                            // Collection 3-5
                            ForEach(2..<5) { index in
                                Button {
                                    // Placeholder for future navigation
                                } label: {
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 220, height: 140)
                                        .overlay(
                                            VStack(alignment: .leading) {
                                                Text("Collection \(index + 1)")
                                                    .font(.headline)
                                                Text("Tap to preview")
                                                    .font(.footnote)
                                                    .opacity(0.8)
                                            }
                                            .padding()
                                            .foregroundStyle(.white)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassBackgroundEffect()
        .padding(.horizontal, 40)
        .padding(.vertical, 48)
        .onAppear {
            // Play intro voiceover when WelcomeView appears
            audioPlayer.playAudio(fileName: "intro_voiceover", fileExtension: "mp3")
        }
        .onDisappear {
            // Stop audio when view disappears
            audioPlayer.stop()
        }
    }
}

struct ScentInfo {
    let title: String
    let description: String
    let category: String
    let type: String
    let videoFileName: String
    let accentColor: Color
}

final class VideoHeroPlayer {
    let player: AVPlayer
    let hasVideo: Bool

    init(videoFileName: String) {
        if let url = Bundle.main.url(forResource: videoFileName, withExtension: "mp4") {
            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)
            player.isMuted = true
            player.actionAtItemEnd = .none

            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { _ in
                player.seek(to: .zero)
                player.play()
            }

            self.player = player
            self.hasVideo = true
        } else {
            self.player = AVPlayer()
            self.hasVideo = false
            print("⚠️ \(videoFileName).mp4 not found in bundle.")
        }
    }
}

struct VideoHeroView: View {
    let videoFileName: String
    @State private var video: VideoHeroPlayer?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.35, green: 0.18, blue: 0.38),
                            Color(red: 0.10, green: 0.08, blue: 0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let video = video, video.hasVideo {
                VideoPlayer(player: video.player)
                    .onAppear {
                        video.player.play()
                    }
                    .onDisappear {
                        video.player.pause()
                    }
                    .disabled(true)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .onAppear {
            if video == nil {
                video = VideoHeroPlayer(videoFileName: videoFileName)
            }
            // Ensure video plays when view appears
            if let video = video, video.hasVideo {
                video.player.play()
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    NavigationStack {
        WelcomeView()
            .environment(AppModel())
    }
}

