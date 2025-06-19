//
//  MainView.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/15/25.
//
import SwiftUI
import UIKit

struct MainView: View {
    @StateObject var viewModel = NoteViewModel()
    @State private var showingAddNote = false
    @State private var showingGenerate = false

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
                            Text(
                                note.date
                                    .formatted(
                                        date: .abbreviated,
                                        time: .shortened
                                    )
                            )
                            .font(.caption)
                        }
                        Spacer()
                        Button {
                            viewModel.toggleComplete(note: note)
                        } label: {
                            Image(
                                systemName: note.isCompleted
                                    ? "checkmark.circle.fill"
                                    : "circle"
                            )
                            .foregroundColor(
                                note.isCompleted ? .green : .gray
                            )
                        }
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet {
                        let note = viewModel.notes[i]
                        viewModel.deleteNote(id: note.id)
                    }
                }
            }
            .navigationTitle("Todoo")
            .toolbar {
                HStack {
                    Button {
                        showingGenerate = true
                    } label: {
                        Image(systemName: "sparkles")
                    }
                    Button {
                        showingAddNote = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddNote) {
                AddNoteView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingGenerate) {
                GenerateNotesView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.fetchNotes()
        }
        .onReceive(
            NotificationCenter
                .default
                .publisher(
                    for: UIApplication.didBecomeActiveNotification
                )
        ) { _ in
            viewModel.fetchNotes()
        }
    }
}
