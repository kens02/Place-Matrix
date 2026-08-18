//
//  TemplateRepository.swift
//  Place-Matrix
//
//  templates / template_items テーブルの読み出し。
//

import Foundation

/// Template の取得を担当する。
///
/// MVP では初期投入した4テンプレートを読むだけで、ユーザーによる追加は行わない。
final class TemplateRepository {

    private let database: SQLiteManager

    init(database: SQLiteManager = .shared) {
        self.database = database
    }

    func fetchAll() throws -> [Template] {
        try database
            .query("SELECT * FROM templates ORDER BY id;")
            .map(Self.makeTemplate)
    }

    func fetch(id: Int64) throws -> Template? {
        try database
            .query("SELECT * FROM templates WHERE id = ?;", [.int(id)])
            .first
            .map(Self.makeTemplate)
    }

    /// Template を構成する項目を表示順で返す
    func items(templateId: Int64) throws -> [TemplateItem] {
        try database
            .query("SELECT * FROM template_items WHERE template_id = ?;", [.int(templateId)])
            .map(Self.makeItem)
            .sorted { $0.position.sortIndex < $1.position.sortIndex }
    }

    // MARK: - 変換

    private static func makeTemplate(from row: Row) -> Template {
        Template(
            id: row.int("id"),
            name: row.string("name"),
            displayMode: DisplayMode.from(rawValue: row.string("display_mode")),
            createdAt: row.date("created_at")
        )
    }

    private static func makeItem(from row: Row) -> TemplateItem {
        TemplateItem(
            id: row.int("id"),
            templateId: row.int("template_id"),
            informationName: row.string("information_name"),
            iconName: row.string("icon_name"),
            position: Position.from(rawValue: row.string("position"))
        )
    }
}
