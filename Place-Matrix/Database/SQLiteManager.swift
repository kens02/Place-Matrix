//
//  SQLiteManager.swift
//  Place-Matrix
//
//  SQLite への薄いラッパ。外部ライブラリを使わず SQLite3 を直接利用する。
//

import Foundation
import SQLite3

/// SQLite に渡す値。
///
/// 型ごとに bind の呼び分けが必要なため、扱う型を明示的に列挙している。
enum SQLValue {
    case text(String)
    case int(Int64)
    case double(Double)
    case null

    /// Date は Unix 秒（INTEGER）として保存する
    static func date(_ value: Date) -> SQLValue {
        .int(Int64(value.timeIntervalSince1970))
    }

    static func optionalInt(_ value: Int64?) -> SQLValue {
        value.map { .int($0) } ?? .null
    }
}

/// SELECT の結果1行。
///
/// statement は取り出し後に finalize するため、値はここへ複製しておく。
struct Row {
    private let values: [String: SQLValue]

    init(values: [String: SQLValue]) {
        self.values = values
    }

    func isNull(_ column: String) -> Bool {
        if case .null = values[column] ?? .null { return true }
        return false
    }

    func string(_ column: String) -> String {
        if case .text(let value) = values[column] ?? .null { return value }
        return ""
    }

    func int(_ column: String) -> Int64 {
        switch values[column] ?? .null {
        case .int(let value): return value
        case .double(let value): return Int64(value)
        default: return 0
        }
    }

    func optionalInt(_ column: String) -> Int64? {
        isNull(column) ? nil : int(column)
    }

    func double(_ column: String) -> Double {
        switch values[column] ?? .null {
        case .double(let value): return value
        case .int(let value): return Double(value)
        default: return 0
        }
    }

    func date(_ column: String) -> Date {
        Date(timeIntervalSince1970: TimeInterval(int(column)))
    }
}

/// DB 操作の入り口。Repository からのみ使用し、View から直接触らない（仕様書 §17）。
final class SQLiteManager {

    enum DatabaseError: LocalizedError {
        case openFailed(String)
        case statementFailed(String, sql: String)

        var errorDescription: String? {
            switch self {
            case .openFailed(let message):
                "データベースを開けませんでした: \(message)"
            case .statementFailed(let message, let sql):
                "SQL の実行に失敗しました: \(message)\nSQL: \(sql)"
            }
        }
    }

    /// アプリ全体で共有するインスタンス
    static let shared = SQLiteManager()

    /// バインドした文字列を SQLite 側にコピーさせるための指定
    private static let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    private var db: OpaquePointer?
    private let databaseURL: URL?

    /// - Parameter databaseURL: nil を渡すとインメモリ DB になる（プレビュー・テスト用）
    init(databaseURL: URL? = SQLiteManager.defaultDatabaseURL()) {
        self.databaseURL = databaseURL
    }

    deinit {
        if let db { sqlite3_close(db) }
    }

    /// Application Support 配下の DB ファイルの位置
    static func defaultDatabaseURL() -> URL? {
        guard let directory = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else { return nil }
        return directory.appendingPathComponent("placematrix.sqlite")
    }

    // MARK: - 接続

    /// DB を開き、スキーマを最新にする。アプリ起動時に一度だけ呼ぶ。
    func open() throws {
        guard db == nil else { return }

        let path = databaseURL?.path ?? ":memory:"
        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX

        guard sqlite3_open_v2(path, &handle, flags, nil) == SQLITE_OK, let handle else {
            let message = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown error"
            sqlite3_close(handle)
            throw DatabaseError.openFailed(message)
        }
        db = handle

        // 子レコードの自動削除（ON DELETE CASCADE）を有効にする
        try execute("PRAGMA foreign_keys = ON;")
        try migrate()
    }

    // MARK: - 実行

    /// DDL や複数文の実行に使う
    func execute(_ sql: String) throws {
        guard let db else { throw DatabaseError.openFailed("データベースが開かれていません") }

        var errorPointer: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, sql, nil, nil, &errorPointer) == SQLITE_OK else {
            let message = errorPointer.map { String(cString: $0) } ?? "unknown error"
            sqlite3_free(errorPointer)
            throw DatabaseError.statementFailed(message, sql: sql)
        }
    }

    /// INSERT / UPDATE / DELETE を実行し、INSERT の場合は採番された ID を返す
    @discardableResult
    func run(_ sql: String, _ parameters: [SQLValue] = []) throws -> Int64 {
        guard let db else { throw DatabaseError.openFailed("データベースが開かれていません") }

        let statement = try prepare(sql, parameters)
        defer { sqlite3_finalize(statement) }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.statementFailed(String(cString: sqlite3_errmsg(db)), sql: sql)
        }
        return sqlite3_last_insert_rowid(db)
    }

    /// SELECT を実行して全行を取り出す
    func query(_ sql: String, _ parameters: [SQLValue] = []) throws -> [Row] {
        let statement = try prepare(sql, parameters)
        defer { sqlite3_finalize(statement) }

        var rows: [Row] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            rows.append(readRow(from: statement))
        }
        return rows
    }

    /// 複数の書き込みをまとめて行う。途中で失敗したら全て取り消す。
    func transaction(_ work: () throws -> Void) throws {
        try execute("BEGIN TRANSACTION;")
        do {
            try work()
            try execute("COMMIT;")
        } catch {
            try? execute("ROLLBACK;")
            throw error
        }
    }

    // MARK: - 内部処理

    private func prepare(_ sql: String, _ parameters: [SQLValue]) throws -> OpaquePointer? {
        guard let db else { throw DatabaseError.openFailed("データベースが開かれていません") }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let message = String(cString: sqlite3_errmsg(db))
            sqlite3_finalize(statement)
            throw DatabaseError.statementFailed(message, sql: sql)
        }

        // バインド位置は 1 始まり
        for (offset, parameter) in parameters.enumerated() {
            let index = Int32(offset + 1)
            switch parameter {
            case .text(let value):
                sqlite3_bind_text(statement, index, value, -1, Self.transient)
            case .int(let value):
                sqlite3_bind_int64(statement, index, value)
            case .double(let value):
                sqlite3_bind_double(statement, index, value)
            case .null:
                sqlite3_bind_null(statement, index)
            }
        }
        return statement
    }

    private func readRow(from statement: OpaquePointer?) -> Row {
        var values: [String: SQLValue] = [:]

        for index in 0..<sqlite3_column_count(statement) {
            guard let namePointer = sqlite3_column_name(statement, index) else { continue }
            let name = String(cString: namePointer)

            switch sqlite3_column_type(statement, index) {
            case SQLITE_INTEGER:
                values[name] = .int(sqlite3_column_int64(statement, index))
            case SQLITE_FLOAT:
                values[name] = .double(sqlite3_column_double(statement, index))
            case SQLITE_TEXT:
                if let text = sqlite3_column_text(statement, index) {
                    values[name] = .text(String(cString: text))
                } else {
                    values[name] = .null
                }
            default:
                values[name] = .null
            }
        }
        return Row(values: values)
    }
}
