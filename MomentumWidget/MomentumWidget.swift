//
//  MomentumWidget.swift
//  MomentumWidget
//
//  Phase 5: Widget Extension — Timeline Provider & Widget Definition
//
//  XCODE SETUP REQUIRED:
//  1. Create a Widget Extension target named "MomentumWidget"
//  2. Add App Group "group.com.momentum.shared" to both targets
//  3. Add SharedData.swift to both the main app and widget targets
//  4. Replace the auto-generated widget code with this file + MomentumWidgetViews.swift
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct MomentumEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Timeline Provider

struct MomentumTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> MomentumEntry {
        MomentumEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (MomentumEntry) -> Void) {
        let data = WidgetData.load() ?? .placeholder
        completion(MomentumEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MomentumEntry>) -> Void) {
        let data = WidgetData.load() ?? .placeholder
        let entry = MomentumEntry(date: Date(), data: data)

        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Definition

struct MomentumWidget: Widget {
    let kind: String = "MomentumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MomentumTimelineProvider()) { entry in
            MomentumWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Momentum")
        .description("Track your daily tasks, streak, and AI insights.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Entry View Router

struct MomentumWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: MomentumEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        default:
            SmallWidgetView(data: entry.data)
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    MomentumWidget()
} timeline: {
    MomentumEntry(date: Date(), data: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    MomentumWidget()
} timeline: {
    MomentumEntry(date: Date(), data: .placeholder)
}
