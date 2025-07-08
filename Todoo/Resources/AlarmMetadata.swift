//
//  AlarmMetadata.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 7/7/25.
//
import AlarmKit

public struct NoteAlarmMetadata: AlarmMetadata {
    public let noteId: Int32
    public let title: String
}
