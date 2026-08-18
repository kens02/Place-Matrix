//
//  PlaceAnnotationView.swift
//  Place-Matrix
//
//  地図上に置く Place の表示。
//

import SwiftUI

/// 地図の Annotation として使う Place の表示（仕様書 §8）。
///
/// インジケータ本体は PlaceIndicatorView に任せ、
/// ここでは地図上で見やすくするための影と名称ラベルだけを足す。
struct PlaceAnnotationView: View {

    let place: Place
    let informations: [Information]
    var size: IndicatorSize = .small
    /// 選択中は少し大きく見せる
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 3) {
            PlaceIndicatorView(place: place, informations: informations, size: size)
                .shadow(color: .black.opacity(0.25), radius: 3, y: 2)

            if !place.name.isEmpty {
                Text(place.name)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.thickMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
            }
        }
        .scaleEffect(isSelected ? 1.25 : 1)
        .animation(.spring(duration: 0.25), value: isSelected)
    }
}

#Preview {
    ZStack {
        Color.green.opacity(0.25).ignoresSafeArea()

        HStack(alignment: .top, spacing: 28) {
            PlaceAnnotationView(
                place: Place(name: "A市", latitude: 35.68, longitude: 139.76, displayMode: .fourQuadrant),
                informations: [
                    Information(name: "水道", iconName: "drop.fill", level: 1, position: .topLeft),
                    Information(name: "通信", iconName: "antenna.radiowaves.left.and.right", level: 3, position: .topRight),
                    Information(name: "電気", iconName: "bolt.fill", level: 2, position: .bottomLeft),
                    Information(name: "ガス", iconName: "flame.fill", level: 4, position: .bottomRight),
                ]
            )
            PlaceAnnotationView(
                place: Place(name: "B町", latitude: 35.68, longitude: 139.76, displayMode: .single),
                informations: [Information(name: "電気", iconName: "bolt.fill", level: 4, position: .single)],
                isSelected: true
            )
        }
    }
}
