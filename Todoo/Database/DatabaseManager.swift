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
        addAlarmIDColumn()
    }

    private func openDatabase() {
        guard let fileURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(dbName)
        else {
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
        let sql = """
        CREATE TABLE IF NOT EXISTS Notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            parentId INTEGER,
            title TEXT NOT NULL,
            description TEXT,
            date TEXT,
            isCompleted INTEGER,
            isAlarmScheduled INTEGER DEFAULT 0,
            alarmID TEXT,
            FOREIGN KEY(parentId) REFERENCES Notes(id)
        );
        """
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            _ = sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    private func addAlarmIDColumn() {
        let sql = "ALTER TABLE Notes ADD COLUMN alarmID TEXT"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            _ = sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    func insertNote(_ note: Note) {
        let sql = """
        INSERT INTO Notes
        (parentId, title, description, date, isCompleted, isAlarmScheduled, alarmID)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if let pid = note.parentId {
                sqlite3_bind_int(stmt, 1, pid)
            } else {
                sqlite3_bind_null(stmt, 1)
            }
            sqlite3_bind_text(stmt, 2, (note.title as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (note.description as NSString).utf8String, -1, nil)
            let dateString = ISO8601DateFormatter().string(from: note.date)
            sqlite3_bind_text(stmt, 4, (dateString as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 5, note.isCompleted ? 1 : 0)
            sqlite3_bind_int(stmt, 6, note.isAlarmScheduled ? 1 : 0)
            if let alarmID = note.alarmID?.uuidString {
                sqlite3_bind_text(stmt, 7, (alarmID as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(stmt, 7)
            }
            _ = sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    func getAllNotes() -> [Note] {
        var notes = [Note]()
        let sql = """
        SELECT id, parentId, title, description, date, isCompleted, isAlarmScheduled, alarmID
        FROM Notes
        """
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = sqlite3_column_int(stmt, 0)
                let parentId: Int32? = sqlite3_column_type(stmt, 1) != SQLITE_NULL
                    ? sqlite3_column_int(stmt, 1)
                    : nil
                let title = String(cString: sqlite3_column_text(stmt, 2))
                let description = String(cString: sqlite3_column_text(stmt, 3))
                let dateString = String(cString: sqlite3_column_text(stmt, 4))
                let isCompleted = sqlite3_column_int(stmt, 5) == 1
                let isAlarmScheduled = sqlite3_column_int(stmt, 6) == 1
                let alarmIDString: String? = sqlite3_column_type(stmt, 7) != SQLITE_NULL
                    ? String(cString: sqlite3_column_text(stmt, 7))
                    : nil
                let alarmID = alarmIDString.flatMap { UUID(uuidString: $0) }
                let date = ISO8601DateFormatter().date(from: dateString) ?? Date()
                notes.append(
                    Note(
                        id: id,
                        parentId: parentId,
                        title: title,
                        description: description,
                        date: date,
                        isCompleted: isCompleted,
                        isAlarmScheduled: isAlarmScheduled,
                        alarmID: alarmID
                    )
                )
            }
        }
        sqlite3_finalize(stmt)
        return notes
    }

    func getNote(id: Int32) -> Note? {
        let sql = """
        SELECT id, parentId, title, description, date, isCompleted, isAlarmScheduled, alarmID
        FROM Notes
        WHERE id = ?
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            return nil
        }
        sqlite3_bind_int(stmt, 1, id)
        guard sqlite3_step(stmt) == SQLITE_ROW else {
            sqlite3_finalize(stmt)
            return nil
        }
        let parentId: Int32? = sqlite3_column_type(stmt, 1) != SQLITE_NULL
            ? sqlite3_column_int(stmt, 1)
            : nil
        let title = String(cString: sqlite3_column_text(stmt, 2))
        let description = String(cString: sqlite3_column_text(stmt, 3))
        let dateString = String(cString: sqlite3_column_text(stmt, 4))
        let isCompleted = sqlite3_column_int(stmt, 5) == 1
        let isAlarmScheduled = sqlite3_column_int(stmt, 6) == 1
        let alarmIDString: String? = sqlite3_column_type(stmt, 7) != SQLITE_NULL
            ? String(cString: sqlite3_column_text(stmt, 7))
            : nil
        let alarmID = alarmIDString.flatMap { UUID(uuidString: $0) }
        let date = ISO8601DateFormatter().date(from: dateString) ?? Date()
        sqlite3_finalize(stmt)
        return Note(
            id: id,
            parentId: parentId,
            title: title,
            description: description,
            date: date,
            isCompleted: isCompleted,
            isAlarmScheduled: isAlarmScheduled,
            alarmID: alarmID
        )
    }

    func updateNote(_ note: Note) {
        let sql = """
        UPDATE Notes SET
          parentId = ?,
          title = ?,
          description = ?,
          date = ?,
          isCompleted = ?,
          isAlarmScheduled = ?,
          alarmID = ?
        WHERE id = ?
        """
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if let pid = note.parentId {
                sqlite3_bind_int(stmt, 1, pid)
            } else {
                sqlite3_bind_null(stmt, 1)
            }
            sqlite3_bind_text(stmt, 2, (note.title as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (note.description as NSString).utf8String, -1, nil)
            let dateString = ISO8601DateFormatter().string(from: note.date)
            sqlite3_bind_text(stmt, 4, (dateString as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 5, note.isCompleted ? 1 : 0)
            sqlite3_bind_int(stmt, 6, note.isAlarmScheduled ? 1 : 0)
            if let alarmID = note.alarmID?.uuidString {
                sqlite3_bind_text(stmt, 7, (alarmID as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(stmt, 7)
            }
            sqlite3_bind_int(stmt, 8, note.id)
            _ = sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    func deleteNote(id: Int32) {
        let sql = "DELETE FROM Notes WHERE id = ?"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, id)
            _ = sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }
}
