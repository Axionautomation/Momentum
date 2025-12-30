//
//  ContentView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        Group {
            if appState.isOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .environmentObject(appState)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
