//
//  StatsView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var appState: AppState

    private let weeklyData = MockDataService.shared.weeklyCompletionData

    var body: some View {
        ZStack {
            Color.momentumDarkBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("Your Stats")
                        .font(MomentumFont.heading(20))
                        .foregroundColor(.white)
                        .padding(.top)

                    // Overview Card
                    overviewCard

                    // Weekly Chart
                    weeklyChartCard

                    // Premium Insights (Locked)
                    premiumInsightsCard

                    // Monthly Progress
                    monthlyProgressCard

                    // Achievements
                    achievementsSection
                        .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Overview Card
    private var overviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Overview")
                    .font(MomentumFont.bodyMedium(16))
                    .foregroundColor(.white)
                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                statItem(title: "Total Tasks", value: "\(MockDataService.shared.totalTasksCompleted)", icon: "checkmark.circle.fill")
                statItem(title: "Completion Rate", value: "\(Int(MockDataService.shared.completionRate * 100))%", icon: "chart.line.uptrend.xyaxis")
                statItem(title: "Current Streak", value: " \(appState.currentUser?.streakCount ?? 0) days", icon: nil)
                statItem(title: "Longest Streak", value: " \(appState.currentUser?.longestStreak ?? 0) days", icon: nil)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func statItem(title: String, value: String, icon: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(MomentumFont.body(13))
                .foregroundColor(.momentumSecondaryText)

            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.momentumViolet)
                }
                Text(value)
                    .font(MomentumFont.stats(20))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Weekly Chart
    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(MomentumFont.bodyMedium(16))
                .foregroundColor(.white)

            Chart {
                ForEach(weeklyData, id: \.0) { day, count in
                    BarMark(
                        x: .value("Day", day),
                        y: .value("Tasks", count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.momentumViolet, .momentumDeepBlue],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(4)
                }
            }
            .frame(height: 150)
            .chartYScale(domain: 0...4)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.momentumSecondaryText)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.momentumSecondaryText)
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.1))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Premium Insights Card
    private var premiumInsightsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.momentumGold)
                Text("Premium Insights")
                    .font(MomentumFont.bodyMedium(16))
                    .foregroundColor(.white)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                premiumFeatureRow(icon: "calendar", text: "Best performing days")
                premiumFeatureRow(icon: "clock", text: "Optimal task times")
                premiumFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Completion predictions")
            }
            .padding()
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                // Upgrade action
            } label: {
                HStack {
                    Text("Upgrade to Premium")
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.momentumGold.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func premiumFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.momentumSecondaryText)
                .frame(width: 24)
            Text(text)
                .font(MomentumFont.body(15))
                .foregroundColor(.momentumSecondaryText)
        }
    }

    // MARK: - Monthly Progress Card
    private var monthlyProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Progress")
                .font(MomentumFont.bodyMedium(16))
                .foregroundColor(.white)

            let monthlyData: [(String, Int)] = [("Week 1", 12), ("Week 2", 15), ("Week 3", 18), ("Week 4", 21)]

            Chart {
                ForEach(monthlyData, id: \.0) { week, tasks in
                    LineMark(
                        x: .value("Week", week),
                        y: .value("Tasks", tasks)
                    )
                    .foregroundStyle(Color.momentumGreenStart)
                    .lineStyle(StrokeStyle(lineWidth: 3))

                    AreaMark(
                        x: .value("Week", week),
                        y: .value("Tasks", tasks)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.momentumGreenStart.opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    PointMark(
                        x: .value("Week", week),
                        y: .value("Tasks", tasks)
                    )
                    .foregroundStyle(Color.momentumGreenStart)
                }
            }
            .frame(height: 120)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.momentumSecondaryText)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.momentumSecondaryText)
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.1))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Achievements Section
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(MomentumFont.bodyMedium(16))
                .foregroundColor(.white)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(BadgeType.allCases, id: \.self) { badge in
                        let isUnlocked = MockDataService.shared.mockAchievements.contains { $0.badgeType == badge }
                        achievementBadge(badge: badge, isUnlocked: isUnlocked)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func achievementBadge(badge: BadgeType, isUnlocked: Bool) -> some View {
        VStack(spacing: 8) {
            Text(badge.emoji)
                .font(.system(size: 32))
                .opacity(isUnlocked ? 1.0 : 0.3)

            Text(badge.title)
                .font(MomentumFont.body(12))
                .foregroundColor(isUnlocked ? .white : .momentumSecondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80, height: 100)
        .padding()
        .background(Color.white.opacity(isUnlocked ? 0.1 : 0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isUnlocked ? Color.momentumGold : Color.clear,
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    StatsView()
        .environmentObject({
            let state = AppState()
            state.loadMockData()
            return state
        }())
}
