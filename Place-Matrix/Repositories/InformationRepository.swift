//
//  InformationRepository.swift
//  Place-Matrix
//
//  information テーブルへの読み書き。
//

import Foundation

/// Place に紐づく Information の永続化を担当する。
final class InformationRepository {

    private let database: SQLiteManager

    init(database: SQLiteManager = .shared) {
        self.database = database
    }

    // MARK: - 取得

    /// 指定 Place の Information を表示順（左上→右上→左下→右下）で返す
    func fetch(placeId: Int64) throws -> [Information] {
        try database
            .query("SELECT * FROM information WHERE place_id = ?;", [.int(placeId)])
            .map(Self.makeInformation)
            .sorted { $0.position.sortIndex < $1.position.sortIndex }
    }

    /// 全 Place 分をまとめて取得し、placeId ごとにまとめて返す。
    ///
    /// 地図には多数の Place が並ぶため、Place ごとに問い合わせず1回で読み込む。
    func fetchAllGroupedByPlace() throws -> [Int64: [Information]] {
        let all = try database
            .query("SELECT * FROM information;")
            .map(Self.makeInformation)

        return Dictionary(grouping: all, by: \.placeId).mapValues { group in
            group.sorted { $0.position.sortIndex < $1.position.sortIndex }
        }
    }

    /// 4分割インジケータが使いやすいよう、位置をキーにして返す。
    /// 同じ位置に複数あった場合は更新の新しい方を採用する。
    func fetchByPosition(placeId: Int64) throws -> [Position: Information] {
        try fetch(placeId: placeId).reduce(into: [:]) { result, information in
            if let existing = result[information.position], existing.updatedAt > information.updatedAt {
                return
            }
            result[information.position] = information
        }
    }

    // MARK: - 書き込み

    func insert(_ information: Information) throws -> Information {
        let now = Date()
        let id = try database.run(
            """
            INSERT INTO information (place_id, name, icon_name, level, level_name, memo, position, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?);
            """,
            [
                .int(information.placeId),
                .text(information.name),
                .text(information.iconName),
                .int(Int64(information.level)),
                .text(information.levelName),
                .text(information.memo),
                .text(information.position.rawValue),
                .date(now),
            ]
        )

        var saved = information
        saved.id = id
        saved.updatedAt = now
        return saved
    }

    @discardableResult
    func update(_ information: Information) throws -> Information {
        let now = Date()
        try database.run(
            """
            UPDATE information
            SET name = ?, icon_name = ?, level = ?, level_name = ?, memo = ?, position = ?, updated_at = ?
            WHERE id = ?;
            """,
            [
                .text(information.name),
                .text(information.iconName),
                .int(Int64(information.level)),
                .text(information.levelName),
                .text(information.memo),
                .text(information.position.rawValue),
                .date(now),
                .int(information.id),
            ]
        )

        var saved = information
        saved.updatedAt = now
        return saved
    }

    /// 未保存なら追加、保存済みなら更新する
    func save(_ information: Information) throws -> Information {
        information.isSaved ? try update(information) : try insert(information)
    }

    func delete(id: Int64) throws {
        try database.run("DELETE FROM information WHERE id = ?;", [.int(id)])
    }

    func deleteAll(placeId: Int64) throws {
        try database.run("DELETE FROM information WHERE place_id = ?;", [.int(placeId)])
    }

    /// Template の項目を Place へ適用する。
    ///
    /// 既存の Information は入れ替えになるため、
    /// 呼び出し側は差し替えて良いか確認してから使うこと。
    func replaceAll(placeId: Int64, with items: [TemplateItem]) throws {
        try database.transaction {
            try deleteAll(placeId: placeId)
            for item in items {
                _ = try insert(item.makeInformation(placeId: placeId))
            }
        }
    }

    // MARK: - 変換

    private static func makeInformation(from row: Row) -> Information {
        Information(
            id: row.int("id"),
            placeId: row.int("place_id"),
            name: row.string("name"),
            iconName: row.string("icon_name"),
            level: Int(row.int("level")),
            levelName: row.string("level_name"),
            memo: row.string("memo"),
            position: Position.from(rawValue: row.string("position")),
            updatedAt: row.date("updated_at")
        )
    }
}
