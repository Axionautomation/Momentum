//
//  MomentumApp.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI
import BackgroundTasks

@main
struct MomentumApp: App {
    init() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.momentum.briefing",
            using: nil
        ) { task in
            // Background briefing generation — scheduling logic in a future phase
            task.setTaskCompleted(success: true)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
