//
//  GlobalAIChatView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/31/25.
//

import SwiftUI
import PhosphorSwift

struct GlobalAIChatView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Color.momentumBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Task context header (if applicable)
                    if let task = appState.globalChatTaskContext {
                        TaskContextHeader(task: task) {
                            appState.globalChatTaskContext = nil
                        }
                    }

                    // Chat messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: MomentumSpacing.compact) {
                                // AI Greeting
                                if viewModel.messages.isEmpty {
                                    GreetingBubble(
                                        message: viewModel.getGreeting()
                                    )
                                    .id("greeting")
                                }

                                // Messages
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(
                                        message: message,
                                        onCopy: { viewModel.copyMessage(message) }
                                    )
                                    .id(message.id)
                                }

                                // Thinking indicator
                                if viewModel.isLoading {
                                    ThinkingBubble()
                                        .id("thinking")
                                }
                            }
                            .padding(.horizontal, MomentumSpacing.standard)
                            .padding(.top, MomentumSpacing.standard)
                            .padding(.bottom, MomentumSpacing.section)
                        }
                        .onChange(of: viewModel.messages.count) { _ in
                            withAnimation {
                                if let lastMessage = viewModel.messages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel.isLoading) { isLoading in
                            if isLoading {
                                withAnimation {
                                    proxy.scrollTo("thinking", anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Suggested prompts
                    if viewModel.messages.isEmpty && !viewModel.isLoading {
                        SuggestedPromptsView(
                            prompts: viewModel.getSuggestedPrompts()
                        ) { prompt in
                            Task {
                                await viewModel.sendSuggestedPrompt(prompt)
                            }
                        }
                    }

                    // Input area
                    ChatInputView(
                        text: $viewModel.inputText,
                        isLoading: viewModel.isLoading,
                        isFocused: $isInputFocused
                    ) {
                        Task {
                            await viewModel.sendMessage()
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            viewModel.startNewChat()
                        } label: {
                            Label("New Chat", systemImage: "plus.bubble")
                        }

                        if !viewModel.messages.isEmpty {
                            Button {
                                viewModel.saveCurrentChat()
                            } label: {
                                Label("Save Chat", systemImage: "square.and.arrow.down")
                            }
                        }

                        if !viewModel.savedChats.isEmpty {
                            Divider()

                            ForEach(viewModel.savedChats.prefix(5)) { chat in
                                Button {
                                    viewModel.loadChat(chat)
                                } label: {
                                    Label(chat.title, systemImage: "bubble.left.and.bubble.right")
                                }
                            }

                            if viewModel.savedChats.count > 5 {
                                Button {
                                    viewModel.showSavedChats = true
                                } label: {
                                    Label("View All Chats", systemImage: "ellipsis")
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Ph.chats.regular
                                .frame(width: 20, height: 20)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(.momentumBlue)
                    }
                }

                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Ph.sparkle.fill
                            .frame(width: 18, height: 18)
                            .foregroundColor(.momentumBlue)

                        Text("AI Assistant")
                            .font(MomentumFont.bodyMedium())
                            .foregroundColor(.momentumTextPrimary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(MomentumFont.bodyMedium())
                    .foregroundColor(.momentumBlue)
                }
            }
            .onAppear {
                viewModel.taskContext = appState.globalChatTaskContext
            }
            .sheet(isPresented: $viewModel.showSavedChats) {
                SavedChatsListView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Task Context Header

struct TaskContextHeader: View {
    let task: MomentumTask
    let onDismiss: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Ph.target.regular
                        .frame(width: 16, height: 16)
                        .foregroundColor(.momentumBlue)

                    Text(task.title)
                        .font(MomentumFont.label())
                        .foregroundColor(.momentumTextPrimary)
                        .lineLimit(1)

                    Spacer()

                    Ph.caretDown.regular
                        .frame(width: 14, height: 14)
                        .foregroundColor(.momentumTextTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))

                    Button {
                        onDismiss()
                    } label: {
                        Ph.x.regular
                            .frame(width: 16, height: 16)
                            .foregroundColor(.momentumTextTertiary)
                    }
                }
                .padding(.horizontal, MomentumSpacing.standard)
                .padding(.vertical, MomentumSpacing.compact)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                    if let description = task.taskDescription {
                        Text(description)
                            .font(MomentumFont.body(14))
                            .foregroundColor(.momentumTextSecondary)
                    }

                    HStack(spacing: MomentumSpacing.compact) {
                        DifficultyBadge(difficulty: task.difficulty)

                        HStack(spacing: 4) {
                            Ph.clock.regular
                                .frame(width: 12, height: 12)
                            Text("\(task.estimatedMinutes) min")
                        }
                        .font(MomentumFont.caption())
                        .foregroundColor(.momentumTextSecondary)
                    }
                }
                .padding(.horizontal, MomentumSpacing.standard)
                .padding(.bottom, MomentumSpacing.compact)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()
                .background(Color.momentumCardBorder)
        }
        .background(Color.momentumBackgroundSecondary)
    }
}

// MARK: - Difficulty Badge

struct DifficultyBadge: View {
    let difficulty: TaskDifficulty

    private var color: Color {
        switch difficulty {
        case .easy: return .momentumEasy
        case .medium: return .momentumMedium
        case .hard: return .momentumHard
        }
    }

    var body: some View {
        Text(difficulty.displayName)
            .font(MomentumFont.caption())
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Greeting Bubble

struct GreetingBubble: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: MomentumSpacing.tight) {
            // AI Avatar
            AIAvatar()

            // Message bubble
            Text(message)
                .font(MomentumFont.body())
                .foregroundColor(.momentumTextPrimary)
                .padding(MomentumSpacing.compact)
                .background(Color.momentumBackgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
                .clipShape(ChatBubbleShape(isFromUser: false))

            Spacer(minLength: 60)
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    let onCopy: () -> Void

    @State private var showCopied = false

    var body: some View {
        HStack(alignment: .top, spacing: MomentumSpacing.tight) {
            if message.role == .user {
                Spacer(minLength: 60)
            } else {
                AIAvatar()
            }

            Text(message.content)
                .font(MomentumFont.body())
                .foregroundColor(message.role == .user ? .white : .momentumTextPrimary)
                .padding(MomentumSpacing.compact)
                .background(
                    message.role == .user
                        ? Color.momentumBlue
                        : Color.momentumBackgroundSecondary
                )
                .clipShape(ChatBubbleShape(isFromUser: message.role == .user))
                .contextMenu {
                    Button {
                        onCopy()
                        showCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showCopied = false
                        }
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
                .overlay(alignment: .bottom) {
                    if showCopied {
                        Text("Copied!")
                            .font(MomentumFont.caption())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Capsule())
                            .offset(y: 24)
                            .transition(.opacity.combined(with: .scale))
                    }
                }

            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showCopied)
    }
}

// MARK: - AI Avatar

struct AIAvatar: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.momentumBlue.opacity(0.15))
                .frame(width: 32, height: 32)

            Ph.sparkle.fill
                .frame(width: 16, height: 16)
                .foregroundColor(.momentumBlue)
        }
    }
}

