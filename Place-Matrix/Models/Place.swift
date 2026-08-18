//
//  Place.swift
//  Place-Matrix
//
//  地理的な場所。
//

import Foundation
import CoreLocation

/// 地図上に登録される場所。
///
/// Place は複数の Information を持つ（仕様書 §4）。
/// どの Information をどう表示するかは `templateId` と `displayMode` が決める。
struct Place: Identifiable, Hashable {
    /// DB 未保存を表す ID
    static let unsavedId: Int64 = 0

    var id: Int64
    var name: String
    var category: String
    var latitude: Double
    var longitude: Double
    /// 適用中の Template（未設定なら nil）
    var templateId: Int64?
    var displayMode: DisplayMode
    var createdAt: Date
    var updatedAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var isSaved: Bool { id != Self.unsavedId }

    init(
        id: Int64 = Place.unsavedId,
        name: String = "",
        category: String = "",
        latitude: Double,
        longitude: Double,
        templateId: Int64? = nil,
        displayMode: DisplayMode = .fourQuadrant,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.latitude = latitude
        self.longitude = longitude
        self.templateId = templateId
        self.displayMode = displayMode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(id: Int64 = Place.unsavedId, name: String = "", category: String = "", coordinate: CLLocationCoordinate2D) {
        self.init(id: id, name: name, category: category, latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
