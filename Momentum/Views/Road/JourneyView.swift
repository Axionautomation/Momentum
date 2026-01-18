//
//  JourneyView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI
import PhosphorSwift

struct JourneyView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedPowerGoal: PowerGoal?
    @State private var showProfile = false

    var body: some View {
        ZStack {
            Color.momentumDarkBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header with profile icon
                    HStack {
                        Text("Your Journey")
                            .font(MomentumFont.heading(20))
                            .foregroundColor(.white)

                        Spacer()

                        Button {
                            showProfile = true
                        } label: {
                            Ph.userCircle.fill
                                .color(.momentumSecondaryText)
                                .frame(width: 28, height: 28)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Vision at Top (Goal)
                    goalDestination
                        .padding(.top, 24)

                    // Road with Power Goals
                    roadWithPowerGoals
                        .padding(.top, 24)

                    // Stats Card at Bottom
                    statsCard
                        .padding(.top, 32)
                        .padding(.bottom, 100)
                }
            }
        }
        .sheet(item: $selectedPowerGoal) { powerGoal in
            PowerGoalDetailSheet(powerGoal: powerGoal)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showProfile) {
            ProfileView()
        }
    }

    // MARK: - Goal Destination
    private var goalDestination: some View {
        VStack(spacing: 12) {
            Text("")
                .font(.system(size: 40))

            Text(appState.activeProjectGoal?.visionRefined ?? "Your Vision")
                .font(MomentumFont.heading(22))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [.momentumGold.opacity(0.3), .momentumGoldLight.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [.momentumGold, .momentumGoldLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .momentumGold.opacity(0.3), radius: 20, y: 10)
        .padding(.horizontal)
    }

    // MARK: - Road with Power Goals
    private var roadWithPowerGoals: some View {
        VStack(spacing: 0) {
            ForEach(Array((appState.activeProjectGoal?.powerGoals ?? []).enumerated().reversed()), id: \.element.id) { index, powerGoal in
                VStack(spacing: 0) {
                    // Road segment
                    roadSegment(isLeft: index % 2 == 0)

                    // Power Goal Node
                    powerGoalNode(powerGoal: powerGoal, index: index)
                        .onTapGesture {
                            selectedPowerGoal = powerGoal
                        }
                }
            }
        }
    }

    private func roadSegment(isLeft: Bool) -> some View {
        GeometryReader { geo in
            Path { path in
                let width = geo.size.width
                let height: CGFloat = 60

                if isLeft {
                    path.move(to: CGPoint(x: width * 0.5, y: 0))
                    path.addQuadCurve(
                        to: CGPoint(x: width * 0.35, y: height),
                        control: CGPoint(x: width * 0.35, y: height * 0.5)
                    )
                } else {
                    path.move(to: CGPoint(x: width * 0.5, y: 0))
                    path.addQuadCurve(
                        to: CGPoint(x: width * 0.65, y: height),
                        control: CGPoint(x: width * 0.65, y: height * 0.5)
                    )
                }
            }
            .stroke(Color.momentumSecondaryText.opacity(0.3), lineWidth: 4)
        }
        .frame(height: 60)
    }

    private func powerGoalNode(powerGoal: PowerGoal, index: Int) -> some View {
        let isActive = powerGoal.status == .active
        let isCompleted = powerGoal.status == .completed
        let isCurrent = index == appState.activeProjectGoal?.currentPowerGoalIndex

        return HStack {
            if index % 2 == 0 {
                Spacer()
            }

            VStack(spacing: 8) {
                // Node Circle
                ZStack {
                    Circle()
                        .fill(
                            isCompleted ? Color.momentumGreenStart :
                            isActive ? Color.momentumViolet :
                            Color.momentumSecondaryText.opacity(0.3)
                        )
                        .frame(width: 50, height: 50)

                    if isCompleted {
                        Ph.check.regular
                            .color(.white)
                            .frame(width: 20, height: 20)
                    } else {
                        Text("\(powerGoal.monthNumber)")
                            .font(MomentumFont.stats(18))
                            .foregroundColor(.white)
                    }

                    // User pin for current position
                    if isCurrent && isActive {
                        Ph.mapPin.fill
                            .color(.momentumCoral)
                            .frame(width: 24, height: 24)
                            .offset(x: 30, y: -20)
                    }
                }

                // Power Goal Title
                VStack(spacing: 2) {
                    Text("Month \(powerGoal.monthNumber)")
                        .font(MomentumFont.body(12))
                        .foregroundColor(.momentumSecondaryText)

                    Text(powerGoal.title)
                        .font(MomentumFont.bodyMedium(14))
                        .foregroundColor(isActive || isCompleted ? .white : .momentumSecondaryText)
                        .lineLimit(1)
                }
            }
            .padding()
            .background(
                isActive ? Color.momentumViolet.opacity(0.15) :
                isCompleted ? Color.momentumGreenStart.opacity(0.1) :
                Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isActive ? Color.momentumViolet : Color.clear,
                        lineWidth: 2
                    )
            )

            if index % 2 != 0 {
                Spacer()
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Stats Card
    private var statsCard: some View {
        VStack(spacing: 16) {
            // Streak Display
            HStack {
                Text("Streak:")
                    .font(MomentumFont.body(16))
                    .foregroundColor(.momentumSecondaryText)

                HStack(spacing: 4) {
                    Text("")
                    Text("\(appState.currentUser?.streakCount ?? 0) days")
                        .font(MomentumFont.stats(20))
                        .foregroundColor(.white)
                }
            }

            // Speedometer
            SpeedometerView(streakDays: appState.currentUser?.streakCount ?? 0)
                .frame(height: 100)

            // Progress to Power Goal
            VStack(spacing: 8) {
                Text("\(Int(appState.currentPowerGoalProgress * 100))% to Power Goal 1")
                    .font(MomentumFont.body(14))
                    .foregroundColor(.momentumSecondaryText)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(MomentumGradients.primary)
                            .frame(width: geo.size.width * appState.currentPowerGoalProgress)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(24)
        .background(Color.momentumSurfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.momentumSurfaceDivider, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        .padding(.horizontal)
    }
}

// MARK: - Speedometer View
struct SpeedometerView: View {
    let streakDays: Int

    private var needleRotation: Double {
        // Map streak days to rotation (0 to 180 degrees)
        let maxStreak: Double = 30
        let normalized = min(Double(streakDays), maxStreak) / maxStreak
        return -90 + (normalized * 180)
    }

    private var zoneColor: Color {
        switch streakDays {
        case 0..<8: return .momentumGold
        case 8..<21: return .momentumGreenStart
        default: return .momentumDeepBlue
        }
    }

    var body: some View {
        ZStack {
            // Background arc
            Circle()
                .trim(from: 0.25, to: 0.75)
                .stroke(Color.white.opacity(0.1), lineWidth: 12)
                .rotationEffect(.degrees(180))

            // Colored arc based on streak zone
            Circle()
                .trim(from: 0.25, to: 0.25 + (0.5 * min(Double(streakDays) / 30.0, 1.0)))
                .stroke(zoneColor, lineWidth: 12)
                .rotationEffect(.degrees(180))

            // Needle
            Rectangle()
                .fill(Color.white)
                .frame(width: 3, height: 40)
                .offset(y: -20)
                .rotationEffect(.degrees(needleRotation))

            // Center dot
            Circle()
                .fill(Color.white)
                .frame(width: 10, height: 10)

            // Days label
            Text("\(streakDays)")
                .font(MomentumFont.stats(24))
                .foregroundColor(.white)
                .offset(y: 30)
        }
    }
}

// MARK: - Power Goal Detail Sheet
struct PowerGoalDetailSheet: View {
    let powerGoal: PowerGoal
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.momentumDarkBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Month \(powerGoal.monthNumber)")
                            .font(MomentumFont.body(14))
                            .foregroundColor(.momentumSecondaryText)

                        Text(powerGoal.title)
                            .font(MomentumFont.heading(22))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    statusBadge
                }

                if let description = powerGoal.description {
                    Text(description)
                        .font(MomentumFont.body(16))
                        .foregroundColor(.momentumSecondaryText)
                }

                // Progress
                if powerGoal.status == .active {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(Int(powerGoal.completionPercentage * 100))% complete")
                            .font(MomentumFont.body(14))
                            .foregroundColor(.momentumSecondaryText)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(MomentumGradients.success)
                                    .frame(width: geo.size.width * powerGoal.completionPercentage)
                            }
                        }
                        .frame(height: 8)
                    }
                }

                // Weekly Milestones
                if !powerGoal.weeklyMilestones.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weekly Milestones")
                            .font(MomentumFont.bodyMedium(16))
                            .foregroundColor(.white)

                        ForEach(powerGoal.weeklyMilestones) { milestone in
                            HStack(spacing: 12) {
                                (milestone.status == .completed ? Ph.checkCircle.fill : Ph.circle.regular)
                                    .color(milestone.status == .completed ? .momentumGreenStart : .momentumSecondaryText)
                                    .frame(width: 20, height: 20)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Week \(milestone.weekNumber)")
                                        .font(MomentumFont.body(12))
                                        .foregroundColor(.momentumSecondaryText)
                                    Text(milestone.milestoneText)
                                        .font(MomentumFont.body(15))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(24)
        }
    }

    private var statusBadge: some View {
        Text(powerGoal.status.rawValue.capitalized)
            .font(MomentumFont.body(12))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                powerGoal.status == .completed ? Color.momentumGreenStart :
                powerGoal.status == .active ? Color.momentumViolet :
                Color.momentumSecondaryText
            )
            .clipShape(Capsule())
    }
}

#Preview {
    JourneyView()
        .environmentObject({
            let state = AppState()
            state.loadMockData()
            return state
        }())
}
