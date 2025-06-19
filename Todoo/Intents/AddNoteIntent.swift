//
//  AddNoteIntent.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/18/25.
//

import AppIntents

struct AddNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Add a Note"
    
    static var description = IntentDescription("Add a new note to Todoo.")
    
    @Parameter(title: "Title")
    var title: String
    
    @Parameter(title: "Description", default: "")
    var description: String
    
    //@Parameter(title: "Date")
    //var date: Date
    
    static var parameterSummary: some ParameterSummary {
        Summary("Add a note with \(\.$title) and \(\.$description)")
    }
    
    func perform() async throws -> some IntentResult {
        let date = Date()
        let note = Note(title: title, description: description, date: date, isCompleted: false)
        DatabaseManager.shared.insertNote(note)
        return .result(value: "Note added to Todoo")
    }
}
