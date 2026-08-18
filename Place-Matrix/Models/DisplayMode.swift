//
//  DisplayMode.swift
//  Place-Matrix
//
//  Place を地図上でどう表示するか。
//

import Foundation

/// Place の表示方法（仕様書 §1 / §8）
enum DisplayMode: String, CaseIterable, Identifiable, Codable, Sendable {
    /// 1つの Information を1つのインジケータとして表示する
    case single
    /// 1つの正方形を4分割し、4つの Information を表示する
    case fourQuadrant

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .single: "単一情報"
        case .fourQuadrant: "4分割"
        }
    }

    /// この表示モードで使用する表示位置
    var positions: [Position] {
        switch self {
        case .single: [.single]
        case .fourQuadrant: Position.quadrants
        }
    }

    /// DB に保存された文字列から復元する。未知の値は `.single` とみなす。
    static func from(rawValue: String) -> DisplayMode {
        DisplayMode(rawValue: rawValue) ?? .single
    }
}
