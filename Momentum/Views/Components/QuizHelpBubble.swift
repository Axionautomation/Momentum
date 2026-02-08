//
//  QuizHelpBubble.swift
//  Momentum
//
//  Created by Henry Bowman on 2/3/26.
//

import SwiftUI
import PhosphorSwift

struct QuizHelpBubble: View {
    let question: SkillQuestion
    let goalContext: String
    let onSelectOption: (String) -> Void
    let onDismiss: () -> Void

    @StateObject private var viewModel = QuizHelpViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Ph.sparkle.fill
                        .frame(width: 20, height: 20)
                        .foregroundColor(.momentumViolet)

                    Text("Help me choose")
                        .font(MomentumFont.bodyMedium())
                        .foregroundColor(.momentumTextPrimary)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Ph.x.regular
                        .frame(width: 20, height: 20)
                        .foregroundColor(.momentumTextSecondary)
                }
            }
            .padding(.horizontal, MomentumSpacing.standard)
            .padding(.vertical, MomentumSpacing.compact)
            .background(Color.momentumBackgroundSecondary)

            Divider()
                .background(Color.momentumCardBorder)

            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: MomentumSpacing.compact) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }

                        if viewModel.isLoading {
                            LoadingBubble()
                                .id("loading")
                        }

                        if let error = viewModel.errorMessage {
                            ErrorBubble(message: error)
                        }
                    }
                    .padding(MomentumSpacing.standard)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.isLoading) { _, isLoading in
                    if isLoading {
                        withAnimation {
                            proxy.scrollTo("loading", anchor: .bottom)
                        }
                    }
                }
            }
            .frame(maxHeight: 180)

            Divider()
                .background(Color.momentumCardBorder)

            // Quick option buttons
            VStack(spacing: MomentumSpacing.compact) {
                Text("Quick select:")
                    .font(MomentumFont.caption())
                    .foregroundColor(.momentumTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: MomentumSpacing.tight) {
                    ForEach(question.options, id: \.self) { option in
                        Button {
                            SoundManager.shared.successHaptic()
                            onSelectOption(option)
                        } label: {
                            Text(option)
                                .font(MomentumFont.caption())
                                .foregroundColor(.momentumBlue)
                                .lineLimit(1)
                                .padding(.horizontal, MomentumSpacing.compact)
                                .padding(.vertical, MomentumSpacing.tight)
                                .background(Color.momentumBlue.opacity(0.1))
                                .cornerRadius(MomentumRadius.small)
                        }
                    }
                }
            }
            .padding(.horizontal, MomentumSpacing.standard)
            .padding(.vertical, MomentumSpacing.compact)
            .background(Color.momentumBackgroundSecondary)

            Divider()
                .background(Color.momentumCardBorder)

            // Input field
            HStack(spacing: MomentumSpacing.tight) {
                TextField("Ask a follow-up question...", text: $viewModel.inputText)
                    .font(MomentumFont.body())
                    .foregroundColor(.momentumTextPrimary)
                    .focused($isInputFocused)
                    .onSubmit {
                        Task {
                            await viewModel.sendMessage()
                        }
                    }

                Button {
                    Task {
                        await viewModel.sendMessage()
                    }
                } label: {
                    Ph.paperPlaneTilt.fill
                        .frame(width: 20, height: 20)
                        .foregroundColor(viewModel.inputText.isEmpty ? .momentumTextTertiary : .momentumBlue)
                }
                .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal, MomentumSpacing.standard)
            .padding(.vertical, MomentumSpacing.compact)
        }
        .background(Color.momentumCardBackground)
        .cornerRadius(MomentumRadius.medium)
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: MomentumRadius.medium)
                .stroke(Color.momentumCardBorder, lineWidth: 1)
        )
        .onAppear {
            viewModel.setup(question: question, goalContext: goalContext)
        }
        .onDisappear {
            viewModel.reset()
        }
    }
}

// MARK: - Chat Bubble

private struct ChatBubble: View {
    let message: QuizHelpMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 40)
            }

            Text(message.content)
                .font(MomentumFont.body(14))
                .foregroundColor(message.role == .user ? .white : .momentumTextPrimary)
                .padding(.horizontal, MomentumSpacing.compact)
                .padding(.vertical, MomentumSpacing.tight)
                .background(
                    message.role == .user
                        ? Color.momentumBlue
                        : Color.momentumBackgroundSecondary
                )
                .cornerRadius(MomentumRadius.small)

            if message.role == .assistant {
                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Loading Bubble

private struct LoadingBubble: View {
    @State private var animating = false

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.momentumTextTertiary)
                        .frame(width: 6, height: 6)
                        .scaleEffect(animating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(Double(index) * 0.15),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, MomentumSpacing.compact)
            .padding(.vertical, MomentumSpacing.tight)
            .background(Color.momentumBackgroundSecondary)
            .cornerRadius(MomentumRadius.small)

            Spacer(minLength: 40)
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Error Bubble

private struct ErrorBubble: View {
    let message: String

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Ph.warning.regular
                    .frame(width: 14, height: 14)
                    .foregroundColor(.momentumWarning)

                Text(message)
                    .font(MomentumFont.caption())
                    .foregroundColor(.momentumTextSecondary)
            }
            .padding(.horizontal, MomentumSpacing.compact)
            .padding(.vertical, MomentumSpacing.tight)
            .background(Color.momentumWarning.opacity(0.1))
            .cornerRadius(MomentumRadius.small)

            Spacer(minLength: 40)
        }
    }
}

#Preview {
    ZStack {
        Color.momentumBackground
            .ignoresSafeArea()

        QuizHelpBubble(
            question: SkillQuestion(
                taskId: UUID(),
                skill: "coding",
                question: "What's your experience level with Swift programming?",
                options: ["Beginner", "Intermediate", "Advanced", "Expert"]
            ),
            goalContext: "Build an iOS app",
            onSelectOption: { _ in },
            onDismiss: {}
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
