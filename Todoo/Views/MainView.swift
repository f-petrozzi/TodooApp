//
//  MainView.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/15/25
//
import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = NoteViewModel()
    @State private var showingAddNote = false
    @State private var showingGenerate = false
    @State private var currentParentId: Int32? = nil
    @State private var expandedParents = Set<Int32>()
    @State private var showHelpOverlay = false

    private static let dateFormatter = DateFormatter().configured {
        $0.dateStyle = .medium
        $0.timeStyle = .short
    }

    var body: some View {
        NavigationView {
            List {
                let rootNotes = viewModel.notes.filter { $0.parentId == nil }
                ForEach(rootNotes) { note in
                    let children = viewModel.notes.filter { $0.parentId == note.id }
                    HStack {
                        Group {
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
                                Image(systemName: expandedParents.contains(note.id) ? "chevron.down" : "chevron.right")
                            }
                            .buttonStyle(.plain)
                        } else {
                            Spacer().frame(width: 20)
                        }
                        Button {
                            viewModel.toggleComplete(note: note)
                        } label: {
                            Image(systemName: note.isCompleted ? "checkmark.circle.fill" : "circle")
                        }
                        .buttonStyle(.plain)
                        Button {
                            if UserDefaults.standard.bool(forKey: "isAlarmShortcutConfigured") {
                                sendToShortcuts(note)
                            } else {
                                showHelpOverlay = true
                            }
                        } label: {
                            Image(systemName: "bell")
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
                                    Image(systemName: child.isCompleted ? "checkmark.circle.fill" : "circle")
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
        .onAppear {
            viewModel.fetchNotes()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.fetchNotes()
        }
    }

    private func sendToShortcuts(_ note: Note) {
        let isoDate = ISO8601DateFormatter().string(from: note.date)
        let raw = isoDate + "|" + note.title
        guard let input = raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string:
                "shortcuts://x-callback-url/run-shortcut?name=ScheduleNoteAlarm&input=\(input)"
              )
        else {
            return
        }
        UIApplication.shared.open(url)
    }
}

private struct HelpOverlayView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Setup Your Alarm Shortcut")
                .font(.headline)
            Text("1 Open Shortcuts and create a new shortcut named ScheduleNoteAlarm\n2 Add Todoo action to fetch title and date\n3 Add Set Alarm action and link inputs\n4 At end add Open URL todoo://setupComplete")
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

extension Int32: Identifiable {
    public var id: Int32 { self }
}

private extension DateFormatter {
    func configured(_ block: (DateFormatter) -> Void) -> DateFormatter {
        block(self)
        return self
    }
}
