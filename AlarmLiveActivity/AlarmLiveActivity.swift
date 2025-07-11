//
//  AlarmLiveActivity.swift
//  AlarmLiveActivity
//
//  Created by Fabrizio Petrozzi on 7/11/25.
//
import WidgetKit
import SwiftUI
import ActivityKit
import AlarmKit

@main
struct AlarmLiveActivity: WidgetBundle {
    var body: some Widget {
        AlarmWidget()
    }
}

struct AlarmWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmKit.AlarmAttributes<NoteAlarmMetadata>.self) { context in
            let title = context.attributes.metadata?.title ?? ""
            VStack {
                if case let .countdown(countdown) = context.state.mode {
                    Text(timerInterval: Date.now...countdown.fireDate)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                } else {
                    Text(title)
                        .font(.headline)
                }
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    if case let .countdown(countdown) = context.state.mode {
                        Text(timerInterval: Date.now...countdown.fireDate)
                            .font(.headline).monospacedDigit()
                    } else {
                        let title = context.attributes.metadata?.title ?? ""
                        Text(title)
                    }
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
            } compactTrailing: {
                if case let .countdown(countdown) = context.state.mode {
                    let remaining = Int(countdown.fireDate.timeIntervalSinceNow)
                    Text("\(max(0, remaining))s")
                } else {
                    Text(" ")
                }
            } minimal: {
                Image(systemName: "alarm.fill")
            }
        }
    }
}
