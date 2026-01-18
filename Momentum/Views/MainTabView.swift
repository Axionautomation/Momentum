//
//  MainTabView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI
import PhosphorSwift

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Current view based on selection
            Group {
                switch appState.selectedTab {
                case .today:
                    TodayView()
                case .journey:
                    JourneyView()
                case .goals:
                    GoalsView()
                case .progress:
                    ProgressView()
                }
            }
            .transition(.opacity)

            // Floating Navigation Bar + AI Button (bottom)
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    // Custom Floating Tab Bar
                    FloatingTabBar()

                    // Floating AI Button
                    FloatingAIButton()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 0)
            }
            .ignoresSafeArea(.keyboard)
        }
        .sheet(isPresented: $appState.showGlobalChat) {
            GlobalAIChatView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Floating Tab Bar

struct FloatingTabBar: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppState.Tab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(hex: "1E293B"))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(Color.momentumSurfaceDivider.opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }

    private func tabButton(for tab: AppState.Tab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                appState.selectedTab = tab
            }
        } label: {
            VStack(spacing: 3) {
                tabIcon(for: tab)
                    .color(appState.selectedTab == tab ? .momentumViolet : .momentumSecondaryText)
                    .frame(width: 18, height: 18)

                Text(tab.rawValue)
                    .font(MomentumFont.body(9))
                    .foregroundColor(appState.selectedTab == tab ? .momentumViolet : .momentumSecondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func tabIcon(for tab: AppState.Tab) -> Image {
        switch tab.icon {
        case "sun":
            return Ph.sun.bold
        case "road":
            return Ph.roadHorizon.bold
        case "target":
            return Ph.target.bold
        case "chart":
            return Ph.chartBar.bold
        default:
            return Ph.house.bold
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
