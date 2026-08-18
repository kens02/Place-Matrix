//
//  Information.swift
//  Place-Matrix
//
//  Place に紐づく情報。
//

import Foundation
import SwiftUI

/// Place に紐づく1つの情報（電気・水道・火災 など）。
///
/// 状態は「アイコン + 名称 + レベル名称 + 色」の組み合わせで伝える。
/// 色だけで意味を判断させない（仕様書 §7 / §15）。
struct Information: Identifiable, Hashable {
    /// DB 未保存を表す ID
    static let unsavedId: Int64 = 0

    var id: Int64
    var placeId: Int64
    var name: String
    /// SF Symbols 名を文字列として保持する（仕様書 §6）
    var iconName: String
    var level: Int
    /// ユーザーが独自に付けたレベル名称。空ならレベルの既定名を使う。
    var levelName: String
    var memo: String
    var position: Position
    var updatedAt: Date

    init(
        id: Int64 = Information.unsavedId,
        placeId: Int64 = Place.unsavedId,
        name: String = "",
        iconName: String = IconCatalog.fallbackIconName,
        level: Int = 0,
        levelName: String = "",
        memo: String = "",
        position: Position = .single,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.placeId = placeId
        self.name = name
        self.iconName = iconName
        self.level = level
        self.levelName = levelName
        self.memo = memo
        self.position = position
        self.updatedAt = updatedAt
    }

    var isSaved: Bool { id != Self.unsavedId }

    /// 実際に表示するレベル名称（未入力ならレベルの既定名）
    var resolvedLevelName: String {
        levelName.trimmingCharacters(in: .whitespaces).isEmpty
            ? LevelPalette.defaultName(for: level)
            : levelName
    }

    /// レベルに対応する色
    var levelColor: Color {
        LevelPalette.color(for: level)
    }

    /// 実際に表示可能な SF Symbols 名（存在しなければ代替アイコン）
    var resolvedIconName: String {
        IconCatalog.resolvedIconName(iconName)
    }

    /// 小さい表示で使う短い名称
    var shortName: String {
        name.count <= 4 ? name : String(name.prefix(4))
    }
}
