//
//  DismissAlarmIntent.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 7/7/25.
//
import AppIntents
import Foundation
import ActivityKit

struct DismissAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "Dismiss Alarm"

    @Parameter(title: "Note ID")
    var noteId: Int

    @MainActor
    func perform() async throws -> some IntentResult {
        let id32 = Int32(noteId)
        NotificationService.shared.cancel(noteId: id32)
        try await AlarmService.shared.cancel(noteId: id32)
        if var note = DatabaseManager.shared.getNote(id: id32) {
            note.isAlarmScheduled = false
            DatabaseManager.shared.updateNote(note)
        }
        let activities = Activity<AlarmAttributes>.activities.filter {
            $0.attributes.metadata.noteId == id32
        }
        for activity in activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        return .result()
    }
}
