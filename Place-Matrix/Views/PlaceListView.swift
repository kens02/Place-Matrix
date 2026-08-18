//
//  PlaceListView.swift
//  Place-Matrix
//
//  登録した場所の一覧。
//

import SwiftUI

/// 場所の一覧画面。検索と削除、詳細への遷移ができる（仕様書 §13 / §18-12）。
struct PlaceListView: View {

    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            Group {
                if store.places.isEmpty {
                    emptyView
                } else {
                    List {
                        ForEach(store.places) { place in
                            NavigationLink(value: place) {
                                PlaceRow(
                                    place: place,
                                    informations: store.informations(for: place.id),
                                    templateName: store.templateName(for: place)
                                )
                            }
                            // onDelete だと削除ボタンが英語のままになるため、自前で用意する
                            .swipeActions(edge: .trailing) {
                                Button("削除", systemImage: "trash", role: .destructive) {
                                    store.delete(placeId: place.id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("一覧")
            .navigationDestination(for: Place.self) { place in
                PlaceDetailView(place: place)
            }
            .searchable(text: $store.searchText, prompt: "名称・カテゴリで検索")
            // 入力のたびに Repository 側で LIKE 検索し直す
            .onChange(of: store.searchText) { _, _ in
                store.reloadPlaces()
            }
        }
    }

    @ViewBuilder
    private var emptyView: some View {
        if store.searchText.isEmpty {
            ContentUnavailableView(
                "場所がありません",
                systemImage: "mappin.slash",
                description: Text("地図をタップすると場所を登録できます")
            )
        } else {
            ContentUnavailableView(
                "見つかりませんでした",
                systemImage: "magnifyingglass",
                description: Text("「\(store.searchText)」に一致する場所はありません")
            )
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
