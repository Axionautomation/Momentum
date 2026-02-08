//
//  AchievementsView.swift
//  Momentum
//
//  Created by Henry Bowman on 2/8/26.
//

import SwiftUI
import PhosphorSwift

struct AchievementsView: View {
    @EnvironmentObject var appState: AppState
    @State private var appeared = false

    private let columns = [
        GridItem(.flexible(), spacing: MomentumSpacing.compact),
        GridItem(.flexible(), spacing: MomentumSpacing.compact)
    ]

    private var unlockedBadges: Set<BadgeType> {
        Set(appState.achievements.map { $0.badgeType })
    }

    private func unlockDate(for badge: BadgeType) -> Date? {
        appState.achievements.first { $0.badgeType == badge }?.unlockedAt
    }

    var body: some View {
        ZStack {
            Color.momentumBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: MomentumSpacing.section) {
                    // Summary header
                    VStack(spacing: MomentumSpacing.tight) {
                        Text("\(appState.achievements.count)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(MomentumGradients.primary)

                        Text("of \(BadgeType.allCases.count) achievements unlocked")
                            .font(MomentumFont.body())
                            .foregroundColor(.momentumTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, MomentumSpacing.standard)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)

                    // Achievement grid
                    LazyVGrid(columns: columns, spacing: MomentumSpacing.compact) {
                        ForEach(Array(BadgeType.allCases.enumerated()), id: \.element) { index, badge in
                            AchievementCard(
                                badge: badge,
                                isUnlocked: unlockedBadges.contains(badge),
                                unlockDate: unlockDate(for: badge)
                            )
                            .offset(y: appeared ? 0 : 30)
                            .opacity(appeared ? 1 : 0)
                            .animation(MomentumAnimation.staggered(index: index), value: appeared)
                        }
                    }
                    .padding(.horizontal, MomentumSpacing.comfortable)

                    Spacer(minLength: 100)
                }
            }
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            withAnimation(MomentumAnimation.smoothSpring.delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let badge: BadgeType
    let isUnlocked: Bool
    let unlockDate: Date?

    @State private var showGlow = false

    private var formattedDate: String {
        guard let date = unlockDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: MomentumSpacing.compact) {
            // Icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? badge.accentColor.opacity(0.15) : Color.momentumSurface)
                    .frame(width: 56, height: 56)

                if isUnlocked {
                    Circle()
                        .fill(badge.accentColor.opacity(showGlow ? 0.3 : 0.1))
                        .frame(width: 56, height: 56)
                        .blur(radius: 8)
                }

                Image(systemName: badge.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(isUnlocked ? badge.accentColor : .momentumTextTertiary)

                if !isUnlocked {
                    // Lock overlay
                    Circle()
                        .fill(Color.momentumBackground.opacity(0.5))
                        .frame(width: 56, height: 56)

                    Ph.lock.fill
                        .frame(width: 18, height: 18)
                        .foregroundColor(.momentumTextTertiary)
                }
            }

            // Title
            Text(badge.title)
                .font(MomentumFont.label())
                .foregroundColor(isUnlocked ? .momentumTextPrimary : .momentumTextTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Description or "???"
            Text(isUnlocked ? badge.description : "???")
                .font(MomentumFont.caption(11))
                .foregroundColor(.momentumTextSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 28)

            // Unlock date
            if isUnlocked, let _ = unlockDate {
                Text(formattedDate)
                    .font(MomentumFont.caption(10))
                    .foregroundColor(.momentumTextTertiary)
            }
        }
        .padding(MomentumSpacing.compact)
        .frame(maxWidth: .infinity)
        .background(Color.momentumBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: MomentumRadius.medium)
                .strokeBorder(
                    isUnlocked ? badge.accentColor.opacity(0.3) : Color.momentumCardBorder,
                    lineWidth: isUnlocked ? 1 : 0.5
                )
        )
        .shadow(
            color: isUnlocked ? badge.accentColor.opacity(0.15) : .clear,
            radius: 8, y: 2
        )
        .onAppear {
            if isUnlocked {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    showGlow = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
            .environmentObject(AppState())
    }
    .preferredColorScheme(.dark)
}
