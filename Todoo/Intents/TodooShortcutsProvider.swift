//
//  TodooShortcutsProvider.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/19/25.
//

import AppIntents

struct TodooShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddNoteIntent(),
            phrases: [
                "Add a note to \(.applicationName)",
                "Create a new note in \(.applicationName)"
            ],
            shortTitle: "Add note",
            systemImageName: "note.text"
        )
    }
}

