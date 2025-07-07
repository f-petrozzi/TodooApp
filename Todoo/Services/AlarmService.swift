//
//  AlarmService.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 7/7/25.
//
import AlarmKit
import Foundation
import SwiftUI

enum AlarmError: Error {
    case invalidDate
    case noPermission
    case uuidCreationFailed
}

actor AlarmService {
    static let shared = AlarmService()
    private let manager = AlarmManager.shared

    @MainActor
    private func ensureAuthorized() async throws {
        let state = manager.authorizationState
        if state == .notDetermined {
            let newState = try await manager.requestAuthorization()
            guard newState == .authorized else { throw AlarmError.noPermission }
        } else if state != .authorized {
            throw AlarmError.noPermission
        }
    }

    @MainActor
    func schedule(note: Note) async throws {
        try await ensureAuthorized()
        guard note.date > Date() else { throw AlarmError.invalidDate }
        let id = try Self.uuid(for: note.id)
        try? await manager.cancel(id: id)
        let presentation = makePresentation(for: note.title)
        let metadata = NoteAlarmMetadata(noteId: note.id, title: note.title)
        let attrs = AlarmKit.AlarmAttributes<NoteAlarmMetadata>(
            presentation: presentation,
            metadata: metadata,
            tintColor: Color.blue
        )
        let schedule = Alarm.Schedule.fixed(note.date)
        let config = AlarmManager.AlarmConfiguration(schedule: schedule, attributes: attrs)
        _ = try await manager.schedule(id: id, configuration: config)
    }

    @MainActor
    func cancel(noteId: Int32) async throws {
        try await ensureAuthorized()
        let id = try Self.uuid(for: noteId)
        _ = try await manager.cancel(id: id)
    }

    @MainActor
    private func makePresentation(for title: String) -> AlarmPresentation {
        let stop = AlarmButton(text: "Dismiss", textColor: .white, systemImageName: "xmark.circle.fill")
        let snooze = AlarmButton(text: "Snooze", textColor: .white, systemImageName: "repeat")
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: title),
            stopButton: stop,
            secondaryButton: snooze,
            secondaryButtonBehavior: .countdown
        )
        return AlarmPresentation(alert: alert)
    }

    nonisolated private static func uuid(for noteId: Int32) throws -> UUID {
        let hex = String(noteId, radix: 16)
        let padded = String(repeating: "0", count: 12 - hex.count) + hex
        let str = "00000000-0000-0000-0000-\(padded)"
        guard let uuid = UUID(uuidString: str) else { throw AlarmError.uuidCreationFailed }
        return uuid
    }
}
