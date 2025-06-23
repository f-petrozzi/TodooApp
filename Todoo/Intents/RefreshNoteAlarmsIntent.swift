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
        let today = cal.startOfDay(for: Date())

        for note in notes where note.isAlarmScheduled {
            let noteDay = cal.startOfDay(for: note.date)
            if noteDay < today {
                runShortcut("RemoveNoteAlarm", date: note.date, label: note.title)
                var cleared = note
                cleared.isAlarmScheduled = false
                db.updateNote(cleared)
            } else if cal.isDate(note.date, inSameDayAs: today) {
                runShortcut("ScheduleNoteAlarm", date: note.date, label: note.title)
                var marked = note
                marked.isAlarmScheduled = true
                db.updateNote(marked)
            }
        }

        return .result()
    }

    private func runShortcut(_ name: String, date: Date, label: String) {
        let iso = ISO8601DateFormatter().string(from: date)
        let raw = "\(iso)|\(label)"
        guard let input = raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "shortcuts://x-callback-url/run-shortcut?name=\(name)&input=\(input)&x-success=todoo://setupComplete")
        else {
            return
        }
        UIApplication.shared.open(url)
    }
}
