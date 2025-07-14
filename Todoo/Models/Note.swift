//
//  Note.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/14/25.
//
import Foundation

struct Note: Identifiable, Codable, Equatable {
    var id: Int32 = 0
    var parentId: Int32?
    var title: String
    var description: String
    var date: Date
    var isCompleted: Bool
    var isAlarmScheduled: Bool = false
    var alarmID: UUID? = nil
    var createdAt: Date = Date()
    var completedAt: Date? = nil
    var isArchived: Bool = false
    var archivedAt: Date? = nil
    var isAutoArchived: Bool = false
    var recurrenceRule: String? = nil
    var isMarkedForDeletion: Bool = false
    var deletionScheduledAt: Date? = nil
}
