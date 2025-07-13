//
//  SublistView.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 7/01/25.
//
import SwiftUI

struct SublistView: View {
    @ObservedObject var viewModel: NoteViewModel
    let parent: Note
    @State private var showingAddItem = false

    private var children: [Note] {
        viewModel.sectionedNotes.values
            .flatMap { $0 }
            .filter { $0.parentId == parent.id }
    }

    var body: some View {
        List {
            ForEach(children) { item in
                HStack {
                    Text(item.title)
                    Spacer()
                    Button {
                        viewModel.toggleComplete(note: item)
                    } label: {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    }
                    .buttonStyle(.plain)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .navigationTitle(parent.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddItem = true
                } label: {
                    Image(systemName: "plus.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddNoteView(viewModel: viewModel, parentId: parent.id)
        }
        .onAppear {
            viewModel.fetchNotes()
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let note = children[index]
            viewModel.delete(note: note)
        }
    }
}

struct SublistView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = NoteViewModel()
        let sample = Note(
            id: 1,
            parentId: nil,
            title: "Groceries",
            description: "",
            date: Date(),
            isCompleted: false
        )
        NavigationView {
            SublistView(viewModel: vm, parent: sample)
        }
    }
}
