//
//  RefreshNoteAlarms.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/22/25.
//
import AppIntents
import Foundation

@available(iOS 17.0, *)
struct RefreshNoteAlarmsIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Today's Alarms"
    static var description: IntentDescription = IntentDescription(
        "Schedules any note alarms that fall on today’s date and clears out past ones."
    )
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        let allNotes = DatabaseManager.shared.getAllNotes()
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())

        for note in allNotes where note.isAlarmScheduled &&
            calendar.startOfDay(for: note.date) < todayStart
        {
            var cleared = note
            cleared.isAlarmScheduled = false
            DatabaseManager.shared.updateNote(cleared)
        }

        for note in allNotes where !note.isAlarmScheduled &&
            calendar.isDate(note.date, inSameDayAs: todayStart)
        {
            let intent = ScheduleNoteAlarmIntent()
            intent.noteId = Int(note.id)
            _ = try await intent.perform()

            var updated = note
            updated.isAlarmScheduled = true
            DatabaseManager.shared.updateNote(updated)
        }

        return .result()
    }
}
