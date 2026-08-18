//
//  PlaceRepository.swift
//  Place-Matrix
//
//  places テーブルへの読み書き。
//

import Foundation

/// Place の永続化を担当する。View はここを直接使わず AppStore 経由で利用する（仕様書 §17）。
final class PlaceRepository {

    private let database: SQLiteManager

    init(database: SQLiteManager = .shared) {
        self.database = database
    }

    // MARK: - 取得

    func fetchAll() throws -> [Place] {
        try database
            .query("SELECT * FROM places ORDER BY updated_at DESC;")
            .map(Self.makePlace)
    }

    func fetch(id: Int64) throws -> Place? {
        try database
            .query("SELECT * FROM places WHERE id = ?;", [.int(id)])
            .first
            .map(Self.makePlace)
    }

    /// 名称・カテゴリの部分一致で検索する。キーワードが空なら全件返す。
    func search(keyword: String) throws -> [Place] {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return try fetchAll() }

        let pattern = "%\(trimmed)%"
        return try database
            .query(
                """
                SELECT * FROM places
                WHERE name LIKE ? OR category LIKE ?
                ORDER BY updated_at DESC;
                """,
                [.text(pattern), .text(pattern)]
            )
            .map(Self.makePlace)
    }

    // MARK: - 書き込み

    /// 新規登録し、採番された ID を持つ Place を返す
    func insert(_ place: Place) throws -> Place {
        let now = Date()
        let id = try database.run(
            """
            INSERT INTO places (name, category, latitude, longitude, template_id, display_mode, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?);
            """,
            [
                .text(place.name),
                .text(place.category),
                .double(place.latitude),
                .double(place.longitude),
                .optionalInt(place.templateId),
                .text(place.displayMode.rawValue),
                .date(now),
                .date(now),
            ]
        )

        var saved = place
        saved.id = id
        saved.createdAt = now
        saved.updatedAt = now
        return saved
    }

    /// 既存の Place を更新し、更新日時を進めた Place を返す
    @discardableResult
    func update(_ place: Place) throws -> Place {
        let now = Date()
        try database.run(
            """
            UPDATE places
            SET name = ?, category = ?, latitude = ?, longitude = ?,
                template_id = ?, display_mode = ?, updated_at = ?
            WHERE id = ?;
            """,
            [
                .text(place.name),
                .text(place.category),
                .double(place.latitude),
                .double(place.longitude),
                .optionalInt(place.templateId),
                .text(place.displayMode.rawValue),
                .date(now),
                .int(place.id),
            ]
        )

        var saved = place
        saved.updatedAt = now
        return saved
    }

    /// 未保存なら追加、保存済みなら更新する
    func save(_ place: Place) throws -> Place {
        place.isSaved ? try update(place) : try insert(place)
    }

    /// 削除する。紐づく information は CASCADE で一緒に消える。
    func delete(id: Int64) throws {
        try database.run("DELETE FROM places WHERE id = ?;", [.int(id)])
    }

    // MARK: - 変換

    private static func makePlace(from row: Row) -> Place {
        Place(
            id: row.int("id"),
            name: row.string("name"),
            category: row.string("category"),
            latitude: row.double("latitude"),
            longitude: row.double("longitude"),
            templateId: row.optionalInt("template_id"),
            displayMode: DisplayMode.from(rawValue: row.string("display_mode")),
            createdAt: row.date("created_at"),
            updatedAt: row.date("updated_at")
        )
    }
}
