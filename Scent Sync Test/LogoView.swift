//
//  LogoView.swift
//  Scent Sync Test
//
//  Created by Tina Jiang on 11/21/25.
//

import SwiftUI

struct LogoView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image("brandlogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 160, height: 60)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.2))
        )
    }
}

#Preview {
    LogoView()
        .background(Color.black)
}

