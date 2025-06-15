//
//  MainView.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/15/25.
//

import SwiftUI

struct MainView: View {
    @StateObject var viewModel = NoteViewModel()
    @State private var showingAddNote = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.notes) { note in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(note.title)
                                .font(.headline)
                            Text(note.description)
                                .font(.subheadline)
                            Text(note.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                        }
                        Spacer()
                        Button(action: {
                            viewModel.toggleComplete(note: note)
                        }) {
                            Image(systemName: note.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(note.isCompleted ? .green : .gray)
                        }
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { i in
                        let note = viewModel.notes[i]
                        viewModel.deleteNote(id: note.id)
                    }
                }
            }
            .navigationTitle("Todoo")
            .toolbar {
                Button(action: {
                    showingAddNote = true
                }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddNote) {
                AddNoteView(viewModel: viewModel)
            }
        }
    }
}
