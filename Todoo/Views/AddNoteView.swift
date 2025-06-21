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
            VStack(spacing: 12) {
                TextField(
                    parentId == nil ? "Title" : "Subnote",
                    text: $title
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .cornerRadius(8)

                if parentId == nil {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $description)
                            .padding(12)

                        if description.isEmpty {
                            Text("Description")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                        }
                    }
                    .frame(height: 100)
                    .cornerRadius(8)
                }

                if parentId == nil {
                    DatePicker(
                        "",
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .padding(.horizontal, 16)
                }

                Button(action: {
                    viewModel.addNote(
                        title: title,
                        description: description,
                        date: date,
                        parentId: parentId
                    )
                    dismiss()
                }) {
                    Text("Add")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 16)
            .navigationTitle(parentId == nil ? "Add Note" : "Add Subnote")
            .accentColor(Theme.accent)
        }
    }
}
