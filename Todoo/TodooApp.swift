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
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainView(viewModel: viewModel)
                .accentColor(Theme.accent)
                .onAppear {
                    DatabaseManager.shared.markOverdueNotesForAutoArchive()
                }
        }
        .onChange(of: scenePhase) { newPhase, oldPhase in
            if newPhase == .active {
                DatabaseManager.shared.markOverdueNotesForAutoArchive()
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        DatabaseManager.shared.markOverdueNotesForAutoArchive()
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
