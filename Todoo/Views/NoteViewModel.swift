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

  func toggleAlarm(for note: Note) {
    Task { @MainActor in
      var updated = note
      if updated.isAlarmScheduled {
        try? await AlarmService.shared.cancel(noteId: updated.id)
        updated.isAlarmScheduled = false
      } else if updated.date > Date() {
        try? await AlarmService.shared.schedule(note: updated)
        updated.isAlarmScheduled = true
      }
      if updated.isAlarmScheduled {
        try? await NotificationService.shared.schedule(note: updated)
      } else {
        await NotificationService.shared.cancel(noteId: updated.id)
      }
      DatabaseManager.shared.updateNote(updated)
      notes = DatabaseManager.shared.getAllNotes()
    }
  }

  func delete(note: Note) {
    Task { @MainActor in
      if note.isAlarmScheduled {
        await NotificationService.shared.cancel(noteId: note.id)
      }
      DatabaseManager.shared.deleteNote(id: note.id)
      notes = DatabaseManager.shared.getAllNotes()
    }
  }
}
