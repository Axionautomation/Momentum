//
//  MomentumWidgetViews.swift
//  MomentumWidget
//
//  Phase 5: Widget Extension — Small & Medium Widget Views
//
//  Design: Dark glassmorphic style matching the main app.
//  Uses system fonts (SF Pro Display) since PhosphorSwift is not available in widget extensions.
//  Accent colors match GoalDomain: career (blue), finance (green), growth (violet).
//

import SwiftUI
import WidgetKit

// MARK: - Color Helpers (standalone for widget target)

extension Color {
    static let widgetBackground = Color(red: 9/255, green: 9/255, blue: 11/255)         // #09090B zinc-950
    static let widgetSurface = Color(red: 24/255, green: 24/255, blue: 27/255)           // #18181B zinc-900
    static let widgetBorder = Color.white.opacity(0.08)
    static let widgetTextPrimary = Color(red: 250/255, green: 250/255, blue: 250/255)    // #FAFAFA zinc-50
    static let widgetTextSecondary = Color(red: 161/255, green: 161/255, blue: 170/255)  // #A1A1AA zinc-400
    static let widgetTextTertiary = Color(red: 113/255, green: 113/255, blue: 122/255)   // #71717A zinc-500
    static let widgetBlue = Color(red: 59/255, green: 130/255, blue: 246/255)            // #3B82F6
    static let widgetCyan = Color(red: 6/255, green: 182/255, blue: 212/255)             // #06B6D4
    static let widgetGreen = Color(red: 16/255, green: 185/255, blue: 129/255)           // #10B981
    static let widgetViolet = Color(red: 139/255, green: 92/255, blue: 246/255)          // #8B5CF6
    static let widgetCoral = Color(red: 255/255, green: 107/255, blue: 74/255)           // #FF6B4A

    /// Resolve accent color from domain string.
    static func domainColor(_ domain: String?) -> Color {
        switch domain {
        case "finance": return .widgetGreen
        case "growth": return .widgetViolet
        default: return .widgetBlue
        }
    }
}

// MARK: - Small Widget View

/// Small widget: streak flame icon + count, tasks remaining count, dark background.
struct SmallWidgetView: View {
    let data: WidgetData

    private var accentColor: Color {
        .domainColor(data.goalDomain)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top row: Logo + streak
            HStack {
                // App icon placeholder
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text("M")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    )

                Spacer()

                // Streak
                if data.streakCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.widgetCoral)
                        Text("\(data.streakCount)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.widgetCoral)
                    }
                }
            }

            Spacer()

            // Tasks remaining — large number
            VStack(alignment: .leading, spacing: 2) {
                Text("\(data.tasksRemaining)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.widgetTextPrimary)

                Text("tasks left")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.widgetTextSecondary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 4)

                    let progress = data.totalTasks > 0
                        ? CGFloat(data.tasksCompleted) / CGFloat(data.totalTasks)
                        : 0
                    RoundedRectangle(cornerRadius: 3)
                        .fill(accentColor)
                        .frame(width: geo.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(14)
        .background(Color.widgetBackground)
        .widgetURL(URL(string: "momentum://dashboard"))
    }
}

// MARK: - Medium Widget View

/// Medium widget: top 3 task titles, streak, AI insight snippet, dark glassmorphic card style.
struct MediumWidgetView: View {
    let data: WidgetData

    private var accentColor: Color {
        .domainColor(data.goalDomain)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Left column: Tasks
            VStack(alignment: .leading, spacing: 6) {
                // Header row
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text("M")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        )

                    Text("Today's Tasks")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.widgetTextSecondary)

                    Spacer()
                }

                // Task list (up to 3)
                if data.topTaskTitles.isEmpty {
                    Text("All done for today!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.widgetTextPrimary)
                        .padding(.top, 2)
                } else {
                    ForEach(Array(data.topTaskTitles.prefix(3).enumerated()), id: \.offset) { index, title in
                        HStack(spacing: 6) {
                            Circle()
                                .strokeBorder(accentColor.opacity(0.6), lineWidth: 1.5)
                                .frame(width: 14, height: 14)

                            Text(title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.widgetTextPrimary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                // Bottom: progress
                HStack(spacing: 8) {
                    Text("\(data.tasksCompleted)/\(data.totalTasks)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(accentColor)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 3)

                            let progress = data.totalTasks > 0
                                ? CGFloat(data.tasksCompleted) / CGFloat(data.totalTasks)
                                : 0
                            RoundedRectangle(cornerRadius: 2)
                                .fill(accentColor)
                                .frame(width: geo.size.width * progress, height: 3)
                        }
                    }
                    .frame(height: 3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right column: Streak + AI Insight
            VStack(alignment: .leading, spacing: 8) {
                // Streak badge
                if data.streakCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.widgetCoral)
                        Text("\(data.streakCount) day streak")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.widgetCoral)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.widgetCoral.opacity(0.12))
                    .cornerRadius(8)
                }

                // AI Insight
                if let insight = data.aiInsight, !insight.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                                .foregroundColor(accentColor)
                            Text("AI Insight")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(accentColor)
                        }

                        Text(insight)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.widgetTextSecondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
                            )
                    )
                }

                Spacer()

                // Milestone
                if let name = data.milestoneName {
                    HStack(spacing: 4) {
                        WidgetProgressRing(
                            progress: data.milestoneProgress,
                            color: accentColor,
                            size: 14
                        )
                        Text(name)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.widgetTextTertiary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Color.widgetBackground)
        .widgetURL(URL(string: "momentum://dashboard"))
    }
}

// MARK: - Widget Progress Ring

struct WidgetProgressRing: View {
    let progress: Double
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 2)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}
