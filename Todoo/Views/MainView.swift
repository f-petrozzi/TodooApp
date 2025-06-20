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
    @State private var showingGenerate = false
    @State private var currentParentId: Int32? = nil
    @State private var expandedParents = Set<Int32>()

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.notes.filter { $0.parentId == nil }) { note in
                    let children = viewModel.notes.filter { $0.parentId == note.id }

                    HStack {
                        if note.description.isEmpty {
                          VStack(alignment: .leading, spacing: Theme.vPadding) {
                            Text(note.title)
                              .font(.title2.weight(.semibold))
                              .foregroundColor(.primary)
                            Text(Self.dateFormatter.string(from: note.date))
                              .font(Theme.subheadlineFont)
                              .foregroundColor(.secondary)
                          }
                          .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
                        } else {
                            VStack(alignment: .leading, spacing: Theme.vPadding) {
                                Text(note.title)
                                    .font(Theme.headlineFont)
                                    .foregroundColor(.primary)
                                Text(note.description)
                                    .font(Theme.subheadlineFont)
                                    .foregroundColor(.secondary)
                                Text(Self.dateFormatter.string(from: note.date))
                                    .font(Theme.subheadlineFont)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

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
                            }
                            .buttonStyle(.plain)
                        } else {
                            Spacer().frame(width: 20)
                        }

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
                    .cardStyle()
                    .swipeActions(edge: .leading) {
                        Button {
                            currentParentId = note.id
                        } label: {
                            Image(systemName: "plus.circle")
                                .iconButtonStyle(size: 24)
                        }
                        .tint(Theme.accent)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            expandedParents.remove(note.id)
                            viewModel.deleteNote(id: note.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }

                    if expandedParents.contains(note.id) && !children.isEmpty {
                        ForEach(children) { child in
                            HStack {
                                Color.clear.frame(width: 0)
                                Text(child.title)
                                    .font(Theme.bodyFont)
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
                            .cardStyle()
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteNote(id: child.id)
                                    if viewModel.notes.filter({ $0.parentId == note.id }).isEmpty {
                                        expandedParents.remove(note.id)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }

                        HStack {
                            Spacer()
                            Button {
                                currentParentId = note.id
                            } label: {
                                Image(systemName: "plus.circle")
                                    .iconButtonStyle(size: 28)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Todoo")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showingGenerate = true
                    } label: {
                        Image(systemName: "sparkles")
                            .iconButtonStyle()
                    }
                    Button {
                        showingAddNote = true
                    } label: {
                        Image(systemName: "plus")
                            .iconButtonStyle()
                    }
                }
            }
            .accentColor(Theme.accent)
            .sheet(isPresented: $showingAddNote) {
                AddNoteView(viewModel: viewModel, parentId: nil)
            }
            .sheet(isPresented: $showingGenerate) {
                GenerateNotesView(viewModel: viewModel)
            }
            .sheet(item: $currentParentId) { parentId in
                AddNoteView(viewModel: viewModel, parentId: parentId)
            }
        }
        .onAppear {
            viewModel.fetchNotes()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
        ) { _ in viewModel.fetchNotes() }
    }
}

extension Int32: @retroactive Identifiable {
    public var id: Int32 { self }
}
