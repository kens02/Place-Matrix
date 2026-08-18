//
//  DatabaseSchema.swift
//  Place-Matrix
//
//  テーブル定義と、初回起動時のテンプレート投入。
//

import Foundation

extension SQLiteManager {

    /// スキーマを変更したらこの値を上げ、`migrate()` に移行処理を足す
    static let currentSchemaVersion: Int64 = 1

    // MARK: - マイグレーション

    /// 必要ならテーブルを作成し、初期データを投入する
    func migrate() throws {
        if try schemaVersion() < 1 {
            try transaction {
                try createTables()
                try seedTemplatesIfNeeded()
            }
            try updateSchemaVersion(to: 1)
        }
    }

    private func schemaVersion() throws -> Int64 {
        try query("PRAGMA user_version;").first?.int("user_version") ?? 0
    }

    private func updateSchemaVersion(to version: Int64) throws {
        // PRAGMA はプレースホルダを使えないため直接埋め込む（値はアプリ内定数）
        try execute("PRAGMA user_version = \(version);")
    }

    // MARK: - テーブル

    private func createTables() throws {
        try execute("""
            CREATE TABLE IF NOT EXISTS places (
                id           INTEGER PRIMARY KEY AUTOINCREMENT,
                name         TEXT    NOT NULL,
                category     TEXT    NOT NULL DEFAULT '',
                latitude     REAL    NOT NULL,
                longitude    REAL    NOT NULL,
                template_id  INTEGER REFERENCES templates(id) ON DELETE SET NULL,
                display_mode TEXT    NOT NULL DEFAULT 'fourQuadrant',
                created_at   INTEGER NOT NULL,
                updated_at   INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS templates (
                id           INTEGER PRIMARY KEY AUTOINCREMENT,
                name         TEXT    NOT NULL,
                display_mode TEXT    NOT NULL DEFAULT 'fourQuadrant',
                created_at   INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS template_items (
                id               INTEGER PRIMARY KEY AUTOINCREMENT,
                template_id      INTEGER NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
                information_name TEXT    NOT NULL,
                icon_name        TEXT    NOT NULL,
                position         TEXT    NOT NULL
            );

            CREATE TABLE IF NOT EXISTS information (
                id         INTEGER PRIMARY KEY AUTOINCREMENT,
                place_id   INTEGER NOT NULL REFERENCES places(id) ON DELETE CASCADE,
                name       TEXT    NOT NULL,
                icon_name  TEXT    NOT NULL,
                level      INTEGER NOT NULL DEFAULT 0,
                level_name TEXT    NOT NULL DEFAULT '',
                memo       TEXT    NOT NULL DEFAULT '',
                position   TEXT    NOT NULL DEFAULT 'single',
                updated_at INTEGER NOT NULL
            );

            CREATE INDEX IF NOT EXISTS idx_information_place ON information(place_id);
            CREATE INDEX IF NOT EXISTS idx_template_items_template ON template_items(template_id);
            """)
    }

    // MARK: - 初期データ

    /// 仕様書 §5 の4テンプレートを投入する（既にデータがあれば何もしない）
    private func seedTemplatesIfNeeded() throws {
        let existing = try query("SELECT COUNT(*) AS count FROM templates;").first?.int("count") ?? 0
        guard existing == 0 else { return }

        for template in Self.builtInTemplates {
            let now = SQLValue.date(Date())
            let templateId = try run(
                "INSERT INTO templates (name, display_mode, created_at) VALUES (?, ?, ?);",
                [.text(template.name), .text(template.displayMode.rawValue), now]
            )

            for item in template.items {
                try run(
                    """
                    INSERT INTO template_items (template_id, information_name, icon_name, position)
                    VALUES (?, ?, ?, ?);
                    """,
                    [.int(templateId), .text(item.name), .text(item.iconName), .text(item.position.rawValue)]
                )
            }
        }
    }

    /// 投入するテンプレートの定義
    private struct SeedTemplate {
        struct Item {
            let name: String
            let iconName: String
            let position: Position
        }

        let name: String
        let displayMode: DisplayMode
        let items: [Item]
    }

    /// 仕様書 §5 のテンプレート。配置は §14 の表示例に合わせている。
    private static let builtInTemplates: [SeedTemplate] = [
        SeedTemplate(name: "Infrastructure", displayMode: .fourQuadrant, items: [
            .init(name: "水道", iconName: "drop.fill", position: .topLeft),
            .init(name: "通信", iconName: "antenna.radiowaves.left.and.right", position: .topRight),
            .init(name: "電気", iconName: "bolt.fill", position: .bottomLeft),
            .init(name: "ガス", iconName: "flame.fill", position: .bottomRight),
        ]),
        SeedTemplate(name: "Disaster", displayMode: .fourQuadrant, items: [
            .init(name: "火災", iconName: "flame.fill", position: .topLeft),
            .init(name: "浸水", iconName: "water.waves", position: .topRight),
            .init(name: "倒壊", iconName: "house.fill", position: .bottomLeft),
            .init(name: "その他", iconName: "exclamationmark.triangle.fill", position: .bottomRight),
        ]),
        SeedTemplate(name: "Medical", displayMode: .fourQuadrant, items: [
            .init(name: "病院", iconName: "cross.case.fill", position: .topLeft),
            .init(name: "医薬品", iconName: "pills.fill", position: .topRight),
            .init(name: "救急", iconName: "cross.circle.fill", position: .bottomLeft),
            .init(name: "その他", iconName: "exclamationmark.triangle.fill", position: .bottomRight),
        ]),
        SeedTemplate(name: "Traffic", displayMode: .fourQuadrant, items: [
            .init(name: "鉄道", iconName: "tram.fill", position: .topLeft),
            .init(name: "道路", iconName: "road.lanes", position: .topRight),
            .init(name: "バス", iconName: "bus.fill", position: .bottomLeft),
            .init(name: "その他", iconName: "exclamationmark.triangle.fill", position: .bottomRight),
        ]),
    ]
}
