//
//  Note.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/14/25.
//
import Foundation

struct Note: Identifiable, Codable {
    var id: Int32 = 0
    var title: String
    var description: String
    var date: Date
    var isCompleted: Bool

}
