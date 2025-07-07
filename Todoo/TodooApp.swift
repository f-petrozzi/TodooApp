//
//  TodooApp.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/11/25.
//
import SwiftUI
import UserNotifications

@main
struct TodooApp: App {
  @StateObject private var viewModel = NoteViewModel()

  init() {
    Task {
      let center = UNUserNotificationCenter.current()

      // register Snooze & Done actions
      let snooze = UNNotificationAction(
        identifier: "SNOOZE_ACTION",
        title: "Snooze",
        options: []
      )
      let done = UNNotificationAction(
        identifier: "DONE_ACTION",
        title: "Done",
        options: [.destructive]
      )
      let category = UNNotificationCategory(
        identifier: "NOTE_ALARM",
        actions: [snooze, done],
        intentIdentifiers: [],
        options: []
      )
      center.setNotificationCategories([category])
      center.delegate = NotificationDelegate.shared

      do {
        try await NotificationService.shared.requestAuthorization()
      } catch {
        print("⚠️ Notification permission error:", error)
      }
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(viewModel)
        .accentColor(Theme.accent)
    }
  }
}
