//
//  TodooApp.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/11/25.
//
import SwiftUI
import AlarmKit

@main
struct TodooApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = NoteViewModel()

    var body: some Scene {
        WindowGroup {
            MainView(viewModel: viewModel)
                .accentColor(Theme.accent)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Task {
            _ = try? await AlarmManager.shared.requestAuthorization()
        }

        Task {
            for await alarms in AlarmManager.shared.alarmUpdates {
                print("🔔 alarmUpdate id=\(alarms.map(\.id)) state=\(alarms.map(\.state))")
            }
        }

        return true
    }
}
