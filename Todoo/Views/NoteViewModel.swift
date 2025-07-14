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
    
    @Published var selectedCategories: Set<FilterCategory>
    @Published var categoryOrder: [FilterCategory]
    
    @Published var currentSort: DatabaseManager.SortOption = .alarm
    @Published var searchText: String = ""
    
    private let categoryOrderKey = "categoryOrder"

    var searchResults: [Note] {
        guard !searchText.isEmpty else { return [] }
        return allNotes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
            || $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    init() {
        let stored = UserDefaults.standard.stringArray(forKey: categoryOrderKey) ?? []
        let saved  = stored.compactMap { FilterCategory(rawValue: $0) }
        let initialOrder    = saved.isEmpty ? FilterCategory.allCases : saved
        let initialSelected = Set(initialOrder)

        categoryOrder      = initialOrder
        selectedCategories = initialSelected

        fetchNotes()
    }

    private func saveCategoryOrder() {
        let raw = categoryOrder.map(\.rawValue)
        UserDefaults.standard.set(raw, forKey: categoryOrderKey)
    }

    func fetchNotes() {
        allNotes = DatabaseManager.shared.getAllNotes()
        var dict: [FilterCategory: [Note]] = [:]
        for category in selectedCategories {
            dict[category] = DatabaseManager.shared.fetchNotes(
                category: category,
                sort: currentSort
            )
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
    
    // Called by CategoryPickerView’s onMove
    func moveCategory(from source: IndexSet, to destination: Int) {
        categoryOrder.move(fromOffsets: source, toOffset: destination)
        saveCategoryOrder()
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
        var newNote = Note(
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
        updated.completedAt = updated.isCompleted ? Date() : nil
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

    func archive(note: Note) {
        var updated = note
        updated.isArchived = true
        updated.isMarkedForDeletion = false
        updated.deletionScheduledAt = nil
        DatabaseManager.shared.updateNote(updated)
        fetchNotes()
    }

    func delete(note: Note) {
        var toDelete = note
        if toDelete.isAlarmScheduled, let aid = toDelete.alarmID {
            Task { @MainActor in
                try? await AlarmService.shared.cancelAlarm(alarmID: aid)
            }
        }
        DatabaseManager.shared.deleteNote(id: toDelete.id)
        fetchNotes()
    }

    func cleanupCompletedNotes() {
        DatabaseManager.shared.cleanupCompletedNotes()
        fetchNotes()
    }
}
