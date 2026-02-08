//
//  SharedData.swift
//  MomentumWidget
//
//  Phase 5: Widget Extension — Shared Data Model
//
//  XCODE SETUP REQUIRED:
//  1. In Xcode, go to File > New > Target > Widget Extension
//  2. Name it "MomentumWidget", uncheck "Include Configuration App Intent"
//  3. Go to project Signing & Capabilities for BOTH the main app and widget targets
//  4. Add "App Groups" capability to both targets
//  5. Create an App Group: "group.com.momentum.shared"
//  6. Enable the same App Group in both targets
//  7. Replace the generated widget code with the files in this directory
//  8. Add SharedData.swift to BOTH targets (main app + widget)
//

import Foundation

/// App Group identifier for sharing data between the main app and widget.
let appGroupIdentifier = "group.com.momentum.shared"

/// Lightweight data model shared between the main app and the widget extension.
/// The main app writes this to the shared App Group UserDefaults;
/// the widget reads it to populate its timeline.
struct WidgetData: Codable {
    let streakCount: Int
    let tasksRemaining: Int
    let tasksCompleted: Int
    let totalTasks: Int
    let topTaskTitles: [String]      // Up to 3 task titles for the medium widget
    let aiInsight: String?           // Short AI insight snippet
    let goalDomain: String?          // "career", "finance", "growth"
    let milestoneName: String?
    let milestoneProgress: Double    // 0.0 - 1.0
    let lastUpdated: Date

    static let storageKey = "widgetData"

    /// Write widget data to the shared App Group container.
    func save() {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        if let data = try? JSONEncoder().encode(self) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }

    /// Read widget data from the shared App Group container.
    static func load() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = defaults.data(forKey: storageKey),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data)
        else { return nil }
        return widgetData
    }

    /// Placeholder data for widget previews and initial state.
    static let placeholder = WidgetData(
        streakCount: 7,
        tasksRemaining: 3,
        tasksCompleted: 2,
        totalTasks: 5,
        topTaskTitles: [
            "Research competitor pricing",
            "Draft LinkedIn post",
            "Review budget spreadsheet"
        ],
        aiInsight: "Focus on the competitor analysis today — it'll unlock your pricing strategy.",
        goalDomain: "career",
        milestoneName: "Market Research",
        milestoneProgress: 0.45,
        lastUpdated: Date()
    )
}
