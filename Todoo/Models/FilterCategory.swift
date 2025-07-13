//
//  FilterCategory.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 7/13/25.
//
import Foundation

enum FilterCategory: String, CaseIterable, Identifiable {
    case today
    case reminder
    case upcoming
    case done
    case archived

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .today:    return "Today"
        case .reminder: return "Reminder"
        case .upcoming: return "Upcoming"
        case .done:     return "Done"
        case .archived: return "Archived"
        }
    }
}
