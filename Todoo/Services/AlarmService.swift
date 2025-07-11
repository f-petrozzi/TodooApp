//
//  AlarmService.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 7/7/25.
//
import Foundation
import AlarmKit
import SwiftUI
import AppIntents
import ActivityKit

class AlarmService {
    static let shared = AlarmService()
    private init() {}

    func requestAuthorization() async throws {
        guard AlarmManager.shared.authorizationState == .notDetermined else { return }
        _ = try await AlarmManager.shared.requestAuthorization()
    }

    func scheduleAlarm(
        noteID: Int32,
        alarmID: UUID,
        date: Date,
        title: String
    ) async throws {
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: title),
            stopButton: AlarmButton(
                text: LocalizedStringResource(stringLiteral: "Done"),
                textColor: .white,
                systemImageName: "xmark"
            ),
            secondaryButton: AlarmButton(
                text: LocalizedStringResource(stringLiteral: "Snooze"),
                textColor: .white,
                systemImageName: "moon.zzz"
            ),
            secondaryButtonBehavior: .countdown
        )

        let attributes = AlarmAttributes(
            presentation: AlarmPresentation(alert: alert),
            metadata: NoteAlarmMetadata(noteID: noteID, title: title),
            tintColor: .accentColor
        )

        let configuration: AlarmManager.AlarmConfiguration<NoteAlarmMetadata> = .alarm(
            schedule: .fixed(date),
            attributes: attributes,
            stopIntent: StopAlarmIntent(alarmIDString: alarmID.uuidString),
            secondaryIntent: SnoozeAlarmIntent(alarmIDString: alarmID.uuidString),
            sound: .default
        )

        _ = try await AlarmManager.shared.schedule(
            id: alarmID,
            configuration: configuration
        )
    }

    func cancelAlarm(alarmID: UUID) async throws {
        try await AlarmManager.shared.cancel(id: alarmID)
    }

    func stopAlarm(alarmID: UUID) async throws {
        try await AlarmManager.shared.stop(id: alarmID)
    }

    func snoozeAlarm(alarmID: UUID) async throws {
        try await AlarmManager.shared.countdown(id: alarmID)
    }
}
