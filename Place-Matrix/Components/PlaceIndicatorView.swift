//
//  PlaceIndicatorView.swift
//  Place-Matrix
//
//  Place の表示方法を1箇所で決める。
//

import SwiftUI

/// Place を表示モードに応じたインジケータで描く。
///
/// 地図と詳細画面で同じ表示ロジックを重複実装しないため、
/// 「単一情報にするか4分割にするか」の判断はここへ集約する（仕様書 §11）。
struct PlaceIndicatorView: View {

    let place: Place
    let informations: [Information]
    var size: IndicatorSize = .medium

    var body: some View {
        switch place.displayMode {
        case .fourQuadrant:
            FourQuadrantIndicator(informations: informations, size: size)
        case .single:
            if let information = primaryInformation {
                SingleInformationIndicator(information: information, size: size)
            } else {
                EmptyIndicator(size: size)
            }
        }
    }

    /// 単一情報表示で使う Information。位置 `.single` を優先し、なければ先頭。
    private var primaryInformation: Information? {
        informations.first { $0.position == .single } ?? informations.first
    }
}

/// 情報がまだ1件もないときの表示
struct EmptyIndicator: View {
    var size: IndicatorSize = .medium

    var body: some View {
        RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
            .fill(Color(.secondarySystemBackground))
            .overlay {
                RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                    .strokeBorder(Color(.separator), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            }
            .overlay {
                Image(systemName: "questionmark")
                    .font(.system(size: size.iconSize * 0.7, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .frame(width: size.side, height: size.side)
            .accessibilityLabel("情報が未登録です")
    }
}

#Preview {
    let quadrantPlace = Place(name: "A市", latitude: 35.68, longitude: 139.76, displayMode: .fourQuadrant)
    let singlePlace = Place(name: "B町", latitude: 35.68, longitude: 139.76, displayMode: .single)
    let emptyPlace = Place(name: "C村", latitude: 35.68, longitude: 139.76, displayMode: .fourQuadrant)

    return HStack(alignment: .top, spacing: 20) {
        PlaceIndicatorView(
            place: quadrantPlace,
            informations: [
                Information(name: "水道", iconName: "drop.fill", level: 1, position: .topLeft),
                Information(name: "通信", iconName: "antenna.radiowaves.left.and.right", level: 3, position: .topRight),
                Information(name: "電気", iconName: "bolt.fill", level: 2, position: .bottomLeft),
                Information(name: "ガス", iconName: "flame.fill", level: 4, position: .bottomRight),
            ]
        )
        PlaceIndicatorView(
            place: singlePlace,
            informations: [Information(name: "電気", iconName: "bolt.fill", level: 2, position: .single)]
        )
        PlaceIndicatorView(place: emptyPlace, informations: [])
    }
    .padding()
}
