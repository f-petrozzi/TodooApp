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
  static var title: LocalizedStringResource { "Remove Note Alarm" }
  static var description = IntentDescription("Cancels the alarm for a note")

  @Parameter(title: "Note ID") var noteId: Int

  @MainActor
  func perform() async throws -> some IntentResult {
    try await AlarmService.shared.cancel(noteId: Int32(noteId))
    if var note = DatabaseManager.shared.getNote(id: Int32(noteId)) {
      note.isAlarmScheduled = false
      DatabaseManager.shared.updateNote(note)
    }
    return .result()
  }
}
