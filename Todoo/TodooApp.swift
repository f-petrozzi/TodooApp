//
//  TodooApp.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/11/25.
//
//
import SwiftUI
import UserNotifications
import AppIntents

@main
@available(iOS 17.0, *)
struct TodooApp: App {
    @StateObject private var viewModel = NoteViewModel()

    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    var body: some Scene {
        WindowGroup {
            MainView(viewModel: viewModel)
                .accentColor(Theme.accent)
                .onOpenURL { url in
                    guard url.scheme == "todoo" else { return }
                    if url.host == "setupComplete" {
                        UserDefaults.standard.set(true, forKey: "isAlarmShortcutConfigured")
                    } else if url.host == "alarmRemoved",
                              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
                              let noteIdStr = comps.queryItems?.first(where: { $0.name == "noteId" })?.value,
                              let noteId = Int32(noteIdStr),
                              let deletedStr = comps.queryItems?.first(where: { $0.name == "deleted" })?.value,
                              let deleted = Bool(deletedStr) {
                        if var note = viewModel.notes.first(where: { $0.id == noteId }) {
                            note.isAlarmScheduled = !deleted
                            DatabaseManager.shared.updateNote(note)
                            viewModel.fetchNotes()
                        }
                    }
                }
        }
    }
}

