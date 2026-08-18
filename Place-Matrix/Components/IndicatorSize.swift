//
//  IndicatorSize.swift
//  Place-Matrix
//
//  インジケータの大きさと、その大きさで何を表示するか。
//

import SwiftUI

/// インジケータの表示サイズ。
///
/// 小さい表示では要素を削り、大きい表示では名称やレベル名まで出す（仕様書 §9 / §10）。
enum IndicatorSize {
    /// 地図上のピンなど、ごく小さい表示。アイコンと色だけ。
    case small
    /// 一覧など。アイコンと名称と色。
    case medium
    /// 詳細画面など。アイコンと名称とレベル名まで。
    case large

    /// インジケータ全体の一辺の長さ
    var side: CGFloat {
        switch self {
        case .small: 52
        case .medium: 88
        case .large: 148
        }
    }

    /// 名称を表示するか
    var showsName: Bool {
        switch self {
        case .small: false
        case .medium, .large: true
        }
    }

    /// レベル名称を表示するか
    var showsLevelName: Bool {
        switch self {
        case .small, .medium: false
        case .large: true
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .small: 10
        case .medium: 14
        case .large: 20
        }
    }

    /// 単一情報表示でのアイコンの大きさ
    var iconSize: CGFloat {
        switch self {
        case .small: 22
        case .medium: 30
        case .large: 46
        }
    }

    /// 4分割表示での1区画のアイコンの大きさ（区画は全体の半分の広さしかない）
    var quadrantIconSize: CGFloat {
        switch self {
        case .small: 15
        case .medium: 20
        case .large: 30
        }
    }

    var nameFont: Font {
        switch self {
        case .small: .system(size: 9, weight: .semibold)
        case .medium: .system(size: 13, weight: .semibold)
        case .large: .system(size: 18, weight: .bold)
        }
    }

    var quadrantNameFont: Font {
        switch self {
        case .small: .system(size: 7, weight: .semibold)
        case .medium: .system(size: 10, weight: .semibold)
        case .large: .system(size: 14, weight: .semibold)
        }
    }

    var levelNameFont: Font {
        switch self {
        case .small: .system(size: 9)
        case .medium: .system(size: 12)
        case .large: .system(size: 15, weight: .semibold)
        }
    }
}
