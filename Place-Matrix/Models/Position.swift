//
//  Position.swift
//  Place-Matrix
//
//  Information を「どこに表示するか」を表す。
//

import Foundation

/// Information の表示位置。
///
/// 4分割インジケータは「4つの固定フィールド」ではなく、
/// 4つの Information を位置指定して配置したものである（仕様書 §4）。
/// 単一情報表示の場合は `.single` を使う。
enum Position: String, CaseIterable, Identifiable, Codable, Sendable {
    case single
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    var id: String { rawValue }

    /// 4分割インジケータで使用する4区画（左上→右上→左下→右下の表示順）
    static let quadrants: [Position] = [.topLeft, .topRight, .bottomLeft, .bottomRight]

    var displayName: String {
        switch self {
        case .single: "単一"
        case .topLeft: "左上"
        case .topRight: "右上"
        case .bottomLeft: "左下"
        case .bottomRight: "右下"
        }
    }

    /// 表示順・並べ替えに使う序列（左上→右上→左下→右下）
    var sortIndex: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    /// DB に保存された文字列から復元する。未知の値は `.single` とみなす。
    static func from(rawValue: String) -> Position {
        Position(rawValue: rawValue) ?? .single
    }
}
