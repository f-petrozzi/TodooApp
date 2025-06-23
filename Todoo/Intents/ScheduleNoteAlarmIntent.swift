//
//  ScheduleNoteAlarm.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/21/25.
//
import AppIntents
import Foundation

@available(iOS 17.0, *)
struct ScheduleNoteAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "Schedule note alarm"
    static var description: IntentDescription = IntentDescription(
        "Marks a note as having an alarm scheduled"
    )
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Note ID")
    var noteId: Int

    @MainActor
    func perform() async throws -> some IntentResult {
        guard var note = DatabaseManager.shared.getNote(id: Int32(noteId)) else {
            return .result()
        }
        note.isAlarmScheduled = true
        DatabaseManager.shared.updateNote(note)
        return .result()
    }
}
