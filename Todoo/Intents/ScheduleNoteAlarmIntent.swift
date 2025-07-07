//
//  ScheduleNoteAlarm.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/21/25.
//
import AppIntents
import Foundation

struct ScheduleNoteAlarmIntent: AppIntent {
  static var title: LocalizedStringResource { "Schedule Note Alarm" }
  static var description = IntentDescription("Schedules an alarm for a note")

  @Parameter(title: "Note ID") var noteId: Int

  @MainActor
  func perform() async throws -> some IntentResult {
    guard let note = DatabaseManager.shared.getNote(id: Int32(noteId)) else {
      return .result()
    }
    try await AlarmService.shared.schedule(note: note)
    var updated = note; updated.isAlarmScheduled = true
    DatabaseManager.shared.updateNote(updated)
    return .result()
  }
}
