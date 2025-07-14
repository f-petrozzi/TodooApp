//
//  NoteViewModel.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/15/25.
//
import Foundation

class NoteViewModel: ObservableObject {
    @Published var allNotes: [Note] = []
    @Published var sectionedNotes: [FilterCategory: [Note]] = [:]
    @Published var selectedCategories: Set<FilterCategory> = Set(FilterCategory.allCases)
    @Published var currentSort: DatabaseManager.SortOption = .alarm
    @Published var searchText: String = ""

    var searchResults: [Note] {
        guard !searchText.isEmpty else { return [] }
        return allNotes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
            || $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    init() {
        fetchNotes()
    }

    func fetchNotes() {
        allNotes = DatabaseManager.shared.getAllNotes()
        var dict: [FilterCategory: [Note]] = [:]
        for category in selectedCategories {
            let notesForCategory = DatabaseManager.shared.fetchNotes(
                category: category,
                sort: currentSort
            )
            dict[category] = notesForCategory
        }
        sectionedNotes = dict
    }

    func toggleCategory(_ category: FilterCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
        fetchNotes()
    }

    func setSortOption(_ sort: DatabaseManager.SortOption) {
        currentSort = sort
        fetchNotes()
    }

    func addNote(
        title: String,
        description: String,
        date: Date,
        parentId: Int32?
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

    func toggleComplete(note: Note) {
        var updated = note
        updated.isCompleted.toggle()
        if updated.isCompleted {
            updated.completedAt = Date()
        } else {
            updated.completedAt = nil
        }
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
            if updated.isAlarmScheduled, let aid = updated.alarmID {
                try? await AlarmService.shared.cancelAlarm(alarmID: aid)
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

    func archive(note: Note) {
        var updated = note
        updated.isArchived = true
        updated.isMarkedForDeletion = false
        updated.deletionScheduledAt = nil
        DatabaseManager.shared.updateNote(updated)
        fetchNotes()
    }

    func cleanupCompletedNotes() {
        DatabaseManager.shared.cleanupCompletedNotes()
        fetchNotes()
    }

    func delete(note: Note) {
        Task { @MainActor in
            if note.isAlarmScheduled, let aid = note.alarmID {
                try? await AlarmService.shared.cancelAlarm(alarmID: aid)
            }
            DatabaseManager.shared.deleteNote(id: note.id)
            fetchNotes()
        }
    }
}
