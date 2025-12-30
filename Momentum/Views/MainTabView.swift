//
//  MainTabView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            TodayView()
                .tabItem {
                    Label(AppState.Tab.today.rawValue, systemImage: AppState.Tab.today.icon)
                }
                .tag(AppState.Tab.today)

            RoadView()
                .tabItem {
                    Label(AppState.Tab.road.rawValue, systemImage: AppState.Tab.road.icon)
                }
                .tag(AppState.Tab.road)

            GoalsView()
                .tabItem {
                    Label(AppState.Tab.goals.rawValue, systemImage: AppState.Tab.goals.icon)
                }
                .tag(AppState.Tab.goals)

            StatsView()
                .tabItem {
                    Label(AppState.Tab.stats.rawValue, systemImage: AppState.Tab.stats.icon)
                }
                .tag(AppState.Tab.stats)

            ProfileView()
                .tabItem {
                    Label(AppState.Tab.me.rawValue, systemImage: AppState.Tab.me.icon)
                }
                .tag(AppState.Tab.me)
        }
        .tint(.momentumViolet)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
