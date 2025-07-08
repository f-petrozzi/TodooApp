//
//  TodooLiveActivityLiveActivity.swift
//  TodooLiveActivity
//
//  Created by Fabrizio Petrozzi on 7/7/25.
//
import WidgetKit
import SwiftUI
import ActivityKit
import Foundation

public struct NoteAlarmMetadata: Codable, Hashable, Sendable {
    public let noteId: Int32
    public let title: String
}

public struct AlarmAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {}
    public var metadata: NoteAlarmMetadata
    public var endDate: Date
}

@main
struct TodooLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes.self) { context in
            VStack(spacing: 8) {
                Text(context.attributes.metadata.title)
                Text(timerInterval: Date()...context.attributes.endDate,
                     countsDown: true)
            }
            .activityBackgroundTint(.blue)
            .activitySystemActionForegroundColor(.white)
            .widgetURL(URL(string: "todoo://alarm?noteId=\(context.attributes.metadata.noteId)"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "bell.fill")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.metadata.title)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(timerInterval: Date()...context.attributes.endDate,
                         countsDown: true)
                }
            } compactLeading: {
                Image(systemName: "bell.fill")
            } compactTrailing: {
                Text(timerInterval: Date()...context.attributes.endDate,
                     countsDown: true)
            } minimal: {
                Image(systemName: "bell.fill")
            }
        }
    }
}