// MARK: - Chat Bubble Shape

struct ChatBubbleShape: Shape {
    let isFromUser: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        let tailSize: CGFloat = 6

        var path = Path()

        if isFromUser {
            // User bubble - tail on right
            path.addRoundedRect(
                in: CGRect(x: 0, y: 0, width: rect.width - tailSize, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius)
            )
        } else {
            // AI bubble - tail on left
            path.addRoundedRect(
                in: CGRect(x: tailSize, y: 0, width: rect.width - tailSize, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius)
            )
        }

        return path
    }
}

// MARK: - Thinking Bubble

struct ThinkingBubble: View {
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        HStack(alignment: .top, spacing: MomentumSpacing.tight) {
            AIAvatar()

            VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                Text("Thinking...")
                    .font(MomentumFont.body())
                    .foregroundColor(.momentumTextSecondary)

                // Shimmer skeleton lines
                VStack(alignment: .leading, spacing: 6) {
                    ShimmerLine(width: 200)
                    ShimmerLine(width: 160)
                    ShimmerLine(width: 180)
                }
            }
            .padding(MomentumSpacing.compact)
            .background(Color.momentumBackgroundSecondary)
            .clipShape(ChatBubbleShape(isFromUser: false))

            Spacer(minLength: 60)
        }
    }
}

