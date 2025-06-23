//
//  NoteRowView.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/22/25.
//
import SwiftUI
import AppIntents

struct NoteRow: View {
    let note: Note
    let children: [Note]
    @Binding var expandedParents: Set<Int32>
    @ObservedObject var viewModel: NoteViewModel
    let showHelp: () -> Void

    let isParent: Bool
    let onAddChild: () -> Void

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    var body: some View {
        HStack {
            // Title, description, and date
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

            // Expand/collapse indicator
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

            // Completion toggle
            Button {
                viewModel.toggleComplete(note: note)
            } label: {
                Image(systemName: note.isCompleted ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(.plain)

            // Alarm toggle button
            Button {
                let configured = UserDefaults.standard.bool(forKey: "isAlarmShortcutConfigured")
                print("Bell tapped; isAlarmShortcutConfigured = \(configured)")
                guard configured else {
                    showHelp()
                    return
                }

                let iso = ISO8601DateFormatter().string(from: note.date)
                let raw = iso + "|" + note.title
                guard let input = raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                    return
                }
                let name = note.isAlarmScheduled ? "RemoveNoteAlarm" : "ScheduleNoteAlarm"
                let urlString =
                    "shortcuts://x-callback-url/run-shortcut?" +
                    "name=\(name)&input=\(input)&x-success=todoo://setupComplete"
                print("Will open \(name) URL →", urlString)

                Task {
                    if let url = URL(string: urlString) {
                        await UIApplication.shared.open(url)
                    }
                    // Update local flag via AppIntent
                    if note.isAlarmScheduled {
                        let intent = RemoveNoteAlarmIntent()
                        intent.noteId = Int(note.id)
                        _ = try? await intent.perform()
                    } else {
                        let intent = ScheduleNoteAlarmIntent()
                        intent.noteId = Int(note.id)
                        _ = try? await intent.perform()
                    }
                    viewModel.fetchNotes()
                }
            } label: {
                Image(systemName: note.isAlarmScheduled ? "bell.fill" : "bell")
            }
            .buttonStyle(.plain)
        }
        .cardStyle()
        .swipeActions(edge: .leading) {
            if isParent {
                Button {
                    onAddChild()
                } label: {
                    Image(systemName: "plus.circle")
                        .iconButtonStyle(size: 24)
                }
                .tint(Theme.accent)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                // 1) Remove from UI immediately
                expandedParents.remove(note.id)
                viewModel.deleteNote(id: note.id)
                
                // 2) Then delete the alarm asynchronously
                Task {
                    if note.isAlarmScheduled {
                        let iso = ISO8601DateFormatter().string(from: note.date)
                        let raw = iso + "|" + note.title
                        guard let input = raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                            return
                        }
                        let urlString =
                            "shortcuts://x-callback-url/run-shortcut?" +
                            "name=RemoveNoteAlarm&input=\(input)&x-success=todoo://setupComplete"
                        if let url = URL(string: urlString) {
                            await UIApplication.shared.open(url)
                        }
                        let intent = RemoveNoteAlarmIntent()
                        intent.noteId = Int(note.id)
                        _ = try? await intent.perform()
                    }
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
