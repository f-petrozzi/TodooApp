//
//  RefreshNoteAlarms.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/22/25.
//
import AppIntents
import Foundation
import UIKit

@available(iOS 17.0, *)
struct RefreshNoteAlarmsIntent: AppIntent {
    static var title = LocalizedStringResource("Refresh Today’s Alarms")
    static var description = IntentDescription("Clears past alarms and sets up today’s alarms")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let db = DatabaseManager.shared
        let notes = db.getAllNotes()
        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: now)

        for note in notes where note.isAlarmScheduled {
            if note.date < now {
                runShortcut("RemoveNoteAlarm", date: note.date, title: note.title, noteId: note.id)
                var cleared = note
                cleared.isAlarmScheduled = false
                db.updateNote(cleared)
            } else if cal.isDate(note.date, inSameDayAs: today) && note.date >= now {
                runShortcut("ScheduleNoteAlarm", date: note.date, title: note.title, noteId: note.id)
                var marked = note
                marked.isAlarmScheduled = true
                db.updateNote(marked)
            }
        }

        return .result()
    }

    private func runShortcut(_ name: String, date: Date, title: String, noteId: Int32) {
        let iso = ISO8601DateFormatter().string(from: date)
        let raw = "\(iso)|\(title)|\(noteId)"
        guard let input = raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string:
                    "shortcuts://x-callback-url/run-shortcut?name=\(name)&input=\(input)&x-success=todoo://setupComplete")
        else {
            return
        }
        UIApplication.shared.open(url)
    }
}
