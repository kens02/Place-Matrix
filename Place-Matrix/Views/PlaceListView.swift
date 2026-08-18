//
//  PlaceListView.swift
//  Place-Matrix
//
//  登録した場所の一覧。
//

import SwiftUI

/// 場所の一覧画面。
///
/// Phase 6 で検索・削除・詳細への遷移を追加する。
struct PlaceListView: View {

    @Environment(AppStore.self) private var store

    var body: some View {
        NavigationStack {
            Group {
                if store.places.isEmpty {
                    ContentUnavailableView(
                        "場所がありません",
                        systemImage: "mappin.slash",
                        description: Text("地図をタップすると場所を登録できます")
                    )
                } else {
                    List(store.places) { place in
                        PlaceRow(place: place, informations: store.informations(for: place.id))
                    }
                }
            }
            .navigationTitle("一覧")
        }
    }
}

/// 一覧の1行。地図と同じ表示部品を使う（仕様書 §11）。
struct PlaceRow: View {

    let place: Place
    let informations: [Information]
    var templateName: String?

    var body: some View {
        HStack(spacing: 14) {
            PlaceIndicatorView(place: place, informations: informations, size: .small)

            VStack(alignment: .leading, spacing: 3) {
                Text(place.name.isEmpty ? "名称未設定" : place.name)
                    .font(.headline)

                if let templateName {
                    Text(templateName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if !place.category.isEmpty {
                    Text(place.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(MapView.format(place.coordinate))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PlaceListView()
        .environment(AppStore(database: SQLiteManager(databaseURL: nil)))
}
