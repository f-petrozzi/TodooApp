//
//  NotificationService.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 7/7/25.
//
// Services/NotificationService.swift
import UserNotifications
import Foundation

enum NotificationError: Error {
  case invalidDate
  case noPermission
}

actor NotificationService {
  static let shared = NotificationService()
  private let center = UNUserNotificationCenter.current()

  func requestAuthorization() async throws {
    let granted = try await center.requestAuthorization(options: [.alert, .sound])
    print("🔔 requestAuthorization granted? \(granted)")
    if !granted { throw NotificationError.noPermission }
  }

  func schedule(note: Note) async throws {
    guard note.date > Date() else {
      print("⚠️ schedule: date in past:", note.date)
      throw NotificationError.invalidDate
    }

    let content = UNMutableNotificationContent()
    content.title = note.title
    content.body = note.description
    content.sound = .default
    content.categoryIdentifier = "NOTE_ALARM"

    let interval = note.date.timeIntervalSinceNow
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
    let id = String(note.id)
    let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

    do {
      try await center.add(req)
      print("✅ Fallback notification scheduled id=\(id) in \(interval)s")
    } catch {
      print("❌ Fallback schedule failed:", error)
    }

    center.getPendingNotificationRequests { requests in
      print("📋 Pending notifications:", requests.map(\.identifier))
    }
  }

  @MainActor
  func cancel(noteId: Int32) {
    let id = String(noteId)
    center.removePendingNotificationRequests(withIdentifiers: [id])
    print("🗑 Removed fallback notification id=\(id)")
  }
}
