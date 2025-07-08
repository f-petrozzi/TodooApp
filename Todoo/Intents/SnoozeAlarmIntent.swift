//
//  SnoozeAlarmIntent.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 7/7/25.
//
import AppIntents
import Foundation
import AlarmKit

struct SnoozeAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "Snooze Alarm"

    @Parameter(title: "Note ID")
    var noteId: Int

    func perform() async throws -> some IntentResult {
        let id32 = Int32(noteId)
        guard var note = DatabaseManager.shared.getNote(id: id32) else { return .result() }
        note.date = Date().addingTimeInterval(5 * 60)
        DatabaseManager.shared.updateNote(note)
        try await AlarmService.shared.cancel(noteId: id32)
        try await AlarmService.shared.schedule(note: note)
        try await NotificationService.shared.schedule(note: note)
        return .result()
    }
}
