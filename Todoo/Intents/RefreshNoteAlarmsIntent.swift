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
  static var title: LocalizedStringResource { "Refresh Today’s Alarms" }
  static var description = IntentDescription("Clears past alarms and sets up today’s alarms")

  @MainActor
  func perform() async throws -> some IntentResult {
    let notes = DatabaseManager.shared.getAllNotes()
    let today = Calendar.current.startOfDay(for: Date())
    for note in notes {
      if note.isAlarmScheduled, note.date < Date() {
        try? await AlarmService.shared.cancel(noteId: note.id)
        var n = note; n.isAlarmScheduled = false
        DatabaseManager.shared.updateNote(n)
      }
      if note.date >= Date(), Calendar.current.isDate(note.date, inSameDayAs: today) {
        try await AlarmService.shared.schedule(note: note)
        var n = note; n.isAlarmScheduled = true
        DatabaseManager.shared.updateNote(n)
      }
    }
    return .result()
  }
}
