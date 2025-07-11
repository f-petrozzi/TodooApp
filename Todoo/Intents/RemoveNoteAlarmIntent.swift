//
//  RemoveNoteAlarm.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/22/25.
//
// RemoveNoteAlarmIntent.swift
import AppIntents
import Foundation

struct RemoveNoteAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "Remove Note Alarm"
    static var description: IntentDescription? = IntentDescription("Cancels the alarm for a specific note")

    @Parameter(title: "Note ID")
    var noteID: Int

    @MainActor
    func perform() async throws -> some IntentResult {
        let id32 = Int32(noteID)
        guard let note = DatabaseManager.shared.getNote(id: id32),
              note.isAlarmScheduled,
              let alarmID = note.alarmID else {
            return .result()
        }
        try await AlarmService.shared.cancelAlarm(alarmID: alarmID)
        var n = note
        n.isAlarmScheduled = false
        n.alarmID = nil
        DatabaseManager.shared.updateNote(n)
        return .result()
    }
}
