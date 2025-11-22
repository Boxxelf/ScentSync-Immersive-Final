//
//  LazySundayImmersiveView.swift
//  Scent Sync Test
//
//  Created by iya student on 11/18/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct LazySundayImmersiveView: View {
    @Environment(AppModel.self) var appModel

    var body: some View {
        RealityView { content in
            // Add the Lazy Sunday Morning immersive content
            // TODO: Replace "Immersive" with your LazySunday-specific scene name from Reality Composer Pro
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)
            }
        }
    }
}

#Preview(immersionStyle: .full) {
    LazySundayImmersiveView()
        .environment(AppModel())
}

