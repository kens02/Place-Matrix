//
//  LevelPalette.swift
//  Place-Matrix
//
//  状態レベル（0〜4）と、その名称・色の対応表。
//

import SwiftUI

/// 1つの状態レベルの定義。
///
/// 色は Information の「意味」ではなく「状態レベル」を表す（仕様書 §7）。
struct LevelDefinition: Identifiable, Hashable, Sendable {
    let level: Int
    let name: String
    let color: Color
    /// `color` を背景に敷いたときに読める文字・アイコンの色。
    /// 黄色のような明るい色に白を載せると読めなくなるため個別に持たせる。
    let foreground: Color

    var id: Int { level }
}

/// レベル定義の参照点。
///
/// 将来ユーザーがレベル名称と色を変更できるようにするため、
/// レベル → 名称 / 色 の変換は必ずここを経由させる（仕様書 §3 / §7）。
/// 変更が必要になったら `definitions` を差し替えるだけでアプリ全体に反映される。
enum LevelPalette {

    /// MVP のデフォルト定義
    static let definitions: [LevelDefinition] = [
        LevelDefinition(level: 0, name: "不明", color: .gray, foreground: .white),
        LevelDefinition(level: 1, name: "正常", color: .green, foreground: .white),
        LevelDefinition(level: 2, name: "注意", color: .yellow, foreground: .black),
        LevelDefinition(level: 3, name: "警戒", color: .orange, foreground: .white),
        LevelDefinition(level: 4, name: "危険", color: .red, foreground: .white),
    ]

    /// 未設定・範囲外のレベルに使う定義
    static let unknown = LevelDefinition(level: 0, name: "不明", color: .gray, foreground: .white)

    /// 選択可能なレベルの範囲
    static var levels: [Int] { definitions.map(\.level) }

    static func definition(for level: Int) -> LevelDefinition {
        definitions.first { $0.level == level } ?? unknown
    }

    static func color(for level: Int) -> Color {
        definition(for: level).color
    }

    /// レベル色の上に載せる文字・アイコンの色
    static func foreground(for level: Int) -> Color {
        definition(for: level).foreground
    }

    /// そのレベルの既定の名称（ユーザーが levelName を入力していない場合に使う）
    static func defaultName(for level: Int) -> String {
        definition(for: level).name
    }
}
