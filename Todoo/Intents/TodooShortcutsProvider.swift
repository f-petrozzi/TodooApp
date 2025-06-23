//
//  TodooShortcutsProvider.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/19/25.
//
import AppIntents

@available(iOS 17.0, *)
struct TodooShortcutsProvider: AppShortcutsProvider {
    static let appShortcuts: [AppShortcut] = [
        AppShortcut(
            intent: AddNoteIntent(),
            phrases: [
                "Add a note to ${applicationName}",
                "Create a new note in ${applicationName}"
            ],
            shortTitle: "Add note",
            systemImageName: "note.text"
        ),
        AppShortcut(
            intent: ScheduleNoteAlarmIntent(),
            phrases: [
                "Schedule note alarm in ${applicationName}",
                "Set alarm for note in ${applicationName}"
            ],
            shortTitle: "Note alarm",
            systemImageName: "bell"
        ),
        AppShortcut(
            intent: RemoveNoteAlarmIntent(),
            phrases: [
                "Remove note alarm in ${applicationName}",
                "Cancel alarm for note in ${applicationName}"
            ],
            shortTitle: "Remove alarm",
            systemImageName: "bell.slash"
        )
    ]
}
