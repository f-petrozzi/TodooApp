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
    init() {
        UNUserNotificationCenter
            .current()
            .requestAuthorization(options: [.alert, .sound]) { granted, _ in
                if !granted {
                    print("Notifications permission denied")
                }
            }
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .accentColor(Theme.accent)
                .onOpenURL { url in
                    guard url.scheme == "todoo",
                          url.host   == "setupComplete"
                    else { return }
                    UserDefaults.standard.set(
                        true,
                        forKey: "isAlarmShortcutConfigured"
                    )
                }
        }
    }
}
