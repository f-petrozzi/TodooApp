//
//  TodooLiveActivityLiveActivity.swift
//  TodooLiveActivity
//
//  Created by Fabrizio Petrozzi on 7/7/25.
//
import WidgetKit
import SwiftUI
import ActivityKit
import AppIntents
import Foundation

public struct NoteAlarmMetadata: Codable, Hashable, Sendable {
    public let noteId: Int32
    public let title: String
}

public struct AlarmAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var remaining: TimeInterval
    }
    public var metadata: NoteAlarmMetadata
}

@main
struct TodooLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes.self) { context in
            VStack(spacing: 8) {
                Text(context.attributes.metadata.title)
                Text("\(Int(context.state.remaining))s remaining")
            }
            .activityBackgroundTint(.blue)
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "bell.fill")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.metadata.title)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(Int(context.state.remaining))s")
                }
            } compactLeading: {
                Image(systemName: "bell.fill")
            } compactTrailing: {
                Text("\(Int(context.state.remaining))s")
            } minimal: {
                Image(systemName: "bell.fill")
            }
            .widgetURL(
                URL(string: "todoo://alarm?noteId=\(context.attributes.metadata.noteId)")
            )
            .keylineTint(.blue)
        }
    }
}
