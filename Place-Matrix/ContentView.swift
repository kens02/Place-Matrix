//
//  ContentView.swift
//  Place-Matrix
//
//  Created by 津留健志 on 2026/08/17.
//
//  ※ Phase 5 で RootTabView（Map / List）に差し替える一時的な画面。
//     現時点では DB と Repository が正しく動いているかを確認するために使う。
//

import SwiftUI

struct ContentView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        NavigationStack {
            List {
                Section("状態") {
                    LabeledContent("DB", value: store.isReady ? "準備完了" : "準備中")
                    LabeledContent("Template", value: "\(store.templates.count) 件")
                    LabeledContent("Place", value: "\(store.places.count) 件")
                }

                Section("Template") {
                    ForEach(store.templates) { template in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name).font(.headline)
                            Text(
                                store.templateItems(templateId: template.id)
                                    .map { "\($0.position.displayName):\($0.informationName)" }
                                    .joined(separator: "  ")
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Place") {
                    if store.places.isEmpty {
                        Text("まだ登録がありません").foregroundStyle(.secondary)
                    }
                    ForEach(store.places) { place in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(place.name).font(.headline)
                            Text(store.templateName(for: place) ?? "Template 未設定")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ForEach(store.informations(for: place.id)) { information in
                                HStack(spacing: 6) {
                                    Image(systemName: information.resolvedIconName)
                                        .foregroundStyle(information.levelColor)
                                        .frame(width: 20)
                                    Text(information.name)
                                    Spacer()
                                    Text(information.resolvedLevelName)
                                        .font(.caption)
                                        .foregroundStyle(information.levelColor)
                                }
                                .font(.subheadline)
                            }
                        }
                        .swipeActions {
                            Button("削除", role: .destructive) {
                                store.delete(placeId: place.id)
                            }
                        }
                    }
                }
            }
            .onChange(of: store.isReady, initial: true) { _, ready in
                // 検証用: -add-sample 付きで起動したら自動でサンプルを作る
                if ready, ProcessInfo.processInfo.arguments.contains("-add-sample") {
                    addSamplePlace()
                }
            }
            .navigationTitle("Place Matrix")
            .toolbar {
                Button("サンプル追加", systemImage: "plus") {
                    addSamplePlace()
                }
            }
        }
    }

    /// Repository の一連の流れ（Place 追加 → Template 適用 → Information 生成）を確認する
    private func addSamplePlace() {
        guard let template = store.templates.randomElement() else { return }

        let place = Place(
            name: "サンプル\(store.places.count + 1)",
            category: "テスト",
            latitude: 35.6812 + Double.random(in: -0.05...0.05),
            longitude: 139.7671 + Double.random(in: -0.05...0.05)
        )
        guard let saved = store.save(place) else { return }
        store.applyTemplate(template, to: saved)

        // レベルを散らして、色分けが効いているか見えるようにする
        for var information in store.informations(for: saved.id) {
            information.level = Int.random(in: 0...4)
            store.save(information)
        }
    }
}

#Preview {
    ContentView()
        .environment(AppStore(database: SQLiteManager(databaseURL: nil)))
}
