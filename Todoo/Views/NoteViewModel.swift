//
//  NoteViewModel.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/15/25.
//
import Foundation

class NoteViewModel: ObservableObject {
    @Published var notes: [Note] = []

    init() {
        fetchNotes()
    }

    func fetchNotes() {
        notes = DatabaseManager.shared.getAllNotes()
    }

    func addNote(title: String, description: String, date: Date, parentId: Int32?) {
        let newNote = Note(
            id: 0,
            parentId: parentId,
            title: title,
            description: description,
            date: date,
            isCompleted: false
        )
        DatabaseManager.shared.insertNote(newNote)
        fetchNotes()
    }

    func deleteNote(id: Int32) {
        DatabaseManager.shared.deleteNote(id: id)
        fetchNotes()
    }

    func toggleComplete(note: Note) {
        var updated = note
        updated.isCompleted.toggle()
        DatabaseManager.shared.updateNote(updated)
        fetchNotes()
    }

    func setAlarm(for note: Note, alarmID: UUID) {
        var updated = note
        updated.alarmID = alarmID
        updated.isAlarmScheduled = true
        DatabaseManager.shared.updateNote(updated)
        fetchNotes()
    }

    func clearAlarm(for note: Note) {
        var updated = note
        updated.alarmID = nil
        updated.isAlarmScheduled = false
        DatabaseManager.shared.updateNote(updated)
        fetchNotes()
    }

    func toggleAlarm(for note: Note) {
        Task { @MainActor in
            var updated = note
            if updated.isAlarmScheduled {
                try? await AlarmService.shared.cancelAlarm(alarmID: updated.alarmID!)
                updated.isAlarmScheduled = false
            } else if updated.date > Date() {
                try? await AlarmService.shared.requestAuthorization()
                let id = UUID()
                try? await AlarmService.shared.scheduleAlarm(
                    noteID: updated.id,
                    alarmID: id,
                    date: updated.date,
                    title: updated.title
                )
                updated.isAlarmScheduled = true
                updated.alarmID = id
            }
            DatabaseManager.shared.updateNote(updated)
            fetchNotes()
        }
    }

    func delete(note: Note) {
        Task { @MainActor in
            if note.isAlarmScheduled {
                try? await AlarmService.shared.cancelAlarm(alarmID: note.alarmID!)
            }
            DatabaseManager.shared.deleteNote(id: note.id)
            fetchNotes()
        }
    }
}
