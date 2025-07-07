//
//  NotificationService.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 7/7/25.
//
import UserNotifications
import Foundation

enum NotificationError: Error {
  case invalidDate
  case noPermission
}

actor NotificationService {
  static let shared = NotificationService()
  private let center = UNUserNotificationCenter.current()

  private let snoozeAction = UNNotificationAction(
    identifier: "SNOOZE_ACTION",
    title: "Snooze",
    options: []
  )
  private let doneAction = UNNotificationAction(
    identifier: "DONE_ACTION",
    title: "Done",
    options: [.authenticationRequired]
  )
  private lazy var category = UNNotificationCategory(
    identifier: "NOTE_ALARM",
    actions: [snoozeAction, doneAction],
    intentIdentifiers: [],
    options: [.customDismissAction]
  )

  func requestAuthorization() async throws {
    let granted = try await center.requestAuthorization(options: [.alert, .sound])
    if !granted { throw NotificationError.noPermission }
    center.setNotificationCategories([category])
  }

  func schedule(note: Note) async throws {
    guard note.date > Date() else { throw NotificationError.invalidDate }

    let content = UNMutableNotificationContent()
    content.title = note.title
    content.body = note.description
    content.sound = .default
    content.categoryIdentifier = "NOTE_ALARM"

    let interval = note.date.timeIntervalSinceNow
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
    let request = UNNotificationRequest(
      identifier: String(note.id),
      content: content,
      trigger: trigger
    )

    try await center.add(request)
  }

  @MainActor
  func cancel(noteId: Int32) {
    center.removePendingNotificationRequests(withIdentifiers: [String(noteId)])
  }
}
