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
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [.momentumBlue, .momentumBlueLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.momentumBlue.opacity(0.4), radius: 15, y: 8)

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
        Color.momentumBackground.ignoresSafeArea()

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
    .preferredColorScheme(.dark)
}
