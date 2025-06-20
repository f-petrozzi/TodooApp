//
//  NoteViewModel.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/15/25.
//
import Foundation

class NoteViewModel: ObservableObject {
    @Published var notes = [Note]()

    init() {
        fetchNotes()
    }

    func fetchNotes() {
        notes = DatabaseManager.shared.getAllNotes()
    }

    func addNote(
        title: String,
        description: String,
        date: Date,
        parentId: Int32? = nil
    ) {
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
}
