import SwiftUI

struct SublistView: View {
  @ObservedObject var viewModel: NoteViewModel
  let parent: Note
  @State private var showingAddItem = false

  var body: some View {
    List {
      ForEach(viewModel.notes.filter { $0.parentId == parent.id }) { item in
        HStack {
          Text(item.title)
          Spacer()
          Button {
            viewModel.toggleComplete(note: item)
          } label: {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
          }
          .buttonStyle(PlainButtonStyle())
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
    let children = viewModel.notes.filter { $0.parentId == parent.id }
    for index in offsets {
      let note = children[index]
      viewModel.deleteNote(id: note.id)
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
