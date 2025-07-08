//
//  NotificationDelegate.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 7/7/25.
//
import UserNotifications
import Foundation
import ActivityKit

@MainActor
class NotificationDelegate: NSObject, @preconcurrency UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completion: @escaping (UNNotificationPresentationOptions) -> Void) {
        completion([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let noteId = Int32(response.notification.request.identifier) else { return }
        switch response.actionIdentifier {
        case "SNOOZE_ACTION":
            guard var note = DatabaseManager.shared.getNote(id: noteId) else { return }
            note.date = Date().addingTimeInterval(5 * 60)
            DatabaseManager.shared.updateNote(note)
            Task {
                try? await AlarmService.shared.cancel(noteId: noteId)
                try? await AlarmService.shared.schedule(note: note)
                try? await NotificationService.shared.schedule(note: note)
            }
        case "DONE_ACTION":
            NotificationService.shared.cancel(noteId: noteId)
            Task {
                try? await AlarmService.shared.cancel(noteId: noteId)
            }
            if var note = DatabaseManager.shared.getNote(id: noteId) {
                note.isAlarmScheduled = false
                DatabaseManager.shared.updateNote(note)
            }
            let activities = Activity<AlarmAttributes>.activities.filter { $0.attributes.metadata.noteId == noteId }
            for activity in activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        default:
            break
        }
    }
}
