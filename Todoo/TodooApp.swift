//
//  TodooApp.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/11/25.
//
import SwiftUI

@main
struct TodooApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainView(viewModel: NoteViewModel())
                .onOpenURL { url in
                    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                          let host = components.host,
                          let queryItem = components.queryItems?.first(where: { $0.name == "noteId" }),
                          let noteIdString = queryItem.value,
                          let noteId = Int32(noteIdString)
                    else { return }

                    switch host {
                    case "snooze":
                        if let note = DatabaseManager.shared.getNote(id: noteId) {
                            Task { try? await AlarmService.shared.schedule(note: note) }
                        }
                    case "dismiss":
                        Task { try? await AlarmService.shared.cancel(noteId: noteId) }
                    default:
                        break
                    }
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        return true
    }
}
