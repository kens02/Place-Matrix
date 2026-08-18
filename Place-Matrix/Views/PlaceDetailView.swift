//
//  PlaceDetailView.swift
//  Place-Matrix
//
//  Place の詳細画面。
//

import SwiftUI
import MapKit

/// Place の詳細（仕様書 §14）。
///
/// 場所の名前・地図・Template・Information を表示する。
struct PlaceDetailView: View {

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// 遷移してきた時点の Place。表示には store 上の最新版を使う。
    let place: Place

    @State private var isDeleteConfirmationPresented = false
    @State private var editTarget: EditTarget?

    /// 開く編集画面。sheet を複数付けると互いに打ち消し合うため1つにまとめる。
    private enum EditTarget: Identifiable {
        case place(Place)
        case information(Information)

        var id: String {
            switch self {
            case .place(let place): "place-\(place.id)"
            case .information(let information): "information-\(information.id)-\(information.position.rawValue)"
            }
        }
    }

    /// 編集で内容が変わっても追随できるよう、毎回 store から引き直す
    private var current: Place {
        store.places.first { $0.id == place.id } ?? place
    }

    private var informations: [Information] {
        store.informations(for: place.id)
    }

    var body: some View {
        List {
            mapSection
            indicatorSection
            informationSection
            detailSection
            deleteSection
        }
        .navigationTitle(current.name.isEmpty ? "名称未設定" : current.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("編集") { editTarget = .place(current) }
            }
        }
        .sheet(item: $editTarget) { target in
            switch target {
            case .place(let place):
                PlaceEditView(place: place)
            case .information(let information):
                InformationEditView(
                    information: information,
                    allowsPositionChange: current.displayMode == .fourQuadrant
                )
            }
        }
        .confirmationDialog(
            "この場所を削除しますか？",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("削除する", role: .destructive) {
                store.delete(placeId: current.id)
                dismiss()
            }
            Button("やめる", role: .cancel) {}
        } message: {
            Text("登録した情報もすべて削除されます。")
        }
    }

    // MARK: - 各セクション

    private var mapSection: some View {
        Section {
            Map(initialPosition: .region(region)) {
                Annotation(current.name, coordinate: current.coordinate) {
                    PlaceAnnotationView(place: current, informations: informations)
                }
                .annotationTitles(.hidden)
            }
            .frame(height: 190)
            .listRowInsets(EdgeInsets())
            // 詳細画面の地図は位置の確認用なので操作させない
            .allowsHitTesting(false)
        }
    }

    private var indicatorSection: some View {
        Section {
            HStack {
                Spacer()
                PlaceIndicatorView(place: current, informations: informations, size: .large)
                Spacer()
            }
            .padding(.vertical, 8)
        } header: {
            Text(store.templateName(for: current) ?? "Template 未設定")
        }
    }

    @ViewBuilder
    private var informationSection: some View {
        Section("情報") {
            if informations.isEmpty {
                Text("情報が登録されていません")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(informations) { information in
                    Button {
                        editTarget = .information(information)
                    } label: {
                        InformationRow(information: information)
                            // 行全体をタップできるようにする（余白部分もヒットさせる）
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            if let position = nextAvailablePosition {
                Button("情報を追加", systemImage: "plus.circle.fill") {
                    editTarget = .information(Information(placeId: current.id, position: position))
                }
            }
        }
    }

    /// まだ埋まっていない表示位置。すべて埋まっていれば nil。
    private var nextAvailablePosition: Position? {
        let used = Set(informations.map(\.position))
        return current.displayMode.positions.first { !used.contains($0) }
    }

    private var detailSection: some View {
        Section("詳細") {
            LabeledContent("表示方法", value: current.displayMode.displayName)
            if !current.category.isEmpty {
                LabeledContent("カテゴリ", value: current.category)
            }
            LabeledContent("座標", value: MapView.format(current.coordinate))
            LabeledContent("更新日時", value: current.updatedAt.formatted(date: .abbreviated, time: .shortened))
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                isDeleteConfirmationPresented = true
            } label: {
                // Label のままだとアイコンだけ強調色になるので明示的に赤へ揃える
                Label("この場所を削除", systemImage: "trash")
                    .foregroundStyle(.red)
            }
        }
    }

    /// 場所が中央に来る狭めの表示範囲
    private var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: current.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        )
    }
}

/// Information 1件分の行。位置・アイコン・名称・レベル・メモを並べる。
struct InformationRow: View {

    let information: Information

    var body: some View {
        HStack(spacing: 12) {
            InformationIconView(
                iconName: information.iconName,
                size: 22,
                color: information.levelColor
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(information.name)
                        .font(.body.weight(.medium))
                    if information.position != .single {
                        Text(information.position.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color(.tertiarySystemFill), in: Capsule())
                    }
                }

                if !information.memo.isEmpty {
                    Text(information.memo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            LevelIndicator(
                level: information.level,
                levelName: information.levelName,
                style: .badge
            )
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        PlaceDetailView(
            place: Place(id: 1, name: "A市", category: "自治体", latitude: 35.6812, longitude: 139.7671)
        )
    }
    .environment(AppStore(database: SQLiteManager(databaseURL: nil)))
}
