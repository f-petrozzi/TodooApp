//
//  ScheduleNoteAlarm.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/21/25.
//
import AppIntents
import Foundation

struct ScheduleNoteAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "Schedule Note Alarm"
    static var description: IntentDescription? = IntentDescription("Schedules an alarm for a specific note")

    @Parameter(title: "Note ID")
    var noteID: Int

    @MainActor
    func perform() async throws -> some IntentResult {
        let id32 = Int32(noteID)
        guard let note = DatabaseManager.shared.getNote(id: id32),
              note.date > Date() else {
            return .result()
        }
        let id = UUID()
        try await AlarmService.shared.scheduleAlarm(
            noteID: id32,
            alarmID: id,
            date: note.date,
            title: note.title
        )
        var n = note
        n.isAlarmScheduled = true
        n.alarmID = id
        DatabaseManager.shared.updateNote(n)
        return .result()
    }
}
