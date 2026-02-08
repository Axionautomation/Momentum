//
//  NotificationService.swift
//  Momentum
//
//  Phase 5: Notification System
//

import Foundation
import UserNotifications
import UIKit
import Combine

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    // MARK: - Notification Category Identifiers

    enum Category {
        static let taskReminder = "TASK_REMINDER"
        static let morningBriefing = "MORNING_BRIEFING"
        static let streakReminder = "STREAK_REMINDER"
        static let milestoneAlert = "MILESTONE_ALERT"
    }

    enum Action {
        static let markComplete = "MARK_COMPLETE"
        static let snooze = "SNOOZE"
        static let openApp = "OPEN_APP"
        static let viewBriefing = "VIEW_BRIEFING"
    }

    // MARK: - Initialization

    init() {
        Task {
            await checkCurrentAuthorization()
        }
    }

    // MARK: - Permission

    /// Request notification permission. Returns true if authorized.
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge, .providesAppNotificationSettings])
            isAuthorized = granted
            if granted {
                registerCategories()
            }
            return granted
        } catch {
            print("Notification permission error: \(error)")
            isAuthorized = false
            return false
        }
    }

    /// Check current authorization without prompting.
    func checkCurrentAuthorization() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Category Registration

    /// Register notification categories with actions for rich notifications.
    func registerCategories() {
        // Task Reminder: "Mark Complete" + "Snooze"
        let markCompleteAction = UNNotificationAction(
            identifier: Action.markComplete,
            title: "Mark Complete",
            options: [.foreground]
        )
        let snoozeAction = UNNotificationAction(
            identifier: Action.snooze,
            title: "Snooze 30min",
            options: []
        )
        let taskCategory = UNNotificationCategory(
            identifier: Category.taskReminder,
            actions: [markCompleteAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Morning Briefing: "View Briefing"
        let viewBriefingAction = UNNotificationAction(
            identifier: Action.viewBriefing,
            title: "View Briefing",
            options: [.foreground]
        )
        let briefingCategory = UNNotificationCategory(
            identifier: Category.morningBriefing,
            actions: [viewBriefingAction],
            intentIdentifiers: [],
            options: []
        )

        // Streak Reminder: "Open App"
        let openAppAction = UNNotificationAction(
            identifier: Action.openApp,
            title: "Open Momentum",
            options: [.foreground]
        )
        let streakCategory = UNNotificationCategory(
            identifier: Category.streakReminder,
            actions: [openAppAction],
            intentIdentifiers: [],
            options: []
        )

        // Milestone Alert: "Open App"
        let milestoneCategory = UNNotificationCategory(
            identifier: Category.milestoneAlert,
            actions: [openAppAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([
            taskCategory,
            briefingCategory,
            streakCategory,
            milestoneCategory
        ])
    }

    // MARK: - Schedule Morning Briefing

    /// Schedule a daily morning briefing notification at the specified time.
    func scheduleMorningBriefing(at hour: Int, minute: Int) {
        // Remove any existing briefing notifications first
        center.removePendingNotificationRequests(withIdentifiers: ["morning-briefing"])

        let content = UNMutableNotificationContent()
        content.title = "Your Morning Briefing is Ready"
        content.body = "See today's tasks, AI insights, and your streak progress."
        content.sound = .default
        content.categoryIdentifier = Category.morningBriefing
        content.threadIdentifier = "briefing"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "morning-briefing",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule morning briefing: \(error)")
            }
        }
    }

    // MARK: - Schedule Task Reminder

    /// Schedule a reminder for a specific task, firing `minutesBefore` minutes before midnight (or at a custom time).
    func scheduleTaskReminder(for task: MomentumTask, minutesBefore: Int = 60) {
        let identifier = "task-reminder-\(task.id.uuidString)"

        // Remove any existing reminder for this task
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title
        if let desc = task.taskDescription, !desc.isEmpty {
            content.subtitle = String(desc.prefix(50))
        }
        content.sound = .default
        content.categoryIdentifier = Category.taskReminder
        content.threadIdentifier = "tasks"
        content.userInfo = [
            "taskId": task.id.uuidString,
            "goalId": task.goalId.uuidString
        ]

        // Schedule for `minutesBefore` minutes before end of day (9 PM default)
        let calendar = Calendar.current
        var fireDate = calendar.startOfDay(for: task.scheduledDate)
        fireDate = calendar.date(byAdding: .hour, value: 21, to: fireDate) ?? fireDate // 9 PM
        fireDate = calendar.date(byAdding: .minute, value: -minutesBefore, to: fireDate) ?? fireDate

        // Only schedule if the fire date is in the future
        guard fireDate > Date() else { return }

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule task reminder: \(error)")
            }
        }
    }

    // MARK: - Schedule Streak Reminder

    /// Schedule an evening reminder if no tasks have been completed today.
    /// Fires daily at 8 PM — the app can cancel it when a task is completed.
    func scheduleStreakReminder() {
        let identifier = "streak-reminder"

        // Remove existing
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Keep Your Streak Alive!"
        content.body = "You haven't completed any tasks today. Open Momentum to stay on track."
        content.sound = .default
        content.categoryIdentifier = Category.streakReminder
        content.threadIdentifier = "streak"

        var dateComponents = DateComponents()
        dateComponents.hour = 20 // 8 PM
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule streak reminder: \(error)")
            }
        }
    }

    // MARK: - Schedule Milestone Alert

    /// Schedule a congratulatory notification when a milestone is completed.
    func scheduleMilestoneAlert(milestone: Milestone) {
        let identifier = "milestone-\(milestone.id.uuidString)"

        let content = UNMutableNotificationContent()
        content.title = "Milestone Complete!"
        content.body = "You've completed \"\(milestone.title)\". Amazing progress!"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = Category.milestoneAlert
        content.threadIdentifier = "milestones"

        // Fire immediately (1 second delay)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule milestone alert: \(error)")
            }
        }
    }

    // MARK: - Cancel

    /// Cancel all pending notifications.
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    /// Cancel a specific notification by identifier.
    func cancelReminder(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Cancel the streak reminder (e.g., when a task is completed today).
    func cancelStreakReminderForToday() {
        // Remove today's streak reminder since the user completed a task
        center.removePendingNotificationRequests(withIdentifiers: ["streak-reminder"])
        // Re-schedule for tomorrow
        scheduleStreakReminder()
    }

    /// Cancel a task reminder by task ID.
    func cancelTaskReminder(taskId: UUID) {
        let identifier = "task-reminder-\(taskId.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Badge Management

    /// Update the app badge count.
    func updateBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count) { error in
            if let error = error {
                print("Failed to set badge count: \(error)")
            }
        }
    }

    /// Clear the app badge.
    func clearBadge() {
        updateBadgeCount(0)
    }
}
