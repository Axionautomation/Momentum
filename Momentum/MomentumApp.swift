//
//  MomentumApp.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI
import BackgroundTasks
import UserNotifications
import Combine

@main
struct MomentumApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.momentum.briefing",
            using: nil
        ) { task in
            // Background briefing generation — scheduling logic in a future phase
            task.setTaskCompleted(success: true)
        }

        // Register notification categories at launch
        NotificationService.shared.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - App Delegate for Notification Handling

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner + sound even when app is in foreground
        completionHandler([.banner, .sound])
    }

    // Handle notification action (Mark Complete, Snooze, etc.)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo

        switch actionIdentifier {
        case NotificationService.Action.markComplete:
            // Post notification for AppState to handle task completion
            if let taskIdString = userInfo["taskId"] as? String {
                NotificationCenter.default.post(
                    name: .completeTaskFromNotification,
                    object: nil,
                    userInfo: ["taskId": taskIdString]
                )
            }

        case NotificationService.Action.snooze:
            // Reschedule the notification for 30 minutes from now
            if let taskIdString = userInfo["taskId"] as? String,
               let taskId = UUID(uuidString: taskIdString) {
                let content = response.notification.request.content.mutableCopy() as! UNMutableNotificationContent
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30 * 60, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "task-reminder-\(taskId.uuidString)-snoozed",
                    content: content,
                    trigger: trigger
                )
                center.add(request)
            }

        case NotificationService.Action.viewBriefing:
            // Post notification to navigate to dashboard
            NotificationCenter.default.post(
                name: .navigateToDashboard,
                object: nil
            )

        default:
            break
        }

        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let completeTaskFromNotification = Notification.Name("completeTaskFromNotification")
    static let navigateToDashboard = Notification.Name("navigateToDashboard")
}
