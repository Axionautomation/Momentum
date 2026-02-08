//
//  DataPrivacyView.swift
//  Momentum
//
//  Created by Henry Bowman on 2/8/26.
//

import SwiftUI
import PhosphorSwift

struct DataPrivacyView: View {
    @EnvironmentObject var appState: AppState
    @State private var appeared = false
    @State private var showClearChatConfirmation = false
    @State private var showClearMemoryConfirmation = false
    @State private var showDeleteAllConfirmation = false
    @State private var showExportSheet = false
    @State private var exportedData: String = ""

    var body: some View {
        ZStack {
            Color.momentumBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: MomentumSpacing.section) {
                    // Export Section
                    VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
                        HStack(spacing: MomentumSpacing.tight) {
                            Ph.export.fill
                                .frame(width: 20, height: 20)
                                .foregroundColor(.momentumBlue)

                            Text("Export Data")
                                .font(MomentumFont.headingMedium())
                                .foregroundColor(.momentumTextPrimary)
                        }

                        Text("Download a copy of your data in JSON format.")
                            .font(MomentumFont.caption())
                            .foregroundColor(.momentumTextSecondary)

                        DataActionButton(
                            icon: Ph.fileArrowDown.regular,
                            title: "Export My Data",
                            subtitle: "Goals, tasks, progress, and settings",
                            color: .momentumBlue,
                            index: 0,
                            appeared: appeared
                        ) {
                            exportAllData()
                        }

                        DataActionButton(
                            icon: Ph.brain.regular,
                            title: "Download AI Memory",
                            subtitle: "\(appState.aiMemoryEntries.count) memory entries",
                            color: .momentumViolet,
                            index: 1,
                            appeared: appeared
                        ) {
                            exportAIMemory()
                        }
                    }
                    .padding(MomentumSpacing.standard)
                    .momentumCard()
                    .padding(.horizontal, MomentumSpacing.comfortable)
                    .padding(.top, MomentumSpacing.standard)

                    // Clear Data Section
                    VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
                        HStack(spacing: MomentumSpacing.tight) {
                            Ph.eraser.fill
                                .frame(width: 20, height: 20)
                                .foregroundColor(.momentumWarning)

                            Text("Clear Data")
                                .font(MomentumFont.headingMedium())
                                .foregroundColor(.momentumTextPrimary)
                        }

                        DataActionButton(
                            icon: Ph.chatCircleDots.regular,
                            title: "Clear Chat History",
                            subtitle: "Remove all AI conversation logs",
                            color: .momentumWarning,
                            index: 2,
                            appeared: appeared
                        ) {
                            showClearChatConfirmation = true
                        }

                        DataActionButton(
                            icon: Ph.brain.regular,
                            title: "Clear AI Memory",
                            subtitle: "Remove all learned preferences",
                            color: .momentumWarning,
                            index: 3,
                            appeared: appeared
                        ) {
                            showClearMemoryConfirmation = true
                        }
                    }
                    .padding(MomentumSpacing.standard)
                    .momentumCard()
                    .padding(.horizontal, MomentumSpacing.comfortable)
                    .offset(y: appeared ? 0 : 30)
                    .opacity(appeared ? 1 : 0)

                    // Danger Zone
                    VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
                        HStack(spacing: MomentumSpacing.tight) {
                            Ph.warning.fill
                                .frame(width: 20, height: 20)
                                .foregroundColor(.momentumDanger)

                            Text("Danger Zone")
                                .font(MomentumFont.headingMedium())
                                .foregroundColor(.momentumDanger)
                        }

