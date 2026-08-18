//
//  Template.swift
//  Place-Matrix
//
//  情報の組み合わせのひな形。
//

import Foundation

/// 「どの4情報を4分割表示するか」を決めるひな形（仕様書 §5）。
struct Template: Identifiable, Hashable {
    static let unsavedId: Int64 = 0

    var id: Int64
    var name: String
    var displayMode: DisplayMode
    var createdAt: Date

    init(
        id: Int64 = Template.unsavedId,
        name: String,
        displayMode: DisplayMode = .fourQuadrant,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.displayMode = displayMode
        self.createdAt = createdAt
    }
}

/// Template を構成する1項目。Place に適用すると Information になる。
struct TemplateItem: Identifiable, Hashable {
    static let unsavedId: Int64 = 0

    var id: Int64
    var templateId: Int64
    var informationName: String
    var iconName: String
    var position: Position

    init(
        id: Int64 = TemplateItem.unsavedId,
        templateId: Int64 = Template.unsavedId,
        informationName: String,
        iconName: String,
        position: Position
    ) {
        self.id = id
        self.templateId = templateId
        self.informationName = informationName
        self.iconName = iconName
        self.position = position
    }

    /// この項目から、指定 Place 用の Information を作る。
    func makeInformation(placeId: Int64) -> Information {
        Information(
            placeId: placeId,
            name: informationName,
            iconName: iconName,
            level: 0,
            position: position
        )
    }
}
