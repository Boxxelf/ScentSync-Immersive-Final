//
//  ScentDetailView.swift
//  Scent Sync Test
//
//  Created by iya student on 11/18/25.
//

import SwiftUI
import AVKit

struct ScentDetailView: View {
    let scent: ScentInfo
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var appModel
    @State private var audioPlayer = AudioPlayer()
    
    private var statusMessage: String {
        switch appModel.immersiveSpaceState {
        case .open:
            return "Immersive space is currently visible."
        case .inTransition:
            return "Preparing immersive space…"
        case .closed:
            return "Tap the button to open the immersive scene."
        }
    }
    
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
            
            scentCard
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Set the current scent's immersive space ID when view appears
            appModel.currentScentImmersiveSpaceID = appModel.immersiveSpaceID(for: scent.title)
            
            // Play springtime voiceover if this is "Springtime In A Park"
            if scent.title == "Springtime In A Park" {
                audioPlayer.playAudio(fileName: "springtime_voiceover", fileExtension: "mp3")
            }
        }
        .onDisappear {
            // Clear the current scent when view disappears
            appModel.currentScentImmersiveSpaceID = nil
            // Stop audio when view disappears
            audioPlayer.stop()
        }
    }
    
    private var scentCard: some View {
        ZStack(alignment: .leading) {
            VideoHeroView(videoFileName: scent.videoFileName)
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
            
            VStack(alignment: .leading, spacing: 18) {
                // Back button - Arrow only
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .padding(.top, 20)
                .padding(.horizontal, 32)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(scent.category.uppercased())
                        .font(.caption.bold())
                        .tracking(2)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color.white.opacity(0.1), in: Capsule())
                        .foregroundStyle(.white.opacity(0.95))
                    
                    Text(scent.title)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(scent.description)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(maxWidth: 420, alignment: .leading)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(scent.accentColor.opacity(0.9))
                            .frame(width: 10, height: 10)
                        Text(scent.type)
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
                
                // Immersive Space Button - Bottom Right
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        ToggleImmersiveSpaceButton()
                            .buttonStyle(ImmersiveButtonStyle())
                        
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.trailing, 32)
                    .padding(.bottom, 32)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassBackgroundEffect()
        .padding(.horizontal, 40)
        .padding(.vertical, 48)
    }
}

struct ImmersiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview(windowStyle: .automatic) {
    NavigationStack {
        ScentDetailView(scent: ScentInfo(
            title: "Lazy Sunday Morning",
            description: "A relaxing blend that captures the essence of a peaceful morning with soft florals and gentle musks.",
            category: "COLLECTION",
            type: "Eau de Parfum • Floral Musky",
            videoFileName: "lazy_sunday_morning",
            accentColor: .orange
        ))
        .environment(AppModel())
    }
}

