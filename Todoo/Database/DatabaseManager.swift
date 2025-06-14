//
//  DatabaseManager.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/14/25.
//

import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let dbName = "Todoo.sqlite"
    private var db: OpaquePointer?

    private init() {
        openDatabase()
        createNotesTable()
    }
    
    private func openDatabase() {
        guard let fileURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(dbName) else {
                print("Failed to construct database file URL")
                return
            }
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("Error opening database at \(fileURL.path)")
        } else {
            print("Database opened at \(fileURL.path)")
        }
    }
    
    private func createNotesTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS Notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            date TEXT,
            isCompleted INTEGER
        );
        """
        
        var createTableStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, createTableQuery, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) != SQLITE_DONE {
                print("Notes table created successfully.")
            } else {
                print("Failed to create notes table.")
            }
        } else {
            print("CREATE TABLE statement could not be prepared")
        }
        
        sqlite3_finalize(createTableStatement)
    }
}
