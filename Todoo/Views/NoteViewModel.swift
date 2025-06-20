//
//  NoteViewModel.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/15/25.
//
import Foundation

class NoteViewModel: ObservableObject {
  @Published var notes: [Note] = []

  private let dbQueue = DispatchQueue(label: "com.yourapp.sqliteQueue",
                                      qos: .userInitiated)

  init() {
    fetchNotes()
  }

  func fetchNotes() {
    dbQueue.async {
      let all = DatabaseManager.shared.getAllNotes()
      DispatchQueue.main.async {
        self.notes = all
      }
    }
  }

  func addNote(title: String, description: String, date: Date, parentId: Int32?) {
    let newNote = Note(id: 0,
                       parentId: parentId,
                       title: title,
                       description: description,
                       date: date,
                       isCompleted: false)
                       
    dbQueue.async {
      DatabaseManager.shared.insertNote(newNote)
      let all = DatabaseManager.shared.getAllNotes()
      DispatchQueue.main.async {
        self.notes = all
      }
    }
  }

  func deleteNote(id: Int32) {
    dbQueue.async {
      DatabaseManager.shared.deleteNote(id: id)
      let all = DatabaseManager.shared.getAllNotes()
      DispatchQueue.main.async {
        self.notes = all
      }
    }
  }

  func toggleComplete(note: Note) {
    var updated = note
    updated.isCompleted.toggle()
    dbQueue.async {
      DatabaseManager.shared.updateNote(updated)
      let all = DatabaseManager.shared.getAllNotes()
      DispatchQueue.main.async {
        self.notes = all
      }
    }
  }
}