// MARK: - Shimmer Line

struct ShimmerLine: View {
    let width: CGFloat
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.momentumTextTertiary.opacity(0.3))
            .frame(width: width, height: 12)
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.4),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 60)
                .offset(x: shimmerOffset)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    shimmerOffset = width + 60
                }
            }
    }
}

// MARK: - Suggested Prompts

struct SuggestedPromptsView: View {
    let prompts: [String]
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MomentumSpacing.tight) {
                ForEach(prompts, id: \.self) { prompt in
                    Button {
                        onSelect(prompt)
                    } label: {
                        Text(prompt)
                            .font(MomentumFont.label())
                            .foregroundColor(.momentumBlue)
                            .padding(.horizontal, MomentumSpacing.compact)
                            .padding(.vertical, MomentumSpacing.tight)
                            .background(Color.momentumBlue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, MomentumSpacing.standard)
        }
        .padding(.bottom, MomentumSpacing.tight)
    }
}

// MARK: - Chat Input

struct ChatInputView: View {
    @Binding var text: String
    let isLoading: Bool
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.momentumCardBorder)

            HStack(alignment: .bottom, spacing: MomentumSpacing.compact) {
                // Expandable text field
                TextField("Message...", text: $text, axis: .vertical)
                    .font(MomentumFont.body())
                    .foregroundColor(.momentumTextPrimary)
                    .padding(.horizontal, MomentumSpacing.compact)
                    .padding(.vertical, MomentumSpacing.tight)
                    .background(Color.momentumBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
                    .lineLimit(1...5)
                    .focused(isFocused)

                // Send button
                Button {
                    onSend()
                } label: {
                    ZStack {
                        Circle()
                            .fill(canSend ? Color.momentumBlue : Color.momentumTextTertiary.opacity(0.3))
                            .frame(width: 36, height: 36)

                        Ph.paperPlaneTilt.fill
                            .frame(width: 18, height: 18)
                            .foregroundColor(.white)
                    }
                }
                .disabled(!canSend)
                .animation(.easeInOut(duration: 0.2), value: canSend)
            }
            .padding(.horizontal, MomentumSpacing.standard)
            .padding(.vertical, MomentumSpacing.compact)
            .background(Color.momentumBackground)
        }
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
}

// MARK: - Saved Chats List

struct SavedChatsListView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.momentumBackground
                    .ignoresSafeArea()

                if viewModel.savedChats.isEmpty {
                    VStack(spacing: MomentumSpacing.standard) {
                        Ph.chatsCircle.regular
                            .frame(width: 48, height: 48)
                            .foregroundColor(.momentumTextTertiary)

                        Text("No saved chats")
                            .font(MomentumFont.bodyMedium())
                            .foregroundColor(.momentumTextSecondary)
                    }
                } else {
                    List {
                        ForEach(viewModel.savedChats) { chat in
                            Button {
                                viewModel.loadChat(chat)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: MomentumSpacing.micro) {
                                    Text(chat.title)
                                        .font(MomentumFont.bodyMedium())
                                        .foregroundColor(.momentumTextPrimary)
                                        .lineLimit(1)

                                    HStack {
                                        Text("\(chat.messages.count) messages")
                                        Text("•")
                                        Text(chat.updatedAt.formatted(.relative(presentation: .named)))
                                    }
                                    .font(MomentumFont.caption())
                                    .foregroundColor(.momentumTextSecondary)
                                }
                                .padding(.vertical, MomentumSpacing.micro)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteChat(chat)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Saved Chats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.momentumBlue)
                }
            }
        }
    }
}

#Preview {
    GlobalAIChatView()
        .environmentObject(AppState())
}
