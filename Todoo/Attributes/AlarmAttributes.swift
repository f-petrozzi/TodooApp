//
//  AlarmAttributes.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 7/7/25.
//
import ActivityKit
import Foundation

public struct AlarmAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var remaining: TimeInterval
    }
    public var metadata: NoteAlarmMetadata
}
