//
//  AlarmAttributes.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 7/7/25.
//
import AlarmKit
import Foundation

@MainActor
public struct NoteAlarmMetadata: AlarmMetadata, Codable {
    public let noteID: Int32
    public let title: String
}

public typealias AlarmAttributes = AlarmKit.AlarmAttributes<NoteAlarmMetadata>
