//
//  ChatViewModel.swift
//  Momentum
//
//  Created by Henry Bowman on 1/21/26.
//

import SwiftUI
import Combine

// MARK: - Chat Message Model

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: ChatRole
    let content: String
    let timestamp: Date

    init(id: UUID = UUID(), role: ChatRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

enum ChatRole: String, Codable {
    case user
    case assistant
}

// MARK: - Saved Chat Model

struct SavedChat: Identifiable, Codable {
    let id: UUID
    let title: String
    let messages: [ChatMessage]
    let taskId: UUID?
    let taskTitle: String?
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        messages: [ChatMessage],
        taskId: UUID? = nil,
        taskTitle: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.taskId = taskId
        self.taskTitle = taskTitle
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Chat View Model

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var savedChats: [SavedChat] = []
    @Published var showSavedChats: Bool = false
    @Published var currentChatId: UUID?

    private let groqService = GroqService.shared
    var taskContext: MomentumTask?

    private let savedChatsKey = "momentum_saved_chats"

    init() {
        loadSavedChats()
    }

    // MARK: - Greeting

    func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        switch hour {
        case 0..<12:
            timeGreeting = "Good morning"
        case 12..<17:
            timeGreeting = "Good afternoon"
        default:
            timeGreeting = "Good evening"
        }

        if let task = taskContext {
            return "\(timeGreeting)! I'm here to help you with \"\(task.title)\". What would you like to know?"
        } else {
            return "\(timeGreeting)! I'm your AI assistant. Ask me anything about your goals, tasks, or need help with research."
        }
    }

    // MARK: - Suggested Prompts

    func getSuggestedPrompts() -> [String] {
        if let task = taskContext {
            return [
                "Break this into smaller steps",
                "Help me get started",
                "Research tips for this"
            ]
        } else {
            return [
                "How can I stay motivated?",
                "Help me plan my week",
                "What should I focus on?"
            ]
        }
    }

    // MARK: - Send Message

    func sendMessage() async {
        let userMessage = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }

        // Clear input immediately
        inputText = ""

        // Add user message
        let userChatMessage = ChatMessage(role: .user, content: userMessage)
        messages.append(userChatMessage)

        // Show loading
        isLoading = true

        do {
            let response = try await getAIResponse(for: userMessage)

            // Add AI response
            let aiMessage = ChatMessage(role: .assistant, content: response)
            messages.append(aiMessage)
        } catch {
            // Add error message
            let errorMessage = ChatMessage(
                role: .assistant,
                content: "I'm having trouble connecting right now. Please try again in a moment."
            )
            messages.append(errorMessage)
            print("Chat error: \(error)")
        }

        isLoading = false
    }

    // MARK: - AI Response

    private func getAIResponse(for message: String) async throws -> String {
        if let task = taskContext {
            // Task-specific help
            return try await groqService.getTaskHelp(
                taskTitle: task.title,
                taskDescription: task.taskDescription,
                userQuestion: message
            )
        } else {
            // General assistance - use task help with generic context
            return try await groqService.getTaskHelp(
                taskTitle: "General Goal Achievement",
                taskDescription: "Helping user with their goals and productivity",
                userQuestion: message
            )
        }
    }

    // MARK: - Quick Actions

    func sendSuggestedPrompt(_ prompt: String) async {
        inputText = prompt
        await sendMessage()
    }

    func generateMicrosteps() async {
        guard let task = taskContext else { return }

        isLoading = true

        // Add user message indicating the action
        let userMessage = ChatMessage(role: .user, content: "Break this task into smaller steps")
        messages.append(userMessage)

        do {
            let microsteps = try await groqService.generateMicrosteps(
                taskTitle: task.title,
                taskDescription: task.taskDescription,
                difficulty: task.difficulty
            )

            let formatted = microsteps.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
            let response = "Here's how to break down this task:\n\n\(formatted)\n\nStart with step 1 - you've got this!"

            let aiMessage = ChatMessage(role: .assistant, content: response)
            messages.append(aiMessage)
        } catch {
            let errorMessage = ChatMessage(role: .assistant, content: "I couldn't generate microsteps right now. Try asking me to help break it down!")
            messages.append(errorMessage)
        }

        isLoading = false
    }

    // MARK: - Save/Load Chats

    func saveCurrentChat(title: String? = nil) {
        guard !messages.isEmpty else { return }

        let chatTitle = title ?? generateChatTitle()

        let savedChat = SavedChat(
            id: currentChatId ?? UUID(),
            title: chatTitle,
            messages: messages,
            taskId: taskContext?.id,
            taskTitle: taskContext?.title,
            updatedAt: Date()
        )

        // Update or add
        if let index = savedChats.firstIndex(where: { $0.id == savedChat.id }) {
            savedChats[index] = savedChat
        } else {
            savedChats.insert(savedChat, at: 0)
        }

        currentChatId = savedChat.id
        persistSavedChats()
    }

    func loadChat(_ chat: SavedChat) {
        messages = chat.messages
        currentChatId = chat.id
        showSavedChats = false
    }

    func deleteChat(_ chat: SavedChat) {
        savedChats.removeAll { $0.id == chat.id }
        persistSavedChats()
    }

    func startNewChat() {
        messages = []
        currentChatId = nil
        showSavedChats = false
    }

    private func generateChatTitle() -> String {
        if let task = taskContext {
            return "Help with: \(task.title)"
        } else if let firstUserMessage = messages.first(where: { $0.role == .user }) {
            let preview = String(firstUserMessage.content.prefix(30))
            return preview + (firstUserMessage.content.count > 30 ? "..." : "")
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "Chat - \(formatter.string(from: Date()))"
        }
    }

    private func loadSavedChats() {
        if let data = UserDefaults.standard.data(forKey: savedChatsKey),
           let chats = try? JSONDecoder().decode([SavedChat].self, from: data) {
            savedChats = chats
        }
    }

    private func persistSavedChats() {
        if let data = try? JSONEncoder().encode(savedChats) {
            UserDefaults.standard.set(data, forKey: savedChatsKey)
        }
    }

    // MARK: - Copy Message

    func copyMessage(_ message: ChatMessage) {
        UIPasteboard.general.string = message.content
        SoundManager.shared.selectionHaptic()
    }
}
