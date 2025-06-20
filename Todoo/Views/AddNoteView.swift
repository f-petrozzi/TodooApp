//
//  AddNoteView.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/15/25.
//
import SwiftUI

struct AddNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: NoteViewModel
    var parentId: Int32?

    @State private var title = ""
    @State private var description = ""
    @State private var date = Date()

    var body: some View {
        NavigationView {
            VStack(spacing: Theme.vPadding) {
                TextField(
                    parentId == nil ? "Note Title" : "Subnote",
                    text: $title
                )
                .textFieldStyle()

                if parentId == nil {
                    TextEditor(text: $description)
                        .textFieldStyle()
                        .frame(height: 100)

                    DatePicker(
                        "",
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .tint(Theme.accent)
                }

                Button("Add") {
                    viewModel.addNote(
                        title: title,
                        description: description,
                        date: date,
                        parentId: parentId
                    )
                    dismiss()
                }
                .primaryButtonStyle()

                Spacer()
            }
            .padding(.horizontal, Theme.hPadding)
            .navigationTitle(parentId == nil ? "Add Note" : "Add Subnote")
            .accentColor(Theme.accent)
        }
    }
}
