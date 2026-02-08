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
    @State private var chatPanelOffset: CGFloat = 1000
    @State private var showChatPanel: Bool = false
    @State private var screenHeight: CGFloat = 1000

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark background
                Color.momentumBackground
                    .ignoresSafeArea()

                // Current view based on selection
                Group {
                    switch appState.selectedTab {
                    case .dashboard:
                        HomeView()
                    case .goals:
                        ProcessView()
                    case .profile:
                        ProfileView()
                    }
                }
                .transition(.opacity)

                // Chat overlay panel
                if showChatPanel {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissChat()
                        }
                        .transition(.opacity)

                    GlobalAIChatView(isOverlay: true, onDismiss: {
                        dismissChat()
                    })
                    .ignoresSafeArea(.container, edges: .bottom)
                    .shadow(color: .black.opacity(0.5), radius: 30, y: -10)
                    .offset(y: chatPanelOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if value.translation.height > 0 {
                                    chatPanelOffset = value.translation.height
                                }
                            }
                            .onEnded { value in
                                if value.translation.height > 150 {
                                    dismissChat()
                                } else {
                                    withAnimation(MomentumAnimation.smoothSpring) {
                                        chatPanelOffset = 0
                                    }
                                }
                            }
                    )
                    .transition(.move(edge: .bottom))
                }

                // Floating Navigation Bar + AI Button (bottom)
                if !showChatPanel {
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            FloatingTabBar()
                            FloatingAIButton()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 0)
                    }
                }
            }
            .onAppear {
                screenHeight = geometry.size.height
                chatPanelOffset = screenHeight
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: appState.showGlobalChat) { _, show in
            if show {
                presentChat()
            } else {
                dismissChat()
            }
        }
    }

    private func presentChat() {
        showChatPanel = true
        withAnimation(MomentumAnimation.smoothSpring) {
            chatPanelOffset = 0
        }
    }

    private func dismissChat() {
        withAnimation(MomentumAnimation.smoothSpring) {
            chatPanelOffset = screenHeight
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            showChatPanel = false
            appState.showGlobalChat = false
        }
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
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
    }

    private func tabButton(for tab: AppState.Tab) -> some View {
        Button {
            withAnimation(MomentumAnimation.snappy) {
                appState.selectedTab = tab
            }
        } label: {
            VStack(spacing: 3) {
                tabIcon(for: tab)
                    .color(appState.selectedTab == tab ? .white : Color.momentumTextTertiary)
                    .frame(width: 20, height: 20)

                Text(tab.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(appState.selectedTab == tab ? .white : Color.momentumTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color.clear)
        }
        .buttonStyle(.plain)
    }

    private func tabIcon(for tab: AppState.Tab) -> Image {
        switch tab {
        case .dashboard:
            return Ph.house.bold
        case .goals:
            return Ph.target.bold
        case .profile:
            return Ph.user.bold
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
