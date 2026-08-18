//
//  IconCatalog.swift
//  Place-Matrix
//
//  ピクトグラム（SF Symbols）の一覧と、存在しない名前への代替処理。
//

import Foundation
import UIKit

/// Information で使えるピクトグラムのカタログ（仕様書 §6）。
///
/// Information は SF Symbols 名を文字列として保持し、表示時にシンボルへ変換する。
/// 指定された名前が存在しない場合は代替アイコンにフォールバックするため、
/// 名前の間違いで表示が壊れることはない。
enum IconCatalog {

    struct Icon: Identifiable, Hashable {
        let systemName: String
        let label: String

        var id: String { systemName }
    }

    struct Group: Identifiable, Hashable {
        let title: String
        let icons: [Icon]

        var id: String { title }
    }

    /// SF Symbols に存在しない名前が指定されたときの代替アイコン
    static let fallbackIconName = "questionmark.circle.fill"

    static let groups: [Group] = [
        Group(title: "インフラ", icons: [
            Icon(systemName: "bolt.fill", label: "電気"),
            Icon(systemName: "drop.fill", label: "水道"),
            Icon(systemName: "flame.fill", label: "ガス"),
            Icon(systemName: "antenna.radiowaves.left.and.right", label: "通信"),
            Icon(systemName: "wifi", label: "無線"),
        ]),
        Group(title: "災害", icons: [
            Icon(systemName: "flame.fill", label: "火災"),
            Icon(systemName: "water.waves", label: "浸水"),
            Icon(systemName: "house.fill", label: "倒壊"),
            Icon(systemName: "wind", label: "強風"),
            Icon(systemName: "exclamationmark.triangle.fill", label: "その他"),
        ]),
        Group(title: "医療", icons: [
            Icon(systemName: "cross.case.fill", label: "病院"),
            Icon(systemName: "pills.fill", label: "医薬品"),
            Icon(systemName: "cross.circle.fill", label: "救急"),
            Icon(systemName: "stethoscope", label: "診療"),
        ]),
        Group(title: "交通", icons: [
            Icon(systemName: "tram.fill", label: "鉄道"),
            Icon(systemName: "road.lanes", label: "道路"),
            Icon(systemName: "bus.fill", label: "バス"),
            Icon(systemName: "car.fill", label: "自動車"),
            Icon(systemName: "airplane", label: "空路"),
        ]),
        Group(title: "その他", icons: [
            Icon(systemName: "building.2.fill", label: "施設"),
            Icon(systemName: "person.3.fill", label: "人"),
            Icon(systemName: "shippingbox.fill", label: "物資"),
            Icon(systemName: "mappin.circle.fill", label: "地点"),
            Icon(systemName: "questionmark.circle.fill", label: "不明"),
        ]),
    ]

    static var allIcons: [Icon] {
        groups.flatMap(\.icons)
    }

    /// SF Symbols に存在するかどうか
    static func exists(_ systemName: String) -> Bool {
        !systemName.isEmpty && UIImage(systemName: systemName) != nil
    }

    /// 表示に使える SF Symbols 名を返す。存在しなければ代替アイコン名。
    static func resolvedIconName(_ systemName: String) -> String {
        exists(systemName) ? systemName : fallbackIconName
    }
}
