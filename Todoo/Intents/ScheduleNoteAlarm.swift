//
//  ScheduleNoteAlarm.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/21/25.
//

import AppIntents
import UserNotifications
import Foundation

struct ScheduleNoteAlarmIntent: AppIntent {
    static let title = LocalizedStringResource("Schedule note alarm")
    static let description = IntentDescription("Schedule a notification alarm at a note’s due date")
    static let openAppWhenRun = false

    @Parameter(title: "Note ID")
    var noteId: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Set alarm for note ID \(\.$noteId)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let note = DatabaseManager.shared.getNote(id: Int32(noteId)) else {
            return .result(dialog: IntentDialog(stringLiteral: "Note not found"))
        }

        let content = UNMutableNotificationContent()
        content.title = note.title
        content.body = note.description
        content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm.caf"))

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: note.date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: "noteAlarm_\(note.id)",
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let when = dateFormatter.string(from: note.date)

        return .result(dialog: IntentDialog(stringLiteral: "Alarm scheduled for \(when)"))
    }
}
