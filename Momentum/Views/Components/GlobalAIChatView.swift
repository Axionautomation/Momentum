//
//  GlobalAIChatView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/31/25.
//

import SwiftUI
import PhosphorSwift

struct GlobalAIChatView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var orchestrator = ConversationOrchestrator()
    @Environment(\.dismiss) var dismiss

    @State private var userInput: String = ""
    @State private var conversationHistory: [(question: String, answer: String)] = []
    @State private var clarificationAnswers: [String] = []
    @State private var showTaskPicker: Bool = false
    @FocusState private var isInputFocused: Bool

    var currentTask: MomentumTask? {
        appState.globalChatTaskContext
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.momentumDarkBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Task Context Header
                    if let task = currentTask {
                        taskContextHeader(task)
                    } else {
                        noTaskContextHeader
                    }

                    // Conversation Area
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                // Greeting
                                aiMessageBubble("Hi! I'm your AI companion. I can research things, help with tasks, and brainstorm ideas. What can I help you with?")

                                // Load conversation history if task context exists
                                if currentTask != nil {
                                    ForEach(conversationHistory.indices, id: \.self) { index in
                                        VStack(alignment: .trailing, spacing: 8) {
                                            userMessageBubble(conversationHistory[index].question)
                                            aiMessageBubble(conversationHistory[index].answer)
                                        }
                                    }
                                }

                                // Current conversation from orchestrator
                                ForEach(orchestrator.currentConversation) { message in
                                    if message.role == .user {
                                        userMessageBubble(message.content)
                                    } else if message.role == .assistant {
                                        aiMessageBubble(message.content)
                                    }
                                }

                                // Clarifying questions UI
                                if orchestrator.awaitingClarification {
                                    clarifyingQuestionsView
                                }

                                // Loading indicator
                                if orchestrator.isProcessing {
                                    HStack {
                                        ProgressView().tint(.momentumViolet)
                                        Text(orchestrator.awaitingClarification ? "Generating questions..." : "Researching...")
                                            .font(MomentumFont.body(14))
                                            .foregroundColor(.momentumSecondaryText)
                                    }
                                }
                            }
                            .padding()
                            .id("bottomOfConversation")
                        }
                        .onChange(of: orchestrator.currentConversation.count) {
                            withAnimation {
                                proxy.scrollTo("bottomOfConversation", anchor: .bottom)
                            }
                        }
                    }

                    // Input Area
                    inputSection
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveAndDismiss()
                    }
                    .foregroundColor(.momentumViolet)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            isInputFocused = true
            loadExistingConversation()
        }
        .sheet(isPresented: $showTaskPicker) {
            TaskPickerView { selectedTask in
                appState.switchChatTask(selectedTask)
                showTaskPicker = false
                loadExistingConversation()
            }
        }
    }

    // MARK: - Subviews

    private func taskContextHeader(_ task: MomentumTask) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Working on:")
                    .font(MomentumFont.body(12))
                    .foregroundColor(.momentumSecondaryText)
                Text(task.title)
                    .font(MomentumFont.bodyMedium(14))
                    .foregroundColor(.white)
            }

            Spacer()

            Button {
                showTaskPicker = true
            } label: {
                Text("Switch Task")
                    .font(MomentumFont.body(12))
                    .foregroundColor(.momentumViolet)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
    }

    private var noTaskContextHeader: some View {
        Button {
            showTaskPicker = true
        } label: {
            HStack {
                Ph.target.regular
                    .frame(width: 14, height: 14)
                Text("Select a task for context")
                    .font(MomentumFont.bodyMedium(14))
                Spacer()
                Ph.caretRight.regular
                    .frame(width: 14, height: 14)
            }
            .foregroundColor(.momentumViolet)
            .padding()
            .background(Color.momentumViolet.opacity(0.1))
        }
    }

    private var clarifyingQuestionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            aiMessageBubble("I have a few questions to help me research this better:")

            ForEach(Array(orchestrator.clarifyingQuestions.enumerated()), id: \.offset) { index, question in
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(index + 1). \(question)")
                        .font(MomentumFont.body(14))
                        .foregroundColor(.momentumSecondaryText)

                    TextField("Your answer...", text: Binding(
                        get: { clarificationAnswers.indices.contains(index) ? clarificationAnswers[index] : "" },
                        set: { newValue in
                            if clarificationAnswers.indices.contains(index) {
                                clarificationAnswers[index] = newValue
                            } else {
                                while clarificationAnswers.count <= index {
                                    clarificationAnswers.append("")
                                }
                                clarificationAnswers[index] = newValue
                            }
                        }
                    ))
                    .font(MomentumFont.body(14))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            Button {
                submitClarifications()
            } label: {
                HStack {
                    Ph.magnifyingGlass.regular
                        .frame(width: 14, height: 14)
                    Text("Start Research")
                }
                .font(MomentumFont.bodyMedium(14))
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(MomentumGradients.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(clarificationAnswers.count != orchestrator.clarifyingQuestions.count ||
                     clarificationAnswers.contains(where: { $0.isEmpty }))
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var inputSection: some View {
        HStack(spacing: 12) {
            TextField(orchestrator.awaitingClarification ? "Answer the questions above..." : "Ask me anything...", text: $userInput, axis: .vertical)
                .font(MomentumFont.body(16))
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .focused($isInputFocused)
                .disabled(orchestrator.isProcessing || orchestrator.awaitingClarification)
                .lineLimit(1...4)

            Button(action: sendMessage) {
                Ph.arrowCircleUp.fill
                    .frame(width: 32, height: 32)
                    .color(userInput.isEmpty || orchestrator.isProcessing ? .gray : .momentumViolet)
            }
            .disabled(userInput.isEmpty || orchestrator.isProcessing || orchestrator.awaitingClarification)
        }
        .padding()
        .background(Color.momentumDarkBackground)
    }

    // MARK: - Message Bubbles

    private func aiMessageBubble(_ text: String) -> some View {
        HStack {
            HStack(alignment: .top, spacing: 8) {
                ZStack {
                    Circle()
                        .fill(MomentumGradients.primary)
                        .frame(width: 28, height: 28)

                    Ph.sparkle.regular
                        .frame(width: 12, height: 12)
                        .color(.white)
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

    // MARK: - Actions

    private func loadExistingConversation() {
        guard let task = currentTask else {
            conversationHistory = []
            return
        }

        // Load conversation history from task notes
        conversationHistory = []

        var i = 0
        while i < task.notes.conversationHistory.count {
            let message = task.notes.conversationHistory[i]
            if message.role == .user {
                // Look for the next assistant message
                if i + 1 < task.notes.conversationHistory.count,
                   task.notes.conversationHistory[i + 1].role == .assistant {
                    conversationHistory.append((
                        question: message.content,
                        answer: task.notes.conversationHistory[i + 1].content
                    ))
                    i += 2
                } else {
                    i += 1
                }
            } else {
                i += 1
            }
        }

        // Reset orchestrator for fresh conversation
        orchestrator.reset()
    }

    private func sendMessage() {
        guard !userInput.isEmpty, let task = currentTask else {
            // If no task context, prompt to select one
            if currentTask == nil {
                showTaskPicker = true
            }
            return
        }

        let message = userInput
        userInput = ""

        Task {
            do {
                let update = try await orchestrator.processUserMessage(
                    message,
                    taskContext: task,
                    existingConversation: task.notes.conversationHistory
                )

                await MainActor.run {
                    // Save all new messages to task notes
                    for msg in update.newMessages {
                        appState.addConversationMessage(taskId: task.id, message: msg)
                    }

                    // Update local conversation display if it's simple Q&A
                    if !update.requiresClarification,
                       let userMsg = update.newMessages.first(where: { $0.role == .user }),
                       let aiMsg = update.newMessages.first(where: { $0.role == .assistant }) {
                        conversationHistory.append((question: userMsg.content, answer: aiMsg.content))
                    }

                    // Save research finding if present
                    if let finding = update.researchFinding {
                        appState.addResearchFinding(taskId: task.id, finding: finding)
                    }

                    // Handle clarification request
                    if update.requiresClarification {
                        clarificationAnswers = []
                    }
                }
            } catch {
                print("Error processing message: \(error)")
                await MainActor.run {
                    conversationHistory.append((
                        question: message,
                        answer: "Sorry, I couldn't process that. Please check your internet connection and API configuration."
                    ))
                }
            }
        }
    }

    private func submitClarifications() {
        guard let task = currentTask else { return }

        // Build Q&A pairs
        let qaPairs = zip(orchestrator.clarifyingQuestions, clarificationAnswers).map {
            QAPair(question: $0, answer: $1)
        }

        // Get the original query
        guard let query = orchestrator.currentConversation.first(where: { $0.role == .user })?.content else {
            return
        }

        Task {
            do {
                let finding = try await orchestrator.performResearch(
                    query: query,
                    clarifications: qaPairs,
                    taskContext: task
                )

                await MainActor.run {
                    // Save research finding
                    appState.addResearchFinding(taskId: task.id, finding: finding)

                    // Add result to conversation display
                    conversationHistory.append((
                        question: query,
                        answer: finding.searchResults
                    ))

                    // Save the research result message
                    let resultMessage = ConversationMessage(
                        role: .assistant,
                        content: finding.searchResults,
                        metadata: MessageMetadata(
                            messageType: .researchResult,
                            relatedResearchId: finding.id
                        )
                    )
                    appState.addConversationMessage(taskId: task.id, message: resultMessage)

                    // Reset clarification state
                    clarificationAnswers = []
                }
            } catch {
                print("Error performing research: \(error)")
                await MainActor.run {
                    conversationHistory.append((
                        question: query,
                        answer: "Sorry, I couldn't complete the research. Please check your API configuration and try again."
                    ))
                }
            }
        }
    }

    private func saveAndDismiss() {
        // Conversation already auto-saved to task notes
        appState.closeGlobalChat()
        dismiss()
    }
}

#Preview {
    GlobalAIChatView()
        .environmentObject({
            let state = AppState()
            state.loadMockData()
            return state
        }())
}
