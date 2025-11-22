//
//  Scent_Sync_TestApp.swift
//  Scent Sync Test
//
//  Created by Tina Jiang on 11/17/25.
//

import SwiftUI

@main
struct Scent_Sync_TestApp: App {

    @State private var appModel = AppModel()
    @State private var avPlayerViewModel = AVPlayerViewModel()

    var body: some Scene {
        WindowGroup {
            if avPlayerViewModel.isPlaying {
                AVPlayerView(viewModel: avPlayerViewModel)
            } else {
                ContentView()
                    .environment(appModel)
            }
        }

        // Springtime In A Park Immersive Space - uses current ImmersiveView
        ImmersiveSpace(id: AppModel.springtimeImmersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                    print("✅ Springtime ImmersiveSpace appeared")
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                    print("❌ Springtime ImmersiveSpace disappeared")
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
        
        // Lazy Sunday Morning Immersive Space
        ImmersiveSpace(id: AppModel.lazySundayImmersiveSpaceID) {
            LazySundayImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                    print("✅ Lazy Sunday ImmersiveSpace appeared")
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                    print("❌ Lazy Sunday ImmersiveSpace disappeared")
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
        
        // Legacy ImmersiveSpace (kept for backward compatibility)
        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
     }
}
