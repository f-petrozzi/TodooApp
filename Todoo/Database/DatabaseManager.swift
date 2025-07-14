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
        performMigrations()
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

    private func performMigrations() {
        createNotesTable()
        addAlarmIDColumn()
        addCreatedAtColumn()
        addCompletedAtColumn()
        addArchivedColumn()
        addRecurrenceRuleColumn()
        createIndexes()
        createFTSTable()
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

    private func addCreatedAtColumn() {
        let sql = "ALTER TABLE Notes ADD COLUMN createdAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            _ = sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    private func addCompletedAtColumn() {
        let sql = "ALTER TABLE Notes ADD COLUMN completedAt TEXT"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            _ = sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    private func addArchivedColumn() {
        let sql = "ALTER TABLE Notes ADD COLUMN isArchived INTEGER NOT NULL DEFAULT 0"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            _ = sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    private func addRecurrenceRuleColumn() {
        let sql = "ALTER TABLE Notes ADD COLUMN recurrenceRule TEXT"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            _ = sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    private func createIndexes() {
        let indexes = [
            "CREATE INDEX IF NOT EXISTS idx_notes_date ON Notes(date)",
            "CREATE INDEX IF NOT EXISTS idx_notes_completed ON Notes(isCompleted)",
            "CREATE INDEX IF NOT EXISTS idx_notes_archived ON Notes(isArchived)",
            "CREATE INDEX IF NOT EXISTS idx_notes_recurrencerule ON Notes(recurrenceRule)"
        ]
        for sql in indexes {
            execute(sql: sql)
        }
    }

    private func createFTSTable() {
        let sql = """
        CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts
        USING fts5(title, description, content='Notes', content_rowid='id');
        """
        execute(sql: sql)
    }

    func execute(sql: String) {
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        sqlite3_step(stmt)
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
        SELECT id, parentId, title, description, date,
               isCompleted, isAlarmScheduled, alarmID,
               createdAt, completedAt, isArchived, recurrenceRule
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
                let description = sqlite3_column_text(stmt, 3).flatMap { String(cString: $0) } ?? ""
                let dateString = String(cString: sqlite3_column_text(stmt, 4))
                let isCompleted = sqlite3_column_int(stmt, 5) == 1
                let isAlarmScheduled = sqlite3_column_int(stmt, 6) == 1
                let alarmID: UUID? = sqlite3_column_type(stmt, 7) != SQLITE_NULL
                    ? UUID(uuidString: String(cString: sqlite3_column_text(stmt, 7)))
                    : nil
                let createdAtString = String(cString: sqlite3_column_text(stmt, 8))
                let completedAtString = sqlite3_column_text(stmt, 9).flatMap { String(cString: $0) }
                let isArchived = sqlite3_column_int(stmt, 10) == 1
                let recurrenceRule = sqlite3_column_text(stmt, 11).flatMap { String(cString: $0) }
                let date = ISO8601DateFormatter().date(from: dateString) ?? Date()
                let createdAt = ISO8601DateFormatter().date(from: createdAtString) ?? Date()
                let completedAt = completedAtString.flatMap {
                    ISO8601DateFormatter().date(from: $0)
                }
                notes.append(
                    Note(
                        id: id,
                        parentId: parentId,
                        title: title,
                        description: description,
                        date: date,
                        isCompleted: isCompleted,
                        isAlarmScheduled: isAlarmScheduled,
                        alarmID: alarmID,
                        createdAt: createdAt,
                        completedAt: completedAt,
                        isArchived: isArchived,
                        recurrenceRule: recurrenceRule
                    )
                )
            }
        }
        sqlite3_finalize(stmt)
        return notes
    }

    func getNote(id: Int32) -> Note? {
        let sql = """
        SELECT id, parentId, title, description, date,
               isCompleted, isAlarmScheduled, alarmID,
               createdAt, completedAt, isArchived, recurrenceRule
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
        let alarmID: UUID? = sqlite3_column_type(stmt, 7) != SQLITE_NULL
            ? UUID(uuidString: String(cString: sqlite3_column_text(stmt, 7)))
            : nil
        let createdAtString = String(cString: sqlite3_column_text(stmt, 8))
        let completedAtString = sqlite3_column_text(stmt, 9).flatMap { String(cString: $0) }
        let isArchived = sqlite3_column_int(stmt, 10) == 1
        let recurrenceRule = sqlite3_column_text(stmt, 11).flatMap { String(cString: $0) }
        sqlite3_finalize(stmt)
        let date = ISO8601DateFormatter().date(from: dateString) ?? Date()
        let createdAt = ISO8601DateFormatter().date(from: createdAtString) ?? Date()
        let completedAt = completedAtString.flatMap {
            ISO8601DateFormatter().date(from: $0)
        }
        return Note(
            id: id,
            parentId: parentId,
            title: title,
            description: description,
            date: date,
            isCompleted: isCompleted,
            isAlarmScheduled: isAlarmScheduled,
            alarmID: alarmID,
            createdAt: createdAt,
            completedAt: completedAt,
            isArchived: isArchived,
            recurrenceRule: recurrenceRule
        )
    }

    func updateNote(_ note: Note) {
        let sql = """
        UPDATE Notes SET
          parentId        = ?,
          title           = ?,
          description     = ?,
          date            = ?,
          isCompleted     = ?,
          isAlarmScheduled = ?,
          alarmID         = ?,
          createdAt       = ?,
          completedAt     = ?,
          isArchived      = ?,
          recurrenceRule  = ?
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
            sqlite3_bind_text(stmt, 4,
                (ISO8601DateFormatter().string(from: note.date) as NSString).utf8String,
                -1, nil
            )
            sqlite3_bind_int(stmt, 5, note.isCompleted ? 1 : 0)
            sqlite3_bind_int(stmt, 6, note.isAlarmScheduled ? 1 : 0)
            if let aid = note.alarmID?.uuidString {
                sqlite3_bind_text(stmt, 7, (aid as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(stmt, 7)
            }
            sqlite3_bind_text(stmt, 8,
                (ISO8601DateFormatter().string(from: note.createdAt) as NSString).utf8String,
                -1, nil
            )
            if let comp = note.completedAt {
                sqlite3_bind_text(stmt, 9,
                    (ISO8601DateFormatter().string(from: comp) as NSString).utf8String,
                    -1, nil
                )
            } else {
                sqlite3_bind_null(stmt, 9)
            }
            sqlite3_bind_int(stmt, 10, note.isArchived ? 1 : 0)
            if let rule = note.recurrenceRule {
                sqlite3_bind_text(stmt, 11, (rule as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(stmt, 11)
            }
            sqlite3_bind_int(stmt, 12, note.id)
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

    enum SortOption { case alarm, created, title }

    func fetchNotes(category: FilterCategory, sort: SortOption) -> [Note] {
        let orderClause: String = {
            switch sort {
            case .alarm:   return "date COLLATE NOCASE"
            case .created: return "createdAt DESC"
            case .title:   return "title COLLATE NOCASE"
            }
        }()

        let whereClause: String = {
            switch category {
            case .overdue:
                return """
                datetime(date, 'localtime') < datetime('now','localtime')
                AND isCompleted = 0
                AND isArchived  = 0
                """
            case .today:
                return """
                date(date, 'localtime') = date('now','localtime')
                AND isCompleted = 0
                AND isArchived  = 0
                """
            case .reminder:
                return "recurrenceRule IS NOT NULL AND isArchived = 0"
            case .upcoming:
                return """
                datetime(date, 'localtime') 
                  >= datetime('now','localtime','start of day','+1 day')
                AND isCompleted = 0
                AND isArchived  = 0
                """
            case .done:
                return """
                isCompleted = 1
                AND isArchived = 0
                AND datetime(completedAt, 'localtime')
                  >= datetime('now','localtime','-1 day')
                """
            case .archived:
                return "isArchived = 1"
            }
        }()

        let sql = """
        SELECT id, parentId, title, description, date,
               isCompleted, isAlarmScheduled, alarmID,
               createdAt, completedAt, isArchived, recurrenceRule
          FROM Notes
         WHERE \(whereClause)
         ORDER BY \(orderClause);
        """
        return query(sql: sql)
    }

    func cleanupCompletedNotes() {
        let sql = """
        DELETE FROM Notes
         WHERE isCompleted = 1
           AND isArchived  = 0
           AND completedAt < datetime('now','-1 day');
        """
        execute(sql: sql)
    }

    private func query(sql: String) -> [Note] {
        var result = [Note]()
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = sqlite3_column_int(stmt, 0)
                let parentId: Int32? = sqlite3_column_type(stmt, 1) != SQLITE_NULL
                    ? sqlite3_column_int(stmt, 1)
                    : nil
                let title = String(cString: sqlite3_column_text(stmt, 2))
                let description = sqlite3_column_text(stmt, 3).flatMap { String(cString: $0) } ?? ""
                let dateString = String(cString: sqlite3_column_text(stmt, 4))
                let isCompleted = sqlite3_column_int(stmt, 5) == 1
                let isAlarmScheduled = sqlite3_column_int(stmt, 6) == 1
                let alarmID: UUID? = sqlite3_column_type(stmt, 7) != SQLITE_NULL
                    ? UUID(uuidString: String(cString: sqlite3_column_text(stmt, 7)))
                    : nil
                let createdAtString = String(cString: sqlite3_column_text(stmt, 8))
                let completedAtString = sqlite3_column_text(stmt, 9).flatMap { String(cString: $0) }
                let isArchived = sqlite3_column_int(stmt, 10) == 1
                let recurrenceRule = sqlite3_column_text(stmt, 11).flatMap { String(cString: $0) }
                let date = ISO8601DateFormatter().date(from: dateString) ?? Date()
                let createdAt = ISO8601DateFormatter().date(from: createdAtString) ?? Date()
                let completedAt = completedAtString.flatMap {
                    ISO8601DateFormatter().date(from: $0)
                }
                result.append(
                    Note(
                        id: id,
                        parentId: parentId,
                        title: title,
                        description: description,
                        date: date,
                        isCompleted: isCompleted,
                        isAlarmScheduled: isAlarmScheduled,
                        alarmID: alarmID,
                        createdAt: createdAt,
                        completedAt: completedAt,
                        isArchived: isArchived,
                        recurrenceRule: recurrenceRule
                    )
                )
            }
        }
        sqlite3_finalize(stmt)
        return result
    }
}
