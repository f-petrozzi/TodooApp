//
//  AddNoteView.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/15/25.
//

import SwiftUI

struct AddNoteView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: NoteViewModel
    
    var parentId: Int32?

    @State private var title = ""
    @State private var description = ""
    @State private var date = Date()

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                TextField("Description", text: $description)
                DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
            }
            .navigationTitle("New Note")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addNote(
                            title: title,
                            description: description,
                            date: date,
                            parentId: parentId 
                        )
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
