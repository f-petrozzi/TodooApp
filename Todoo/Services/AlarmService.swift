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

    let id = Self.uuid(for: note.id)
    try? await manager.cancel(id: id)

    let stop = AlarmButton(
      text: "Dismiss",
      textColor: .white,
      systemImageName: "xmark.circle.fill"
    )
    let snooze = AlarmButton(
      text: "Snooze",
      textColor: .white,
      systemImageName: "repeat"
    )
    let alert = AlarmPresentation.Alert(
      title: LocalizedStringResource(stringLiteral: note.title),
      stopButton: stop,
      secondaryButton: snooze,
      secondaryButtonBehavior: .countdown
    )
    let presentation = AlarmPresentation(alert: alert)
    let attrs = AlarmAttributes<NoMetadata>(
      presentation: presentation,
      tintColor: .blue
    )

    let schedule = Alarm.Schedule.fixed(note.date)
    let config = AlarmManager.AlarmConfiguration<NoMetadata>(
      schedule: schedule,
      attributes: attrs
    )

    _ = try await manager.schedule(id: id, configuration: config)
  }

  @MainActor
  func cancel(noteId: Int32) async throws {
    try await ensureAuthorized()
    let id = Self.uuid(for: noteId)
    _ = try await manager.cancel(id: id)
  }

  nonisolated private static func uuid(for noteId: Int32) -> UUID {
    let hex = String(noteId, radix: 16)
    let padded = String(repeating: "0", count: 12 - hex.count) + hex
    return UUID(uuidString: "00000000-0000-0000-0000-\(padded)")!
  }
}
