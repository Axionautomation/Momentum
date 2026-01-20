//
//  ProfileView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI
import PhosphorSwift

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Card
                        profileCard

                        // Settings Section
                        settingsSection

                        // Support Section
                        supportSection

                        // Log Out Button
                        Button {
                            appState.resetOnboarding()
                        } label: {
                            Text("Log Out")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
    }

    // MARK: - Profile Card
    private var profileCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.gray)

            VStack(spacing: 4) {
                Text("User")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)

                Text(appState.currentUser?.email ?? "user@example.com")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)

                if let createdAt = appState.currentUser?.createdAt {
                    Text("Member since \(createdAt.formatted(.dateTime.month().year()))")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
                .padding(.horizontal)

            VStack(spacing: 0) {
                settingsRow(icon: "bell.fill", title: "Notifications")
                Divider()
                settingsRow(icon: "moon.fill", title: "Appearance")
            }
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }

    private func settingsRow(icon: String, title: String) -> some View {
        Button {
            // Action
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.black)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .padding()
        }
    }

    // MARK: - Support Section
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Support")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
                .padding(.horizontal)

            VStack(spacing: 0) {
                supportRow(title: "Help & Tutorials")
                Divider()
                supportRow(title: "Contact Support")
                Divider()
                supportRow(title: "Privacy Policy")
                Divider()
                supportRow(title: "Terms of Service")
            }
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }

    private func supportRow(title: String) -> some View {
        Button {
            // Action
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .padding()
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}
