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
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("Notes table created successfully.")
            } else {
                print("Failed to create notes table.")
            }
        } else {
            print("CREATE TABLE statement could not be prepared")
        }
        
        sqlite3_finalize(createTableStatement)
    }
    
    func insertNote(_ note: Note) {
        let insertSQL = "INSERT INTO Notes (title, description, date, isCompleted) VALUES (?, ?, ?, ?)"
        var stmt:OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (note.title as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (note.description as NSString).utf8String, -1, nil)
            
            // Date
            let dateString = ISO8601DateFormatter().string(from: note.date)
            sqlite3_bind_text(stmt, 3, (dateString as NSString).utf8String, -1, nil)
            
            //Bool
            sqlite3_bind_int(stmt, 4, note.isCompleted ? 1 : 0)
            
            if sqlite3_step(stmt) == SQLITE_DONE {
                print("Inserted note")
            } else {
                print("Could not insert note")
            }
        } else {
            print("Could not prepare INSERT statement")
        }
        
        sqlite3_finalize(stmt)
    }
    
    func getAllNotes() -> [Note] {
        var notes: [Note] = []
        let querySQL = "SELECT * FROM Notes;"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, querySQL, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = sqlite3_column_int(stmt, 0)
                let title = String(cString: sqlite3_column_text(stmt, 1))
                let description = String(cString: sqlite3_column_text(stmt, 2))
                let dateString = String(cString: sqlite3_column_text(stmt, 3))
                let isCompleted = sqlite3_column_int(stmt, 4) == 1
                
                // String Date
                let date = ISO8601DateFormatter().date(from: dateString) ?? Date()
                
                let note = Note(id: id, title: title, description: description, date: date, isCompleted: isCompleted)
                notes.append(note)
            }
        } else {
            print("SELECT statement could not be prepared")
        }
        sqlite3_finalize(stmt)
        return notes
    }

    func updateNote(_ note: Note) {
        let updateSQL = "UPDATE Notes SET title = ?, description = ?, date = ?, isCompleted = ? WHERE id = ?;"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, updateSQL, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (note.title as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (note.description as NSString).utf8String, -1, nil)
            let dateString = ISO8601DateFormatter().string(from: note.date)
            sqlite3_bind_text(stmt, 3, (dateString as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 4, note.isCompleted ? 1 : 0)
            sqlite3_bind_int(stmt, 5, note.id)
            
            if sqlite3_step(stmt) == SQLITE_DONE {
                print("Updated note")
            } else {
                print("Could not update note")
            }
        } else {
            print("UPDATE statement could not be prepared")
        }
        sqlite3_finalize(stmt)
    }
    
    func deleteNote(id: Int32) {
        let deleteSQL = "DELETE FROM Notes WHERE id = ?;"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteSQL, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, id)
            
            if sqlite3_step(stmt) == SQLITE_DONE {
                print("Deleted note")
            } else {
                print("Could note delete note")
            }
        } else {
            print("DELETE statement could not be prepared")
        }
        sqlite3_finalize(stmt)
    }
}
