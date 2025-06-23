//
//  MainView.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/15/25
//
import SwiftUI
import AppIntents

struct MainView: View {
    @StateObject private var viewModel = NoteViewModel()
    @State private var showingAddNote = false
    @State private var showingGenerate = false
    @State private var currentParentId: Int32? = nil
    @State private var expandedParents = Set<Int32>()
    @State private var showHelpOverlay = false

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.notes.filter { $0.parentId == nil }) { note in
                    NoteRow(
                        note: note,
                        children: viewModel.notes.filter { $0.parentId == note.id },
                        expandedParents: $expandedParents,
                        viewModel: viewModel,
                        showHelp: { showHelpOverlay = true },
                        isParent: true,
                        onAddChild: { currentParentId = note.id }
                    )

                    if expandedParents.contains(note.id) {
                        let children = viewModel.notes.filter { $0.parentId == note.id }

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
                                    if child.isAlarmScheduled {
                                        Task {
                                            let intent = RemoveNoteAlarmIntent()
                                            intent.noteId = Int(child.id)
                                            _ = try? await intent.perform()
                                        }
                                    }
                                    viewModel.deleteNote(id: child.id)
                                    if viewModel.notes.filter({ $0.parentId == note.id }).isEmpty {
                                        expandedParents.remove(note.id)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }

                        if !children.isEmpty {
                            HStack {
                                Spacer()
                                Button {
                                    currentParentId = note.id
                                } label: {
                                    Image(systemName: "plus.circle")
                                        .iconButtonStyle(size: 22)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Todoo")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { showingGenerate = true } label: {
                        Image(systemName: "sparkles").iconButtonStyle()
                    }
                    Button { showingAddNote = true } label: {
                        Image(systemName: "plus").iconButtonStyle()
                    }
                }
            }
            .accentColor(Theme.accent)

            .sheet(isPresented: $showingAddNote) {
                AddNoteView(viewModel: viewModel, parentId: nil)
                    .popupStyle()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showingGenerate) {
                GenerateNotesView(viewModel: viewModel)
                    .popupStyle()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
            }
            .sheet(item: $currentParentId) { parent in
                AddNoteView(viewModel: viewModel, parentId: parent)
                    .popupStyle()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showHelpOverlay) {
                HelpOverlayView()
            }
        }
        .onAppear { viewModel.fetchNotes() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.fetchNotes()
        }
    }
}

private struct HelpOverlayView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Setup Your Alarm Shortcut")
                .font(.headline)
            Text("""
1 Open Shortcuts and create a new shortcut named ScheduleNoteAlarm
2 Add Todoo action to fetch title and date
3 Add Set Alarm action and link inputs
4 At end add Open URL todoo://setupComplete
""")
                .multilineTextAlignment(.leading)
            Button("Open Shortcuts") {
                UIApplication.shared.open(URL(string: "shortcuts://")!)
            }
        }
        .padding()
        .background(Theme.background)
        .cornerRadius(12)
    }
}

extension Int32: @retroactive Identifiable {
    public var id: Int32 { self }
}
