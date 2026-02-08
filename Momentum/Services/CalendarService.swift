//
//  CalendarService.swift
//  Momentum
//
//  Created by Claude on 2/8/26.
//

import Foundation
import EventKit
import Combine

/// Manages calendar integration via EventKit for scheduling focus sessions, deadlines, and syncing tasks
@MainActor
class CalendarService: ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined

    private let eventStore = EKEventStore()
    private let calendarTitle = "Momentum"

    init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Request calendar access from the user
    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            isAuthorized = granted
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            return granted
        } catch {
            print("[CalendarService] Access request failed: \(error.localizedDescription)")
            isAuthorized = false
            return false
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        authorizationStatus = status
        isAuthorized = (status == .fullAccess)
    }

    // MARK: - Focus Sessions

    /// Schedule a focus session for a task
    func scheduleFocusSession(for task: MomentumTask, duration: Int, startDate: Date? = nil) async throws {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }

        let calendar = getOrCreateMomentumCalendar()
        let event = EKEvent(eventStore: eventStore)
        event.title = "Focus: \(task.title)"
        event.notes = task.taskDescription ?? "Focus session for Momentum task"

        let start = startDate ?? nextAvailableSlot(duration: duration)
        event.startDate = start
        event.endDate = Calendar.current.date(byAdding: .minute, value: duration, to: start)
        event.calendar = calendar

        // Add an alert 5 minutes before
        event.addAlarm(EKAlarm(relativeOffset: -300))

        try eventStore.save(event, span: .thisEvent)
        print("[CalendarService] Scheduled focus session: \(task.title) at \(start)")
    }

    // MARK: - Deadlines

    /// Add a deadline event for a milestone
    func addDeadline(for milestone: Milestone, goalName: String, deadlineDate: Date) async throws {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }

        let calendar = getOrCreateMomentumCalendar()
        let event = EKEvent(eventStore: eventStore)
        event.title = "Deadline: \(milestone.title)"
        event.notes = "Milestone \(milestone.sequenceNumber) for \(goalName)"
        event.startDate = deadlineDate
        event.endDate = deadlineDate
        event.isAllDay = true
        event.calendar = calendar

        // Add alerts at 1 day and 3 days before
        event.addAlarm(EKAlarm(relativeOffset: -86400))   // 1 day
        event.addAlarm(EKAlarm(relativeOffset: -259200))  // 3 days

        try eventStore.save(event, span: .thisEvent)
        print("[CalendarService] Added deadline: \(milestone.title) on \(deadlineDate)")
    }

    // MARK: - Conflicts

    /// Get calendar events that conflict with a given date/time range
    func getConflicts(for date: Date, duration: Int = 60) -> [EKEvent] {
        guard isAuthorized else { return [] }

        let endDate = Calendar.current.date(byAdding: .minute, value: duration, to: date) ?? date
        let predicate = eventStore.predicateForEvents(
            withStart: date,
            end: endDate,
            calendars: nil
        )

        return eventStore.events(matching: predicate)
    }

    /// Get all events for today
    func getTodaysEvents() -> [EKEvent] {
        guard isAuthorized else { return [] }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )

        return eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }

    // MARK: - Task Sync

    /// Sync task due dates with calendar events
    func syncTaskDueDates(tasks: [MomentumTask], goalName: String) async throws {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }

        let calendar = getOrCreateMomentumCalendar()

        for task in tasks where task.status == .pending {
            // Check if event already exists
            let existingEvents = findExistingEvents(for: task)
            if !existingEvents.isEmpty { continue }

            let event = EKEvent(eventStore: eventStore)
            event.title = task.title
            event.notes = "Momentum task for \(goalName)\n\(task.taskDescription ?? "")"
            event.startDate = task.scheduledDate
            event.endDate = Calendar.current.date(
                byAdding: .minute,
                value: task.totalEstimatedMinutes,
                to: task.scheduledDate
            )
            event.calendar = calendar

            try eventStore.save(event, span: .thisEvent)
        }

        print("[CalendarService] Synced \(tasks.count) tasks to calendar")
    }

    // MARK: - Private Helpers

    private func getOrCreateMomentumCalendar() -> EKCalendar {
        // Look for existing Momentum calendar
        let calendars = eventStore.calendars(for: .event)
        if let existing = calendars.first(where: { $0.title == calendarTitle }) {
            return existing
        }

        // Create new calendar
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = calendarTitle

        // Use the default calendar source
        if let source = eventStore.defaultCalendarForNewEvents?.source {
            newCalendar.source = source
        } else if let source = eventStore.sources.first(where: { $0.sourceType == .local }) {
            newCalendar.source = source
        }

        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
        } catch {
            print("[CalendarService] Failed to create calendar: \(error)")
            return eventStore.defaultCalendarForNewEvents ?? newCalendar
        }

        return newCalendar
    }

    private func nextAvailableSlot(duration: Int) -> Date {
        let calendar = Calendar.current
        var candidate = Date()

        // Round up to next 30-minute mark
        let minute = calendar.component(.minute, from: candidate)
        let roundedMinute = minute < 30 ? 30 : 60
        candidate = calendar.date(
            byAdding: .minute,
            value: roundedMinute - minute,
            to: candidate
        ) ?? candidate

        // Check for conflicts and advance if needed
        let conflicts = getConflicts(for: candidate, duration: duration)
        if !conflicts.isEmpty, let lastConflict = conflicts.last {
            candidate = lastConflict.endDate
        }

        return candidate
    }

    private func findExistingEvents(for task: MomentumTask) -> [EKEvent] {
        guard isAuthorized else { return [] }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: task.scheduledDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? task.scheduledDate

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )

        return eventStore.events(matching: predicate).filter { $0.title == task.title }
    }
}

// MARK: - Calendar Errors

enum CalendarError: LocalizedError {
    case notAuthorized
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Calendar access not authorized. Please enable in Settings."
        case .saveFailed(let reason):
            return "Failed to save calendar event: \(reason)"
        }
    }
}
