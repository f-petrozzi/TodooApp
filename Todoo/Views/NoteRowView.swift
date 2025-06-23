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
                let configured = UserDefaults.standard.bool(forKey: "isAlarmShortcutConfigured")
                guard configured else { showHelp(); return }

                let calendar = Calendar.current
                let isToday = calendar.isDate(note.date, inSameDayAs: Date())
                let iso = ISO8601DateFormatter().string(from: note.date)
                let raw = "\(iso)|\(note.title)|\(note.id)"
                guard let input = raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }

                let name = note.isAlarmScheduled ? "RemoveNoteAlarm" : "ScheduleNoteAlarm"
                let params = "noteId=\(note.id)"
                let success = "todoo://alarmRemoved?\(params)&deleted=true".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                let cancel  = "todoo://alarmRemoved?\(params)&deleted=false".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                let urlString =
                    "shortcuts://x-callback-url/run-shortcut?" +
                    "name=\(name)&input=\(input)" +
                    "&x-success=\(success)&x-cancel=\(cancel)"

                Task {
                    if note.isAlarmScheduled {
                        if isToday, let url = URL(string: urlString) {
                            await UIApplication.shared.open(url)
                        } else {
                            let intent = RemoveNoteAlarmIntent()
                            intent.noteId = Int(note.id)
                            _ = try? await intent.perform()
                        }
                    } else {
                        if isToday, let url = URL(string: urlString) {
                            await UIApplication.shared.open(url)
                            let intent = ScheduleNoteAlarmIntent()
                            intent.noteId = Int(note.id)
                            _ = try? await intent.perform()
                        } else {
                            let intent = ScheduleNoteAlarmIntent()
                            intent.noteId = Int(note.id)
                            _ = try? await intent.perform()
                        }
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
                Button { onAddChild() } label: {
                    Image(systemName: "plus.circle").iconButtonStyle(size: 24)
                }
                .tint(Theme.accent)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                let hadAlarm = note.isAlarmScheduled
                expandedParents.remove(note.id)
                viewModel.deleteNote(id: note.id)
                if hadAlarm {
                    Task {
                        let iso = ISO8601DateFormatter().string(from: note.date)
                        let raw = "\(iso)|\(note.title)|\(note.id)"
                        guard let input = raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
                        let name = "RemoveNoteAlarm"
                        let success = "todoo://setupComplete".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                        let urlStr = "shortcuts://x-callback-url/run-shortcut?name=\(name)&input=\(input)&x-success=\(success)"
                        if let url = URL(string: urlStr) {
                            await UIApplication.shared.open(url)
                        }
                    }
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
