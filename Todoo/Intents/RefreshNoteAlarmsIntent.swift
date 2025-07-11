//
//  RefreshNoteAlarms.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/22/25.
//
// RefreshNoteAlarmsIntent.swift
import AppIntents
import Foundation

struct RefreshNoteAlarmsIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Today's Alarms"
    static var description: IntentDescription? = IntentDescription("Clears past alarms and sets up today's alarms")

    @MainActor
    func perform() async throws -> some IntentResult {
        let notes = DatabaseManager.shared.getAllNotes()
        let todayStart = Calendar.current.startOfDay(for: Date())
        for note in notes {
            if note.isAlarmScheduled && note.date < Date(), let alarmID = note.alarmID {
                try? await AlarmService.shared.cancelAlarm(alarmID: alarmID)
                var n = note
                n.isAlarmScheduled = false
                n.alarmID = nil
                DatabaseManager.shared.updateNote(n)
            }
            if note.date >= todayStart && Calendar.current.isDate(note.date, inSameDayAs: todayStart) {
                let id = UUID()
                try? await AlarmService.shared.scheduleAlarm(
                    noteID: note.id,
                    alarmID: id,
                    date: note.date,
                    title: note.title
                )
                var n = note
                n.isAlarmScheduled = true
                n.alarmID = id
                DatabaseManager.shared.updateNote(n)
            }
        }
        return .result()
    }
}
