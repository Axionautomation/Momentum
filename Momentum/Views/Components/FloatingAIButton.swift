//
//  FloatingAIButton.swift
//  Momentum
//
//  Created by Henry Bowman on 12/31/25.
//

import SwiftUI
import PhosphorSwift

struct FloatingAIButton: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button {
            appState.openGlobalChat()
        } label: {
            ZStack {
                // Main button - square with very rounded corners and gradient
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.momentumViolet,
                                Color(hex: "6B46C1"),
                                Color(hex: "1E293B")
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 35
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.momentumViolet.opacity(0.6), lineWidth: 0.5)
                    )
                    .shadow(color: .momentumViolet.opacity(0.4), radius: 15, y: 8)

                Ph.sparkle.regular
                    .color(.white)
                    .frame(width: 22, height: 22)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingAIButton()
                    .padding(.trailing, 20)
                    .padding(.bottom, 90)
            }
        }
    }
    .environmentObject(AppState())
}
