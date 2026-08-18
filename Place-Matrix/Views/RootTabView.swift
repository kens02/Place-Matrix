//
//  RootTabView.swift
//  Place-Matrix
//
//  アプリの入り口。地図と一覧の2タブ構成（仕様書 §13）。
//

import SwiftUI

struct RootTabView: View {

    @Environment(AppStore.self) private var store

    var body: some View {
        TabView {
            Tab("地図", systemImage: "map") {
                MapView()
            }
            Tab("一覧", systemImage: "list.bullet") {
                PlaceListView()
            }
        }
        .alert(
            "エラー",
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}

#Preview {
    RootTabView()
        .environment(AppStore(database: SQLiteManager(databaseURL: nil)))
}
