//
//  AddNoteIntent.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/18/25.
//

import AppIntents
import Foundation

struct AddNoteIntent: AppIntent {
    static let title = LocalizedStringResource("Add a Note")
    static let description = IntentDescription("Add a new note to Todoo")
    static let openAppWhenRun: Bool = true

    @Parameter(title: "Title")
    var title: String

    @Parameter(title: "Description")
    var noteDescription: String

    static var parameterSummary: some ParameterSummary {
        Summary("Add a note titled \(\.$title) with \(\.$noteDescription)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let note = Note(
            title: title,
            description: noteDescription,
            date: Date(),
            isCompleted: false
        )
        DatabaseManager.shared.insertNote(note)
        return .result(
            dialog: IntentDialog(stringLiteral: "Added a note titled \(title)")
        )
    }
}
