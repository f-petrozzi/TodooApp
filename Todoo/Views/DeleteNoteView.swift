//
//  DeleteNoteView.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 7/14/25.
//
import SwiftUI

struct DeleteNoteView: View {
    @State private var localNotes: [Note]
    @State private var selected: Set<Int32> = []
    @ObservedObject var viewModel: NoteViewModel
    let onClose: () -> Void

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    init(notes: [Note], viewModel: NoteViewModel, onClose: @escaping () -> Void) {
        _localNotes = State(initialValue: notes)
        self.viewModel = viewModel
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Expired Notes")
                .font(.headline)
                .padding()
            Divider()
            List(selection: $selected) {
                ForEach(localNotes) { note in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.title)
                                .font(.body)
                            if let scheduled = note.deletionScheduledAt {
                                Text("Expires: \(dateFormatter.string(from: scheduled))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .environment(\.editMode, .constant(.active))
            Divider()
            HStack {
                Button(archiveButtonTitle) {
                    archiveAction()
                }
                .buttonStyle(.plain)

                Spacer()

                Button(deleteButtonTitle, role: .destructive) {
                    deleteAction()
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 20)
        .padding()
    }

    private var archiveButtonTitle: String {
        selected.isEmpty ? "Archive All" : "Archive Selected"
    }

    private var deleteButtonTitle: String {
        selected.isEmpty ? "Delete All" : "Delete Selected"
    }

    private func archiveAction() {
        if selected.isEmpty {
            localNotes.forEach { viewModel.archive(note: $0) }
            localNotes.removeAll()
        } else {
            selected.forEach { id in
                if let note = localNotes.first(where: { $0.id == id }) {
                    viewModel.archive(note: note)
                }
            }
            localNotes.removeAll { selected.contains($0.id) }
        }
        selected.removeAll()
        if localNotes.isEmpty {
            onClose()
        }
    }

    private func deleteAction() {
        if selected.isEmpty {
            localNotes.forEach { viewModel.delete(note: $0) }
            localNotes.removeAll()
        } else {
            selected.forEach { id in
                if let note = localNotes.first(where: { $0.id == id }) {
                    viewModel.delete(note: note)
                }
            }
            localNotes.removeAll { selected.contains($0.id) }
        }
        selected.removeAll()
        if localNotes.isEmpty {
            onClose()
        }
    }
}
