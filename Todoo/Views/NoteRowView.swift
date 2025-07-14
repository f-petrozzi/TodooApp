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

    @State private var showDeletionInfo = false
    @State private var countdownText = ""
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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
                HStack(alignment: .center) {
                    Group {
                        if note.description.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.vPadding) {
                                Text(note.title)
                                    .font(.title2.weight(.semibold))
                                    .foregroundColor(.primary)
                                HStack(spacing: 4) {
                                    Text(Self.dateFormatter.string(from: note.date))
                                        .font(Theme.subheadlineFont)
                                        .foregroundColor(.secondary)
                                    if note.isMarkedForDeletion, let scheduled = note.deletionScheduledAt {
                                        Image(systemName: "hourglass")
                                            .onTapGesture {
                                                showDeletionInfo.toggle()
                                                if showDeletionInfo {
                                                    countdownText = timeRemaining(until: scheduled)
                                                }
                                            }
                                            .overlay(
                                                Group {
                                                    if showDeletionInfo {
                                                        HStack(spacing: 4) {
                                                            Text("deletes in")
                                                                .font(.caption2)
                                                                .lineLimit(1)
                                                            Text(countdownText)
                                                                .font(.caption2.monospacedDigit())
                                                                .lineLimit(1)
                                                        }
                                                        .padding(6)
                                                        .background(Color(.systemBackground))
                                                        .cornerRadius(8)
                                                        .shadow(radius: 4)
                                                        .fixedSize(horizontal: true, vertical: false)
                                                        .offset(x: 30, y: 0)
                                                        .transition(.opacity)
                                                    }
                                                }, alignment: .trailing
                                            )
                                    }
                                }
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
                                HStack(spacing: 4) {
                                    Text(Self.dateFormatter.string(from: note.date))
                                        .font(Theme.subheadlineFont)
                                        .foregroundColor(.secondary)
                                    if note.isMarkedForDeletion, let scheduled = note.deletionScheduledAt {
                                        Image(systemName: "hourglass")
                                            .onTapGesture {
                                                showDeletionInfo.toggle()
                                                if showDeletionInfo {
                                                    countdownText = timeRemaining(until: scheduled)
                                                }
                                            }
                                            .overlay(
                                                Group {
                                                    if showDeletionInfo {
                                                        HStack(spacing: 4) {
                                                            Text("deletes in")
                                                                .font(.caption2)
                                                                .lineLimit(1)
                                                            Text(countdownText)
                                                                .font(.caption2.monospacedDigit())
                                                                .lineLimit(1)
                                                        }
                                                        .padding(6)
                                                        .background(Color(.systemBackground))
                                                        .cornerRadius(8)
                                                        .shadow(radius: 4)
                                                        .fixedSize(horizontal: true, vertical: false)
                                                        .offset(x: 30, y: 0)
                                                        .transition(.opacity)
                                                    }
                                                }, alignment: .trailing
                                            )
                                    }
                                }
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
        .contentShape(Rectangle())
        .onTapGesture {
            if showDeletionInfo {
                showDeletionInfo = false
            }
        }
        .onReceive(timer) { _ in
            if showDeletionInfo, let scheduled = note.deletionScheduledAt {
                countdownText = timeRemaining(until: scheduled)
            }
        }
    }

    private func timeRemaining(until date: Date) -> String {
        let interval = Int(date.timeIntervalSince(Date()))
        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        let seconds = interval % 60
        var parts: [String] = []
        if hours > 0 { parts.append("\(hours)h") }
        if hours > 0 || minutes > 0 { parts.append("\(minutes)m") }
        parts.append("\(seconds)s")
        return parts.joined(separator: " ")
    }
}
