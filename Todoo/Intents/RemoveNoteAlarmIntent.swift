//
//  RemoveNoteAlarm.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/22/25.
//
import AppIntents
import Foundation

@available(iOS 17.0, *)
struct RemoveNoteAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "Remove note alarm"
    static var description: IntentDescription = IntentDescription(
        "Clears the scheduled-alarm flag for a note"
    )
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Note ID")
    var noteId: Int

    @MainActor
    func perform() async throws -> some IntentResult {
        guard var note = DatabaseManager.shared.getNote(id: Int32(noteId)) else {
            return .result()
        }
        note.isAlarmScheduled = false
        DatabaseManager.shared.updateNote(note)
        return .result()
    }
}
