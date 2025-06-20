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

  // drives the sheet for adding a child
  @State private var currentParentId: Int32? = nil

  // which parents are expanded
  @State private var expandedParents = Set<Int32>()

  var body: some View {
    NavigationView {
      List {
        // only top-level notes
        ForEach(viewModel.notes.filter { $0.parentId == nil }) { note in
          let children = viewModel.notes.filter { $0.parentId == note.id }

          // ── Parent row ───────────────────────────────────────────
          HStack {
            // Title + description, plain VStack
            VStack(alignment: .leading, spacing: 4) {
              Text(note.title)
              Text(note.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Fixed 20×20 chevron for expand/collapse
            if !children.isEmpty {
              Button {
                withAnimation {
                  if expandedParents.contains(note.id) {
                    expandedParents.remove(note.id)
                  } else {
                    expandedParents.insert(note.id)
                  }
                }
              } label: {
                Image(systemName:
                      expandedParents.contains(note.id)
                        ? "chevron.down"
                        : "chevron.right"
                )
                .frame(width: 20, height: 20)
              }
              .buttonStyle(.plain)
            } else {
              Spacer().frame(width: 20)
            }

            // Complete toggle
            Button {
              viewModel.toggleComplete(note: note)
            } label: {
              Image(systemName:
                    note.isCompleted
                      ? "checkmark.circle.fill"
                      : "circle"
              )
            }
            .buttonStyle(.plain)
          }
          // swipe to delete parent
          .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
              expandedParents.remove(note.id)
              viewModel.deleteNote(id: note.id)
            } label: {
              Label("Delete", systemImage: "trash")
            }
          }
          // swipe to add first (or more) sub-note
          .swipeActions(edge: .leading) {
            Button {
              currentParentId = note.id
            } label: {
              Label("Add subnote", systemImage: "plus")
            }
            .tint(.blue)
          }

          // ── Inline child rows ────────────────────────────────────
          if expandedParents.contains(note.id) && !children.isEmpty {
            ForEach(children) { child in
              HStack {
                // indent
                Color.clear.frame(width: 20)
                Text(child.title)
                  .foregroundColor(.primary)
                Spacer()
                Button {
                  viewModel.toggleComplete(note: child)
                } label: {
                  Image(systemName:
                        child.isCompleted
                          ? "checkmark.circle.fill"
                          : "circle"
                  )
                }
                .buttonStyle(.plain)
              }
              .transition(.move(edge: .top).combined(with: .opacity))
              // delete child
              .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                  viewModel.deleteNote(id: child.id)
                  // if that was last child, collapse back
                  if viewModel.notes.filter({ $0.parentId == note.id }).isEmpty {
                    expandedParents.remove(note.id)
                  }
                } label: {
                  Label("Delete", systemImage: "trash")
                }
              }
            }

            // “+ Add subnote” under the last child
            HStack {
              Color.clear.frame(width: 20)
              Button {
                currentParentId = note.id
              } label: {
                Label("Add subnote", systemImage: "plus.circle")
              }
              .buttonStyle(.plain)
              Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
          }
        }
      }
      .listStyle(.plain)
      .navigationTitle("Todoo")
      .toolbar {
        HStack {
          Button { showingGenerate = true }
          label: { Image(systemName: "sparkles") }

          Button { showingAddNote = true }
          label: { Image(systemName: "plus") }
        }
      }
      // top-level note sheet
      .sheet(isPresented: $showingAddNote) {
        AddNoteView(viewModel: viewModel, parentId: nil)
      }
      // AI generate sheet
      .sheet(isPresented: $showingGenerate) {
        GenerateNotesView(viewModel: viewModel)
      }
      // sub-note sheet
      .sheet(item: $currentParentId) { parentId in
        AddNoteView(viewModel: viewModel, parentId: parentId)
      }
    }
    .onAppear { viewModel.fetchNotes() }
    .onReceive(
      NotificationCenter.default
        .publisher(for: UIApplication.didBecomeActiveNotification)
    ) { _ in viewModel.fetchNotes() }
  }
}
// Make Int32 identifiable so .sheet(item:) works
extension Int32: @retroactive Identifiable {
  public var id: Int32 { self }
}
