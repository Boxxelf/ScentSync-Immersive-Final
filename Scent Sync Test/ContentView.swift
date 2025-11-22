//
//  ContentView.swift
//  Scent Sync Test
//
//  Created by Tina Jiang on 11/17/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    var body: some View {
        NavigationStack {
            WelcomeView()
                .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