                        DataActionButton(
                            icon: Ph.trash.regular,
                            title: "Delete All Data",
                            subtitle: "Permanently erase everything",
                            color: .momentumDanger,
                            isDestructive: true,
                            index: 4,
                            appeared: appeared
                        ) {
                            showDeleteAllConfirmation = true
                        }
                    }
                    .padding(MomentumSpacing.standard)
                    .background(Color.momentumDanger.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: MomentumRadius.medium)
                            .strokeBorder(Color.momentumDanger.opacity(0.2), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
                    .padding(.horizontal, MomentumSpacing.comfortable)
                    .offset(y: appeared ? 0 : 40)
                    .opacity(appeared ? 1 : 0)

                    // App Info
                    VStack(spacing: MomentumSpacing.tight) {
                        Text("Momentum v1.0.0")
                            .font(MomentumFont.caption())
                            .foregroundColor(.momentumTextTertiary)

                        Text("Build 1")
                            .font(MomentumFont.caption(11))
                            .foregroundColor(.momentumTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, MomentumSpacing.standard)

                    Spacer(minLength: 100)
                }
            }
        }
        .navigationTitle("Data & Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            withAnimation(MomentumAnimation.smoothSpring.delay(0.1)) {
                appeared = true
            }
        }
        .alert("Clear Chat History", isPresented: $showClearChatConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                appState.clearChatHistory()
            }
        } message: {
            Text("This will remove all conversation history from your tasks. This cannot be undone.")
        }
        .alert("Clear AI Memory", isPresented: $showClearMemoryConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                appState.clearAllMemoryEntries()
            }
        } message: {
            Text("This will remove all AI memory entries. The AI will need to relearn your preferences.")
        }
        .alert("Delete All Data", isPresented: $showDeleteAllConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Everything", role: .destructive) {
                appState.resetOnboarding()
            }
        } message: {
            Text("This will permanently delete all your goals, tasks, progress, AI memory, and settings. This CANNOT be undone.")
        }
        .sheet(isPresented: $showExportSheet) {
            ShareSheet(text: exportedData)
        }
    }

    private func exportAllData() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        var exportDict: [String: Any] = [:]

        if let user = appState.currentUser, let data = try? encoder.encode(user) {
            exportDict["user"] = String(data: data, encoding: .utf8) ?? ""
        }
        if let data = try? encoder.encode(appState.goals) {
            exportDict["goals"] = String(data: data, encoding: .utf8) ?? ""
        }
        if let data = try? encoder.encode(appState.achievements) {
            exportDict["achievements"] = String(data: data, encoding: .utf8) ?? ""
        }
        if let data = try? encoder.encode(appState.aiMemoryEntries) {
            exportDict["aiMemory"] = String(data: data, encoding: .utf8) ?? ""
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted) {
            exportedData = String(data: jsonData, encoding: .utf8) ?? "{}"
        } else {
            exportedData = "{}"
        }
        showExportSheet = true
    }

    private func exportAIMemory() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        if let data = try? encoder.encode(appState.aiMemoryEntries) {
            exportedData = String(data: data, encoding: .utf8) ?? "[]"
        } else {
            exportedData = "[]"
        }
        showExportSheet = true
    }
}

// MARK: - Data Action Button

struct DataActionButton: View {
    let icon: Image
    let title: String
    let subtitle: String
    let color: Color
    var isDestructive: Bool = false
    let index: Int
    let appeared: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MomentumSpacing.compact) {
                ZStack {
                    RoundedRectangle(cornerRadius: MomentumRadius.small)
                        .fill(color.opacity(0.12))
                        .frame(width: 36, height: 36)

                    icon
                        .frame(width: 18, height: 18)
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MomentumFont.bodyMedium())
                        .foregroundColor(isDestructive ? .momentumDanger : .momentumTextPrimary)

                    Text(subtitle)
                        .font(MomentumFont.caption())
                        .foregroundColor(.momentumTextSecondary)
                }

                Spacer()

                Ph.caretRight.regular
                    .frame(width: 14, height: 14)
                    .foregroundColor(.momentumTextTertiary)
            }
            .padding(MomentumSpacing.compact)
            .background(Color.momentumSurface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.small))
        }
        .buttonStyle(.plain)
        .offset(y: appeared ? 0 : 20)
        .opacity(appeared ? 1 : 0)
        .animation(MomentumAnimation.staggered(index: index), value: appeared)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let data = text.data(using: .utf8) ?? Data()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("momentum_export.json")
        try? data.write(to: tempURL)
        return UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        DataPrivacyView()
            .environmentObject(AppState())
    }
    .preferredColorScheme(.dark)
}
