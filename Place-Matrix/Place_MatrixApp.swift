//
//  Place_MatrixApp.swift
//  Place-Matrix
//
//  Created by 津留健志 on 2026/08/17.
//

import SwiftUI

@main
struct Place_MatrixApp: App {

    /// アプリ全体で共有する状態。View へは environment 経由で渡す。
    @State private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .task { store.start() }
        }
    }
}
