//
//  NoteRowView.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/22/25.
//
import SwiftUI

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
        Group {
            if !isParent {
                HStack {
                    Text(note.title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Button {
                        viewModel.toggleComplete(note: note)
                    } label: {
                        Image(systemName: note.isCompleted ? "checkmark.circle.fill" : "circle")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 0)
                .padding(.leading, 2)
                .cardStyle()
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        viewModel.delete(note: note)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }

            } else {
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
                        Task {
                            if note.isAlarmScheduled, let alarmID = note.alarmID {
                                try await AlarmService.shared.cancelAlarm(alarmID: alarmID)
                                viewModel.clearAlarm(for: note)
                            } else {
                                try await AlarmService.shared.requestAuthorization()
                                let id = UUID()
                                try await AlarmService.shared.scheduleAlarm(
                                    noteID: note.id,
                                    alarmID: id,
                                    date: note.date,
                                    title: note.title
                                )
                                viewModel.setAlarm(for: note, alarmID: id)
                            }
                        }
                    } label: {
                        Image(systemName: note.isAlarmScheduled ? "bell.fill" : "bell")
                    }
                    .buttonStyle(.plain)
                    .disabled(note.date < Date())
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
                        expandedParents.remove(note.id)
                        viewModel.delete(note: note)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}
