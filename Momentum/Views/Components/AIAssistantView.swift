//
//  AIAssistantView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/29/25.
//

import SwiftUI

struct AIAssistantView: View {
    @StateObject private var groqService = GroqService.shared
    @Environment(\.dismiss) var dismiss

    let task: MomentumTask
    @State private var userQuestion: String = ""
    @State private var aiResponse: String = ""
    @State private var isLoading: Bool = false
    @State private var conversationHistory: [(question: String, answer: String)] = []
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.momentumDarkBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Task Info Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Need help with this task?")
                            .font(MomentumFont.bodyMedium(14))
                            .foregroundColor(.momentumSecondaryText)

                        HStack {
                            Text(task.title)
                                .font(MomentumFont.heading(18))
                                .foregroundColor(.white)

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                Text("\(task.estimatedMinutes) min")
                            }
                            .font(MomentumFont.body(13))
                            .foregroundColor(.momentumSecondaryText)
                        }

                        if let description = task.description {
                            Text(description)
                                .font(MomentumFont.body(14))
                                .foregroundColor(.momentumSecondaryText)
                                .lineLimit(2)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))

                    // Conversation Area
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Initial AI greeting
                            aiMessageBubble(
                                "Hi! I'm here to help you with this task. What would you like to know?"
                            )

                            // Conversation history
                            ForEach(conversationHistory.indices, id: \.self) { index in
                                VStack(alignment: .trailing, spacing: 8) {
                                    userMessageBubble(conversationHistory[index].question)
                                    aiMessageBubble(conversationHistory[index].answer)
                                }
                            }

                            // Current loading state
                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .tint(.momentumViolet)
                                    Text("Thinking...")
                                        .font(MomentumFont.body(14))
                                        .foregroundColor(.momentumSecondaryText)
                                }
                                .padding(.leading)
                            }
                        }
                        .padding()
                    }

                    // Suggested Questions
                    if conversationHistory.isEmpty && !isLoading {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggested questions:")
                                .font(MomentumFont.bodyMedium(12))
                                .foregroundColor(.momentumSecondaryText)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    suggestedQuestionButton("How do I get started?")
                                    suggestedQuestionButton("What should I focus on?")
                                    suggestedQuestionButton("Any tips for this?")
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 8)
                    }

                    // Input Area
                    HStack(spacing: 12) {
                        TextField("Ask a question...", text: $userQuestion)
                            .font(MomentumFont.body(16))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .focused($isTextFieldFocused)
                            .disabled(isLoading)

                        Button(action: askQuestion) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(userQuestion.isEmpty ? .gray : .momentumViolet)
                        }
                        .disabled(userQuestion.isEmpty || isLoading)
                    }
                    .padding()
                    .background(Color.momentumDarkBackground)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(MomentumGradients.primary)
                        Text("AI Assistant")
                            .font(MomentumFont.heading(17))
                            .foregroundColor(.white)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.momentumViolet)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private func aiMessageBubble(_ text: String) -> some View {
        HStack {
            HStack(alignment: .top, spacing: 8) {
                ZStack {
                    Circle()
                        .fill(MomentumGradients.primary)
                        .frame(width: 28, height: 28)

                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }

                Text(text)
                    .font(MomentumFont.body(15))
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            Spacer()
        }
    }

    private func userMessageBubble(_ text: String) -> some View {
        HStack {
            Spacer()
            Text(text)
                .font(MomentumFont.body(15))
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(Color.momentumViolet.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func suggestedQuestionButton(_ question: String) -> some View {
        Button {
            userQuestion = question
            askQuestion()
        } label: {
            Text(question)
                .font(MomentumFont.body(13))
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func askQuestion() {
        guard !userQuestion.isEmpty else { return }

        let question = userQuestion
        userQuestion = ""
        isLoading = true

        Task {
            do {
                let response = try await groqService.getTaskHelp(
                    taskTitle: task.title,
                    taskDescription: task.description,
                    userQuestion: question
                )

                await MainActor.run {
                    conversationHistory.append((question: question, answer: response))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    conversationHistory.append((
                        question: question,
                        answer: "Sorry, I couldn't process that. Please try again or rephrase your question."
                    ))
                    isLoading = false
                }
                print("Error getting AI help: \(error)")
            }
        }
    }
}

#Preview {
    AIAssistantView(task: MomentumTask(
        weeklyMilestoneId: UUID(),
        goalId: UUID(),
        title: "Draft service packages",
        description: "Create 3-tier pricing structure for potential clients",
        difficulty: .medium,
        estimatedMinutes: 30,
        scheduledDate: Date()
    ))
}
